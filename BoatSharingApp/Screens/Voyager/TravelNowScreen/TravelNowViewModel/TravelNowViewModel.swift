import Combine
import SwiftUI

// MARK: - Phase enum (public, used by the view for layout decisions)

enum TravelNowMainPhase: Equatable {
    case idle
    case loading
    case noVoyageFound
    case voyageContent
    case retryableError
}

@MainActor
final class TravelNowViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let travelNowData: TravelNowVoyage?
        let isLoading: Bool
        let errorMessage: String?
        let loadingVoyageId: String?
        let isConfirming: Bool
        let isCancelling: Bool
        let showPaymentPopup: Bool
        let showStripeSheet: Bool
        let toastMessage: String
        let isShowToast: Bool
        let mainPhase: TravelNowMainPhase
        let retryBannerMessage: String
        let displayUsername: String
        let shouldDismissScreen: Bool
    }

    var state: State {
        State(
            travelNowData: travelNowData,
            isLoading: isLoading,
            errorMessage: errorMessage,
            loadingVoyageId: loadingVoyageId,
            isConfirming: isConfirming,
            isCancelling: isCancelling,
            showPaymentPopup: showPaymentPopup,
            showStripeSheet: showStripeSheet,
            toastMessage: toastMessage,
            isShowToast: isShowToast,
            mainPhase: mainPhase,
            retryBannerMessage: retryBannerMessage,
            displayUsername: displayUsername,
            shouldDismissScreen: shouldDismissScreen
        )
    }

    // MARK: - Actions

    enum Action {
        case onAppear
        case onDisappear
        case retry
        case dismissForBackNavigation
        case dismissPaymentPopup
        case confirmVoyage(String)
        case cancelVoyage(String)
        case payNow(String)
        case handleStripeResult(PaymentSheetResult)
        case dismissScreen
        case clearDismissRequest
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:             onAppearLoad()
        case .onDisappear:          onDisappearReset()
        case .retry:                fetchTravelNowVoyage()
        case .dismissForBackNavigation: onDisappearReset()
        case .dismissPaymentPopup:  withAnimation { showPaymentPopup = false }
        case .confirmVoyage(let id): performVoyageConfirmation(voyageId: id)
        case .cancelVoyage(let id): performVoyageCancellation(voyageId: id)
        case .payNow(let id):       startSponsorPaymentOnBehalf(voyageId: id)
        case .handleStripeResult(let r): handleStripePaymentResult(r)
        case .dismissScreen:        onDisappearReset(); shouldDismissScreen = true
        case .clearDismissRequest:  shouldDismissScreen = false
        }
    }

    // MARK: - Published state

    @Published var travelNowData: TravelNowVoyage?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var loadingVoyageId: String?
    @Published var isConfirming: Bool = false
    @Published var isCancelling: Bool = false
    @Published var payNow: Bool = false
    @Published var showPaymentPopup: Bool = false
    @Published var showStripeSheet: Bool = false
    @Published var toastMessage: String = ""
    @Published var isShowToast: Bool = false
    @Published var stripeClientSecret: String?
    @Published var stripePaymentIntentId: String = ""
    @Published var shouldDismissScreen: Bool = false
    @Published var statusCode: Int?

    // MARK: - Dependencies

    private let apiClient: APIClientProtocol
    private let identityProvider: SessionPreferenceStoring
    private let sponsorPaymentRequestViewModel: NewRequestPopUpViewModel

    init(apiClient: APIClientProtocol, identityProvider: SessionPreferenceStoring) {
        self.apiClient = apiClient
        self.identityProvider = identityProvider
        self.sponsorPaymentRequestViewModel = NewRequestPopUpViewModel(
            apiClient: apiClient,
            sessionPreferences: identityProvider
        )
        bindPayNowPipeline()
        bindSponsorPaymentInitiationPipeline()
    }

    deinit { postStripeSuccessTask?.cancel() }

    private var hasLoaded = false
    private var voyageIdForPayment = ""
    private var postStripeSuccessTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Derived

    var currentUserId: String? {
        let id = identityProvider.userID.trimmingCharacters(in: .whitespacesAndNewlines)
        return id.isEmpty ? nil : id
    }

    var displayUsername: String {
        let name = identityProvider.username.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Unknown user" : name
    }

    var mainPhase: TravelNowMainPhase {
        if isLoading { return .loading }
        if statusCode == 404 { return .noVoyageFound }
        if statusCode == 200 { return travelNowData != nil ? .voyageContent : .noVoyageFound }
        if errorMessage != nil { return .retryableError }
        if travelNowData != nil { return .voyageContent }
        return .idle
    }

    var retryBannerMessage: String {
        guard let errorMessage, !errorMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "No voyage found"
        }
        return errorMessage
    }

    // MARK: - Private lifecycle

    private func onAppearLoad() {
        guard !hasLoaded else { return }
        hasLoaded = true
        fetchTravelNowVoyage()
    }

    private func onDisappearReset() {
        hasLoaded = false
        shouldDismissScreen = false
        postStripeSuccessTask?.cancel()
        postStripeSuccessTask = nil
    }

    private func startSponsorPaymentOnBehalf(voyageId: String) {
        guard let sponsorId = currentUserId else { errorMessage = "Missing user id."; return }
        voyageIdForPayment = voyageId
        withAnimation {
            sponsorPaymentRequestViewModel.getSponsorPaymentIds(voyagerId: voyageId, sponsorId: sponsorId, user: "VoyagerUserId")
            showPaymentPopup = false
        }
    }

    func makePaymentSheet() -> PaymentSheet? {
        guard let secret = stripeClientSecret else { return nil }
        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "Boat Sharing"
        return PaymentSheet(paymentIntentClientSecret: secret, configuration: config)
    }

    private func handleStripePaymentResult(_ result: PaymentSheetResult) {
        showStripeSheet = false
        stripeClientSecret = nil
        let intentId = stripePaymentIntentId
        let voyageId = voyageIdForPayment
        switch result {
        case .completed:
            toastMessage = "Payment successful"; isShowToast = true
            performSponsorPaymentConfirmation(voyageId: voyageId, paymentIntentId: intentId)
        case .canceled:
            toastMessage = "Payment canceled"; isShowToast = true
        case .failed(let error):
            toastMessage = "Payment failed: \(error.localizedDescription)"; isShowToast = true
        }
    }

    // MARK: - Combine wiring

    private func bindPayNowPipeline() {
        $payNow
            .removeDuplicates()
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in withAnimation { self?.showPaymentPopup = true } }
            .store(in: &cancellables)
    }

    private func bindSponsorPaymentInitiationPipeline() {
        sponsorPaymentRequestViewModel.$PaymentData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in self?.applySponsorPaymentInitiation(data) }
            .store(in: &cancellables)
    }

    private func applySponsorPaymentInitiation(_ data: PaymentInitiationData?) {
        guard let secret = data?.clientSecret else { return }
        stripePaymentIntentId = data?.PaymentIntentId ?? ""
        stripeClientSecret = secret
        showStripeSheet = true
    }

    // MARK: - Private network

    private func fetchTravelNowVoyage() {
        isLoading = true
        errorMessage = nil
        statusCode = nil
        Task {
            do {
                let response: TravelVoyageResponse = try await apiClient.request(
                    endpoint: "/Voyager/GetImmediatelyBookedVoyage",
                    method: .get,
                    parameters: nil,
                    requiresAuth: true
                )
                self.isLoading = false
                self.travelNowData = response.obj
                self.statusCode = response.status
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                self.statusCode = (error as? APIError).flatMap {
                    if case .serverError(let code, _) = $0 { return code } else { return nil }
                } ?? 500
            }
        }
    }

    private func performVoyageCancellation(voyageId: String) {
        loadingVoyageId = voyageId
        isCancelling = true
        Task {
            do {
                let _: VoyageValidationResponse = try await apiClient.request(
                    endpoint: "/Voyage/Cancel",
                    method: .post,
                    parameters: ["Id": voyageId],
                    requiresAuth: true
                )
                self.loadingVoyageId = nil
                self.isCancelling = false
                self.fetchTravelNowVoyage()
            } catch {
                self.loadingVoyageId = nil
                self.isCancelling = false
                self.errorMessage = error.localizedDescription
                self.fetchTravelNowVoyage()
            }
        }
    }

    private func performVoyageConfirmation(voyageId: String) {
        loadingVoyageId = voyageId
        isConfirming = true
        Task {
            do {
                let response: VoyageConfirmationResponse = try await apiClient.request(
                    endpoint: "/Voyage/Confirm",
                    method: .post,
                    parameters: ["Id": voyageId],
                    requiresAuth: true
                )
                self.loadingVoyageId = nil
                self.isConfirming = false
                if response.status == 200 {
                    self.payNow = true
                } else {
                    self.fetchTravelNowVoyage()
                }
            } catch {
                self.loadingVoyageId = nil
                self.isConfirming = false
                self.errorMessage = error.localizedDescription
                self.fetchTravelNowVoyage()
            }
        }
    }

    private func performSponsorPaymentConfirmation(voyageId: String, paymentIntentId: String) {
        Task {
            do {
                let _: PaymentSuccessResponse = try await apiClient.request(
                    endpoint: AppConfiguration.API.Endpoints.sponsorPaymentConfirmation,
                    method: .post,
                    parameters: ["Id": voyageId, "PaymentIntentId": paymentIntentId],
                    requiresAuth: true
                )
                self.fetchTravelNowVoyage()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Legacy surface

    func getTravelNowVoyage() { fetchTravelNowVoyage() }
    func voyageValidation(voyageId: String) { send(.cancelVoyage(voyageId)) }
    func voyageConfirmation(voyageId: String) { send(.confirmVoyage(voyageId)) }
    func sponsorsPaymentSuccess(voyageId: String, paymentIntentId: String) {
        performSponsorPaymentConfirmation(voyageId: voyageId, paymentIntentId: paymentIntentId)
    }
}
