import SwiftUI
import Combine

@MainActor
final class NewRequestPopUpViewModel: ObservableObject {

    struct State: Equatable {
        var isPaymentLoaded: Bool = false
        var initialPaymentSuccess: Bool = false
        var paymentData: PaymentInitiationData?
        var paymentConfirmed: Bool = false
        var isPaymentConfirmedLoaded: Bool = false
        var initialPaymentErrorMessage: String?
        var toastMessage: String?
        var shouldHideToast: Bool = false
        var shouldDismissPopupForCompletedVoyage: Bool = false
        var shouldNavigateToFeedbackForCompletedVoyage: Bool = false
        var route: Route?
    }

    enum Action: Equatable {
        case getPaymentIds(voyagerId: String)
        case getSponsorPaymentIds(voyagerId: String, sponsorId: String, user: String)
        case voyagerPaymentSuccess(voyageId: String, paymentIntentId: String)
        case sponsorPaymentSuccess(voyageId: String, paymentIntentId: String)
        case onAppear(voyageStatus: String)
        case scheduleToastHide
    }

    enum Route: Equatable {
        case feedback
        case dismissPopup
    }

    @Published private(set) var state = State()

    /// Combine subscriptions on payment data (Stripe sheet wiring in parent VMs).
    var paymentDataPublisher: AnyPublisher<PaymentInitiationData?, Never> {
        $state.map(\.paymentData).removeDuplicates().eraseToAnyPublisher()
    }

    private let networkRepository: AppNetworkRepositoryProtocol
    private let sessionPreferences: SessionPreferenceStoring
    private var toastHideCancellable: AnyCancellable?

    init(networkRepository: AppNetworkRepositoryProtocol, sessionPreferences: SessionPreferenceStoring) {
        self.networkRepository = networkRepository
        self.sessionPreferences = sessionPreferences
    }

    func send(_ action: Action) {
        switch action {
        case .getPaymentIds(let id):
            fetchPaymentIds(voyagerId: id)
        case .getSponsorPaymentIds(let vid, let sid, let user):
            fetchSponsorPaymentIds(voyagerId: vid, sponsorId: sid, user: user)
        case .voyagerPaymentSuccess(let vid, let pid):
            confirmVoyagerPayment(voyageId: vid, paymentIntentId: pid)
        case .sponsorPaymentSuccess(let vid, let pid):
            confirmSponsorPayment(voyageId: vid, paymentIntentId: pid)
        case .onAppear(let status):
            handleOnAppear(voyageStatus: status)
        case .scheduleToastHide:
            scheduleToastHideAfterDelay()
        }
    }

    func getPaymentIds(voyagerId: String) { send(.getPaymentIds(voyagerId: voyagerId)) }
    func getSponsorPaymentIds(voyagerId: String, sponsorId: String, user: String) {
        send(.getSponsorPaymentIds(voyagerId: voyagerId, sponsorId: sponsorId, user: user))
    }

    func scheduleToastHide() { send(.scheduleToastHide) }

