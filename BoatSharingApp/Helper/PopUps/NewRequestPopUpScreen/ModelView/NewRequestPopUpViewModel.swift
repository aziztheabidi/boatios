import SwiftUI
import Alamofire
import Combine

@MainActor
final class NewRequestPopUpViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let isPaymentLoading: Bool
        let isPaymentConfirming: Bool
        let paymentData: PaymentInitiationData?
        let paymentConfirmed: Bool
        let errorMessage: String?
        let toastMessage: String?
        let shouldHideToast: Bool
        let shouldDismissForCompletedVoyage: Bool
        let shouldNavigateToFeedback: Bool
    }

    var state: State {
        State(
            isPaymentLoading: isPaymentLoaded,
            isPaymentConfirming: isPaymentConfirmedloaded,
            paymentData: PaymentData,
            paymentConfirmed: PaymentConfirmed,
            errorMessage: initialPaymentErrorMessgae,
            toastMessage: toastMessage,
            shouldHideToast: shouldHideToast,
            shouldDismissForCompletedVoyage: shouldDismissPopupForCompletedVoyage,
            shouldNavigateToFeedback: shouldNavigateToFeedbackForCompletedVoyage
        )
    }

    // MARK: - Actions

    enum Action {
        case getPaymentIds(voyagerId: String)
        case getSponsorPaymentIds(voyagerId: String, sponsorId: String, user: String)
        case voyagerPaymentSuccess(voyageId: String, paymentIntentId: String)
        case sponsorPaymentSuccess(voyageId: String, paymentIntentId: String)
        case onAppear(voyageStatus: String)
        case scheduleToastHide
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
            scheduleToastHide()
        }
    }

    // MARK: - Route

    enum Route { case feedback; case dismissPopup }
    @Published var route: Route?

    // MARK: - Published state

    @Published var PaymentData: PaymentInitiationData?
    @Published var isPaymentLoaded: Bool = false
    @Published var initialpayemntsuccess: Bool = false
    @Published var PaymentConfirmed: Bool = false
    @Published var isPaymentConfirmedloaded: Bool = false
    @Published var initialPaymentErrorMessgae: String?
    @Published var toastMessage: String?
    @Published var shouldHideToast: Bool = false
    @Published var shouldDismissPopupForCompletedVoyage: Bool = false
    @Published var shouldNavigateToFeedbackForCompletedVoyage: Bool = false

    // MARK: - Dependencies

    private let apiClient: APIClientProtocol
    private let sessionPreferences: SessionPreferenceStoring
    private var toastHideCancellable: AnyCancellable?

    init(apiClient: APIClientProtocol, sessionPreferences: SessionPreferenceStoring) {
        self.apiClient = apiClient
        self.sessionPreferences = sessionPreferences
    }

    // MARK: - Derived

    var isCaptainRole: Bool {
        let canonical = AppConfiguration.UserRole.normalize(sessionPreferences.userRole)
        return AppConfiguration.UserRole(rawValue: canonical)?.rawValue == AppConfiguration.UserRole.captain.rawValue
            || canonical == AppConfiguration.UserRole.captain.rawValue
    }

    // MARK: - Compatibility shims (called directly by SponsorsPaymentViewModel and FutureVoyageViewModel)

    func getPaymentIds(voyagerId: String) { send(.getPaymentIds(voyagerId: voyagerId)) }
    func getSponsorPaymentIds(voyagerId: String, sponsorId: String, user: String) {
        send(.getSponsorPaymentIds(voyagerId: voyagerId, sponsorId: sponsorId, user: user))
    }

    // MARK: - Private network methods

    private func fetchPaymentIds(voyagerId: String) {
        isPaymentLoaded = true
        initialPaymentErrorMessgae = nil
        Task {
            do {
                let response: PaymentInitiationResponse = try await apiClient.request(
                    endpoint: "/Voyage/PaymentInitiate",
                    method: .post,
                    parameters: ["Id": voyagerId],
                    encoding: JSONEncoding.default,
                    requiresAuth: true
                )
                self.isPaymentLoaded = false
                self.initialpayemntsuccess = true
                self.PaymentData = response.obj
            } catch {
                self.isPaymentLoaded = false
                self.initialPaymentErrorMessgae = error.localizedDescription
            }
        }
    }

    private func confirmVoyagerPayment(voyageId: String, paymentIntentId: String) {
        isPaymentLoaded = true
        initialPaymentErrorMessgae = nil
        Task {
            do {
                let _: PaymentSuccessResponse = try await apiClient.request(
                    endpoint: "/Voyage/PaymentConfirmation",
                    method: .post,
                    parameters: ["Id": voyageId, "PaymentIntentId": paymentIntentId],
                    encoding: JSONEncoding.default,
                    requiresAuth: true
                )
                self.isPaymentConfirmedloaded = false
                self.PaymentConfirmed = true
            } catch {
                self.isPaymentConfirmedloaded = false
                self.initialPaymentErrorMessgae = error.localizedDescription
            }
        }
    }

    private func confirmSponsorPayment(voyageId: String, paymentIntentId: String) {
        isPaymentLoaded = true
        initialPaymentErrorMessgae = nil
        Task {
            do {
                let _: PaymentSuccessResponse = try await apiClient.request(
                    endpoint: AppConfiguration.API.Endpoints.sponsorPaymentConfirmation,
                    method: .post,
                    parameters: ["Id": voyageId, "PaymentIntentId": paymentIntentId],
                    encoding: JSONEncoding.default,
                    requiresAuth: true
                )
                self.isPaymentConfirmedloaded = false
                self.PaymentConfirmed = true
            } catch {
                self.isPaymentConfirmedloaded = false
                self.initialPaymentErrorMessgae = error.localizedDescription
            }
        }
    }

    private func fetchSponsorPaymentIds(voyagerId: String, sponsorId: String, user: String) {
        isPaymentLoaded = true
        initialPaymentErrorMessgae = nil
        var parameters: [String: Any] = ["Id": voyagerId, user: sponsorId]
        if user == "SponsorUserId" { parameters["SponserUserId"] = sponsorId }
        Task {
            do {
                let response: PaymentInitiationResponse = try await apiClient.request(
                    endpoint: AppConfiguration.API.Endpoints.sponsorPaymentInitiate,
                    method: .post,
                    parameters: parameters,
                    encoding: JSONEncoding.default,
                    requiresAuth: true
                )
                self.isPaymentLoaded = false
                self.initialpayemntsuccess = true
                self.PaymentData = response.obj
            } catch {
                self.isPaymentLoaded = false
                self.initialPaymentErrorMessgae = error.localizedDescription
            }
        }
    }

    private func handleOnAppear(voyageStatus: String) {
        guard voyageStatus.lowercased() == "completed" else { return }
        shouldDismissPopupForCompletedVoyage = true
        shouldNavigateToFeedbackForCompletedVoyage = true
        route = .dismissPopup
    }

    private func scheduleToastHide() {
        toastHideCancellable?.cancel()
        toastHideCancellable = Just(())
            .delay(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.shouldHideToast = true }
    }

    // MARK: - Legacy surface kept for call-site compat

    func scheduleToastHide() { send(.scheduleToastHide) }
}
