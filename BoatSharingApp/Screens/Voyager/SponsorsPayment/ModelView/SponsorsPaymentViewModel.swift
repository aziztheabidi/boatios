import SwiftUI

@MainActor
final class SponsorsPaymentViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let sponsorPayments: [SponsorPayment]
        let filteredPayments: [SponsorPayment]
        let isLoading: Bool
        let errorMessage: String?
        let searchText: String
        let toastMessage: String
        let isShowingToast: Bool
        let shouldPresentStripeSheet: Bool
        let stripeClientSecret: String?
        let paymentIntentID: String
        let shouldDismissScreen: Bool
    }

    var state: State {
        State(
            sponsorPayments: sponsorPayments,
            filteredPayments: filteredPayments,
            isLoading: isLoading,
            errorMessage: errorMessage,
            searchText: searchText,
            toastMessage: toastMessage,
            isShowingToast: isShowingToast,
            shouldPresentStripeSheet: shouldPresentStripeSheet,
            stripeClientSecret: stripeClientSecret,
            paymentIntentID: paymentIntentID,
            shouldDismissScreen: shouldDismissScreen
        )
    }

    // MARK: - Actions

    enum Action {
        case onAppear
        case onDisappear
        case retry
        case updateSearchText(String)
        case requestPaymentIds(voyageId: String, paymentViewModel: NewRequestPopUpViewModel)
        case configureStripe(secret: String, paymentIntentId: String)
        case paymentCompleted
        case paymentCanceled
        case paymentFailed(String)
        case dismissScreen
        case clearDismissRequest
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            onAppearLoad()
        case .onDisappear:
            onDisappearReset()
        case .retry:
            fetchSponsorPayments()
        case .updateSearchText(let text):
            searchText = text
        case .requestPaymentIds(let voyageId, let paymentViewModel):
            requestSponsorPaymentIds(for: voyageId, paymentViewModel: paymentViewModel)
        case .configureStripe(let secret, let intentId):
            configureStripeSheet(secret: secret, paymentIntentId: intentId)
        case .paymentCompleted:
            handlePaymentCompleted()
        case .paymentCanceled:
            handlePaymentCanceled()
        case .paymentFailed(let message):
            handlePaymentFailed(message)
        case .dismissScreen:
            shouldDismissScreen = true
        case .clearDismissRequest:
            shouldDismissScreen = false
        }
    }

    // MARK: - Route

    enum Route { case paymentSuccess }
    @Published var route: Route?

    // MARK: - Published state

    @Published var sponsorPayments: [SponsorPayment] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    @Published var toastMessage: String = ""
    @Published var isShowingToast: Bool = false
    @Published var shouldNavigateToSuccess: Bool = false
    @Published var shouldPresentStripeSheet: Bool = false
    @Published var stripeClientSecret: String?
    @Published var paymentIntentID: String = ""
    @Published var shouldDismissScreen: Bool = false

    // MARK: - Dependencies

    private let networkRepository: AppNetworkRepositoryProtocol
    private let sessionPreferences: SessionPreferenceStoring
    private var hasLoaded = false
    private var navigateToSuccessTask: Task<Void, Never>?

    init(networkRepository: AppNetworkRepositoryProtocol, sessionPreferences: SessionPreferenceStoring) {
        self.networkRepository = networkRepository
        self.sessionPreferences = sessionPreferences
    }

    // MARK: - Derived

    var filteredPayments: [SponsorPayment] {
        guard !searchText.isEmpty else { return sponsorPayments }
        return sponsorPayments.filter { $0.voyagerName.lowercased().contains(searchText.lowercased()) }
    }

    private var currentUserId: String? {
        let id = sessionPreferences.userID.trimmingCharacters(in: .whitespacesAndNewlines)
        return id.isEmpty ? nil : id
    }

    // MARK: - Private lifecycle

    private func onAppearLoad() {
        guard !hasLoaded else { return }
        hasLoaded = true
        fetchSponsorPayments()
    }

    private func onDisappearReset() {
        hasLoaded = false
        shouldDismissScreen = false
        navigateToSuccessTask?.cancel()
        navigateToSuccessTask = nil
    }

    // MARK: - Private action handlers

    private func requestSponsorPaymentIds(for voyageId: String, paymentViewModel: NewRequestPopUpViewModel) {
        guard let userId = currentUserId else { errorMessage = "Missing user id."; return }
        paymentViewModel.getSponsorPaymentIds(voyagerId: voyageId, sponsorId: userId, user: "SponsorUserId")
    }

    private func configureStripeSheet(secret: String, paymentIntentId: String) {
        stripeClientSecret = secret
        paymentIntentID = paymentIntentId
        shouldPresentStripeSheet = true
    }

    private func handlePaymentCompleted() {
        toastMessage = "Payment successful"
        isShowingToast = true
        shouldPresentStripeSheet = false
        shouldNavigateToSuccess = true
        route = .paymentSuccess
    }

    private func handlePaymentCanceled() {
        toastMessage = "Payment canceled"
        isShowingToast = true
        shouldPresentStripeSheet = false
    }

    private func handlePaymentFailed(_ message: String) {
        toastMessage = "Payment failed: \(message)"
        isShowingToast = true
        shouldPresentStripeSheet = false
    }

    // MARK: - Private network

    private func fetchSponsorPayments() {
        isLoading = true
        guard let userId = currentUserId else { isLoading = false; errorMessage = "Missing user id."; return }
        Task {
            do {
                let response = try await networkRepository.voyager_getSponsorPayments(userId: userId)
                self.isLoading = false
                if response.status == 200 {
                    self.sponsorPayments = response.obj
                } else {
                    self.errorMessage = response.message
                }
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