    /// Called after Stripe sheet completes for voyager payment; keeps prior UX timing (intentional short delay).
    func completeVoyagerPaymentAfterDelay(voyageId: String, paymentIntentId: String) async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        send(.voyagerPaymentSuccess(voyageId: voyageId, paymentIntentId: paymentIntentId))
    }

    /// Called after Stripe sheet completes for sponsor payment; mirrors voyager delay before confirm API.
    func completeSponsorPaymentAfterDelay(voyageId: String, paymentIntentId: String) async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        send(.sponsorPaymentSuccess(voyageId: voyageId, paymentIntentId: paymentIntentId))
    }

    var isCaptainRole: Bool {
        let canonical = AppConfiguration.UserRole.normalize(sessionPreferences.userRole)
        return AppConfiguration.UserRole(rawValue: canonical)?.rawValue == AppConfiguration.UserRole.captain.rawValue
            || canonical == AppConfiguration.UserRole.captain.rawValue
    }

    var paymentPrimaryButtonTitle: String { isCaptainRole ? "Accept" : "Pay Now" }

    var sessionUserId: String {
        sessionPreferences.userID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var receiptEmailSnippet: String {
        let e = sessionPreferences.userEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        return e.isEmpty ? "your email" : e
    }

    func trackRideChatPeerUserId(for voyage: VoyageSession) -> String {
        if isCaptainRole {
            return (voyage.voyagerUserId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return voyage.captainUserId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func displayNameForTrackRideCounterparty(for voyage: VoyageSession) -> String {
        if isCaptainRole {
            return (voyage.voyagerName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return voyage.captainName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func voyageBookingDetails(for voyage: VoyageSession) -> VoyageBookingDetails {
        VoyageBookingDetails(
            voyageID: voyage.id,
            voyagerName: displayNameForTrackRideCounterparty(for: voyage),
            voyagerCount: voyage.numberOfVoyagers,
            pickupDock: voyage.pickupDock,
            dropOffDock: voyage.dropOffDock,
            amountToPay: voyage.amountToPay,
            duration: voyage.duration.trimmingCharacters(in: .whitespacesAndNewlines),
            waterStay: voyage.waterStay.trimmingCharacters(in: .whitespacesAndNewlines),
            bookingDateTime: voyage.bookingDateTime.trimmingCharacters(in: .whitespacesAndNewlines),
            voyagerPhone: (voyage.voyagerPhoneNumber ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            chatPeerUserId: trackRideChatPeerUserId(for: voyage)
        )
    }

    private func mutate(_ update: (inout State) -> Void) {
        var next = state
        update(&next)
        state = next
    }

    private func fetchPaymentIds(voyagerId: String) {
        mutate {
            $0.isPaymentLoaded = true
            $0.initialPaymentErrorMessage = nil
        }
        Task { @MainActor in
            do {
                let response = try await networkRepository.voyage_paymentInitiate(voyagerId: voyagerId)
                mutate {
                    $0.isPaymentLoaded = false
                    $0.initialPaymentSuccess = true
                    $0.paymentData = response.obj
                }
            } catch {
                mutate {
                    $0.isPaymentLoaded = false
                    $0.initialPaymentErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func confirmVoyagerPayment(voyageId: String, paymentIntentId: String) {
        mutate {
            $0.isPaymentLoaded = true
            $0.initialPaymentErrorMessage = nil
        }
        Task { @MainActor in
            do {
                _ = try await networkRepository.voyage_paymentConfirm(voyageId: voyageId, paymentIntentId: paymentIntentId)
                mutate {
                    $0.isPaymentConfirmedLoaded = false
                    $0.paymentConfirmed = true
                }
            } catch {
                mutate {
                    $0.isPaymentConfirmedLoaded = false
                    $0.initialPaymentErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func confirmSponsorPayment(voyageId: String, paymentIntentId: String) {
        mutate {
            $0.isPaymentLoaded = true
            $0.initialPaymentErrorMessage = nil
        }
        Task { @MainActor in
            do {
                _ = try await networkRepository.voyage_sponsorPaymentConfirm(voyageId: voyageId, paymentIntentId: paymentIntentId)
                mutate {
                    $0.isPaymentConfirmedLoaded = false
                    $0.paymentConfirmed = true
                }
            } catch {
                mutate {
                    $0.isPaymentConfirmedLoaded = false
                    $0.initialPaymentErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func fetchSponsorPaymentIds(voyagerId: String, sponsorId: String, user: String) {
        mutate {
            $0.isPaymentLoaded = true
            $0.initialPaymentErrorMessage = nil
        }
        var parameters: [String: Any] = ["Id": voyagerId, user: sponsorId]
        if user == BackendContractCoding.SponsorPaymentInitiateKey.sponsorUserIdCanonical {
            parameters[BackendContractCoding.SponsorPaymentInitiateKey.sponsorUserIdBackendVariant] = sponsorId
        }
        Task { @MainActor in
            do {
                let response = try await networkRepository.voyage_sponsorPaymentInitiate(parameters: parameters)
                mutate {
                    $0.isPaymentLoaded = false
                    $0.initialPaymentSuccess = true
                    $0.paymentData = response.obj
                }
            } catch {
                mutate {
                    $0.isPaymentLoaded = false
                    $0.initialPaymentErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func handleOnAppear(voyageStatus: String) {
        guard voyageStatus.lowercased() == "completed" else { return }
        mutate {
            $0.shouldDismissPopupForCompletedVoyage = true
            $0.shouldNavigateToFeedbackForCompletedVoyage = true
            $0.route = .dismissPopup
        }
    }

    private func scheduleToastHideAfterDelay() {
        toastHideCancellable?.cancel()
        toastHideCancellable = Just(())
            .delay(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.mutate { $0.shouldHideToast = true } }
    }
}
