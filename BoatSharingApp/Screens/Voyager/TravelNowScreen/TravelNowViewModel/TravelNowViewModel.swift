import Combine
import SwiftUI

enum TravelNowMainPhase: Equatable {
    case idle
    case loading
    case noVoyageFound
    case voyageContent
    case retryableError
}

@MainActor
final class TravelNowViewModel: ObservableObject {

    struct State {
        var travelNowData: TravelNowVoyage?
        var isLoading: Bool = false
        var errorMessage: String?
        var loadingVoyageId: String?
        var isConfirming: Bool = false
        var isCancelling: Bool = false
        var showPaymentPopup: Bool = false
        var showStripeSheet: Bool = false
        var toastMessage: String = ""
        var isShowToast: Bool = false
        var stripeClientSecret: String?
        var stripePaymentIntentId: String = ""
        var shouldDismissScreen: Bool = false
        var statusCode: Int?
        var mainPhase: TravelNowMainPhase = .idle
        var retryBannerMessage: String = "No voyage found"
        var displayUsername: String = "Unknown user"
        /// Set after voyage confirm (200) before sponsor flow completes.
        var showPendingSponsorInvite: Bool = false
    }

    enum Action {
        case onAppear
        case onDisappear
        case retry
        case dismissForBackNavigation
        case dismissPaymentPopup
        case dismissToast
        case confirmVoyage(String)
        case cancelVoyage(String)
        case payNow(String)
        case handleStripeResult(PaymentSheetResult)
        case dismissScreen
        case clearDismissRequest
    }

    @Published private(set) var state = State()

    private let networkRepository: AppNetworkRepositoryProtocol
    private let identityProvider: SessionPreferenceStoring
    private let sponsorPaymentRequestViewModel: NewRequestPopUpViewModel

    init(networkRepository: AppNetworkRepositoryProtocol, identityProvider: SessionPreferenceStoring) {
        self.networkRepository = networkRepository
        self.identityProvider = identityProvider
        self.sponsorPaymentRequestViewModel = NewRequestPopUpViewModel(
            networkRepository: networkRepository,
            sessionPreferences: identityProvider
        )
        bindSponsorPaymentInitiationPipeline()
        recomputeDerived()
    }

    deinit { postStripeSuccessTask?.cancel() }

    private var hasLoaded = false
    private var voyageIdForPayment = ""
    private var postStripeSuccessTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    func send(_ action: Action) {
        switch action {
        case .onAppear: onAppearLoad()
        case .onDisappear: onDisappearReset()
        case .retry: fetchTravelNowVoyage()
        case .dismissForBackNavigation: onDisappearReset()
        case .dismissPaymentPopup:
            withAnimation { mutate { $0.showPaymentPopup = false } }
        case .dismissToast:
            mutate { $0.isShowToast = false }
        case .confirmVoyage(let id): performVoyageConfirmation(voyageId: id)
        case .cancelVoyage(let id): performVoyageCancellation(voyageId: id)
        case .payNow(let id): startSponsorPaymentOnBehalf(voyageId: id)
        case .handleStripeResult(let r): handleStripePaymentResult(r)
        case .dismissScreen:
            onDisappearReset()
            mutate { $0.shouldDismissScreen = true }
        case .clearDismissRequest:
            mutate { $0.shouldDismissScreen = false }
        }
    }

    private func mutate(_ update: (inout State) -> Void) {
        var next = state
        update(&next)
        state = next
        recomputeDerived()
    }

    private func recomputeDerived() {
        var next = state
        let name = identityProvider.username.trimmingCharacters(in: .whitespacesAndNewlines)
        next.displayUsername = name.isEmpty ? "Unknown user" : name

        if next.isLoading { next.mainPhase = .loading }
        else if next.statusCode == 404 { next.mainPhase = .noVoyageFound }
        else if next.statusCode == 200 { next.mainPhase = next.travelNowData != nil ? .voyageContent : .noVoyageFound }
        else if next.errorMessage != nil { next.mainPhase = .retryableError }
        else if next.travelNowData != nil { next.mainPhase = .voyageContent }
        else { next.mainPhase = .idle }

        if let err = next.errorMessage, !err.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            next.retryBannerMessage = err
        } else {
            next.retryBannerMessage = "No voyage found"
        }
        state = next
    }

    private var currentUserId: String? {
        let id = identityProvider.userID.trimmingCharacters(in: .whitespacesAndNewlines)
        return id.isEmpty ? nil : id
    }

    private func onAppearLoad() {
        guard !hasLoaded else { return }
        hasLoaded = true
        fetchTravelNowVoyage()
    }

    private func onDisappearReset() {
        hasLoaded = false
        mutate { $0.shouldDismissScreen = false }
        postStripeSuccessTask?.cancel()
        postStripeSuccessTask = nil
    }

    private func startSponsorPaymentOnBehalf(voyageId: String) {
        guard let sponsorId = currentUserId else {
            mutate { $0.errorMessage = "Missing user id." }
            return
        }
        voyageIdForPayment = voyageId
        withAnimation {
            sponsorPaymentRequestViewModel.getSponsorPaymentIds(voyagerId: voyageId, sponsorId: sponsorId, user: "VoyagerUserId")
            mutate { $0.showPaymentPopup = false }
        }
    }

    func makePaymentSheet() -> PaymentSheet? {
        guard let secret = state.stripeClientSecret else { return nil }
        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "Boat Sharing"
        return PaymentSheet(paymentIntentClientSecret: secret, configuration: config)
    }

    private func handleStripePaymentResult(_ result: PaymentSheetResult) {
        let intentId = state.stripePaymentIntentId
        let voyageId = voyageIdForPayment
        mutate {
            $0.showStripeSheet = false
            $0.stripeClientSecret = nil
        }
        switch result {
        case .completed:
            mutate {
                $0.toastMessage = "Payment successful"
                $0.isShowToast = true
            }
            performSponsorPaymentConfirmation(voyageId: voyageId, paymentIntentId: intentId)
        case .canceled:
            mutate {
                $0.toastMessage = "Payment canceled"
                $0.isShowToast = true
            }
        case .failed(let error):
            mutate {
                $0.toastMessage = "Payment failed: \(error.localizedDescription)"
                $0.isShowToast = true
            }
        }
    }

    private func bindSponsorPaymentInitiationPipeline() {
        sponsorPaymentRequestViewModel.paymentDataPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] data in self?.applySponsorPaymentInitiation(data) }
            .store(in: &cancellables)
    }

    private func applySponsorPaymentInitiation(_ data: PaymentInitiationData?) {
        guard let secret = data?.clientSecret else { return }
        mutate {
            $0.stripePaymentIntentId = data?.paymentIntentId ?? ""
            $0.stripeClientSecret = secret
            $0.showStripeSheet = true
        }
    }

    private func fetchTravelNowVoyage() {
        mutate {
            $0.isLoading = true
            $0.errorMessage = nil
            $0.statusCode = nil
        }
        Task { @MainActor in
            do {
                let response = try await networkRepository.voyager_getImmediatelyBookedVoyage()
                mutate {
                    $0.isLoading = false
                    $0.travelNowData = response.obj
                    $0.statusCode = response.status
                    $0.showPendingSponsorInvite = false
                }
            } catch {
                let code = (error as? APIError).flatMap {
                    if case .serverError(let c, _) = $0 { return c } else { return nil }
                } ?? 500
                mutate {
                    $0.isLoading = false
                    $0.errorMessage = error.localizedDescription
                    $0.statusCode = code
                }
            }
        }
    }

    private func performVoyageCancellation(voyageId: String) {
        mutate {
            $0.loadingVoyageId = voyageId
            $0.isCancelling = true
        }
        Task { @MainActor in
            do {
                _ = try await networkRepository.voyage_cancel(voyageId: voyageId)
                mutate {
                    $0.loadingVoyageId = nil
                    $0.isCancelling = false
                }
                fetchTravelNowVoyage()
            } catch {
                mutate {
                    $0.loadingVoyageId = nil
                    $0.isCancelling = false
                    $0.errorMessage = error.localizedDescription
                }
                fetchTravelNowVoyage()
            }
        }
    }

    private func performVoyageConfirmation(voyageId: String) {
        mutate {
            $0.loadingVoyageId = voyageId
            $0.isConfirming = true
        }
        Task { @MainActor in
            do {
                let response = try await networkRepository.voyage_confirm(voyageId: voyageId)
                mutate {
                    $0.loadingVoyageId = nil
                    $0.isConfirming = false
                }
                if response.status == 200 {
                    withAnimation {
                        mutate {
                            $0.showPaymentPopup = true
                            $0.showPendingSponsorInvite = true
                        }
                    }
                } else {
                    fetchTravelNowVoyage()
                }
            } catch {
                mutate {
                    $0.loadingVoyageId = nil
                    $0.isConfirming = false
                    $0.errorMessage = error.localizedDescription
                }
                fetchTravelNowVoyage()
            }
        }
    }

    private func performSponsorPaymentConfirmation(voyageId: String, paymentIntentId: String) {
        Task { @MainActor in
            do {
                _ = try await networkRepository.voyage_sponsorPaymentConfirm(voyageId: voyageId, paymentIntentId: paymentIntentId)
                fetchTravelNowVoyage()
            } catch {
                mutate { $0.errorMessage = error.localizedDescription }
            }
        }
    }

    func getTravelNowVoyage() { fetchTravelNowVoyage() }
    func voyageValidation(voyageId: String) { send(.cancelVoyage(voyageId)) }
    func voyageConfirmation(voyageId: String) { send(.confirmVoyage(voyageId)) }
    func sponsorsPaymentSuccess(voyageId: String, paymentIntentId: String) {
        performSponsorPaymentConfirmation(voyageId: voyageId, paymentIntentId: paymentIntentId)
    }
}

