import Combine
import SwiftUI

@MainActor
final class FutureVoyageViewModel: ObservableObject {

    // MARK: - Section

    enum Section: String {
        case unconfirmed = "Unconfirmed"
        case pending = "Pending"
    }

    // MARK: - State

    struct State {
        let selectedSection: Section
        let showPaymentPopup: Bool
        let showCancelPopup: Bool
        let toastMessage: String
        let isShowToast: Bool
        let isFutureVoyageLoading: Bool
        let voyageErrorMessage: String?
        let futureVoyageDetails: FutureVoyageDetails?
        let loadingVoyageId: String?
        let isConfirming: Bool
        let isCancelling: Bool
        let displayUsername: String
        let pendingInviteMessageUsername: String
        let showStripeSheet: Bool
    }

    var state: State {
        State(
            selectedSection: selectedSection,
            showPaymentPopup: showPaymentPopup,
            showCancelPopup: showCancelPopup,
            toastMessage: toastMessage,
            isShowToast: isShowToast,
            isFutureVoyageLoading: isFutureVoyageLoading,
            voyageErrorMessage: voyageErrorMessage,
            futureVoyageDetails: futureVoyageDetails,
            loadingVoyageId: loadingVoyageId,
            isConfirming: isConfirming,
            isCancelling: isCancelling,
            displayUsername: displayUsername,
            pendingInviteMessageUsername: pendingInviteMessageUsername,
            showStripeSheet: showStripeSheet
        )
    }

    // MARK: - Actions

    enum Action {
        case onAppear
        case dismissForBackNavigation
        case retry
        case selectSection(Section)
        case dismissPaymentPopup
        case payNow
        case presentCancelConfirmation(String)
        case confirmCancel
        case pendingPrimaryConfirm(String)
        case handleStripeResult(PaymentSheetResult)
        case dismissToast
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:                         performOnAppearLoad()
        case .dismissForBackNavigation:         performResetInitialLoadForDismiss()
        case .retry:                            loadVoyagesWithMissingUserToast()
        case .selectSection(let s):             selectedSection = s
        case .dismissPaymentPopup:              withAnimation { showPaymentPopup = false }
        case .payNow:                           startSponsorPaymentOnBehalf()
        case .presentCancelConfirmation(let id): selectedVoyageIdForCancel = id; showCancelPopup = true
        case .confirmCancel:                    performVoyageCancellation(voyageId: selectedVoyageIdForCancel)
        case .pendingPrimaryConfirm(let id):    performHandlePendingPrimaryConfirm(voyageId: id)
        case .handleStripeResult(let result):   performHandleStripePaymentResult(result)
        case .dismissToast:                    isShowToast = false
        }
    }

    // MARK: - Route

    @Published var route: Section?  // unused — kept for future extension

    // MARK: - Published state

    @Published var selectedSection: Section = .unconfirmed
    @Published var showPaymentPopup = false
    @Published var showCancelPopup = false
    @Published var selectedVoyageIdForCancel: String = ""
    @Published var voyageIdForPayment: String = ""
    @Published var toastMessage: String = ""
    @Published var isShowToast: Bool = false
    @Published var showPendingText: Bool = false
    @Published var hasCompletedInitialAppear: Bool = false
    @Published var stripeClientSecret: String?
    @Published var stripePaymentIntentId: String = ""
    @Published var showStripeSheet: Bool = false
    @Published var futureVoyageDetails: FutureVoyageDetails?
    @Published var travelNowData: TravelNowVoyage?
    @Published var isFutureVoyageLoading: Bool = false
    @Published var voyageErrorMessage: String?
    @Published var loadingVoyageId: String?
    @Published var isConfirming: Bool = false
    @Published var isCancelling: Bool = false
    @Published var payNowTrigger: Bool = false
    @Published var PaymentConfirmed: Bool = false

    // MARK: - Dependencies

    private let networkRepository: AppNetworkRepositoryProtocol
    private let identityProvider: SessionPreferenceStoring
    private let sponsorPaymentRequestViewModel: NewRequestPopUpViewModel
    private var cancellables = Set<AnyCancellable>()
    private var stripePaymentCompletionTask: Task<Void, Never>?

    init(networkRepository: AppNetworkRepositoryProtocol, identityProvider: SessionPreferenceStoring) {
        self.networkRepository = networkRepository
        self.identityProvider = identityProvider
        self.sponsorPaymentRequestViewModel = NewRequestPopUpViewModel(
            networkRepository: networkRepository,
            sessionPreferences: identityProvider
        )
        bindPaymentConfirmedPipeline()
        bindPayNowPipeline()
        bindSponsorPaymentInitiationPipeline()
    }

    deinit { stripePaymentCompletionTask?.cancel() }

    // MARK: - Derived

    private var requiredUserId: String? {
        let id = identityProvider.userID.trimmingCharacters(in: .whitespacesAndNewlines)
        return id.isEmpty ? nil : id
    }

    var displayUsername: String {
        let name = identityProvider.username.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "User" : name
    }

    var pendingInviteMessageUsername: String {
        let name = identityProvider.username.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Username" : name
    }

    // MARK: - Private lifecycle

    private func performOnAppearLoad() {
        guard !hasCompletedInitialAppear else { return }
        hasCompletedInitialAppear = true
        loadVoyagesWithMissingUserToast()
    }

    private func performResetInitialLoadForDismiss() {
        hasCompletedInitialAppear = false
        stripePaymentCompletionTask?.cancel()
        stripePaymentCompletionTask = nil
    }

    private func loadVoyagesWithMissingUserToast() {
        guard let userID = requiredUserId else {
            toastMessage = "Missing user id."
            isShowToast = true
            return
        }
        fetchFutureVoyages(userid: userID)
    }

    private func startSponsorPaymentOnBehalf() {
        withAnimation {
            guard let userId = requiredUserId else {
                toastMessage = "Missing user id."
                isShowToast = true
                return
            }
            sponsorPaymentRequestViewModel.getSponsorPaymentIds(
                voyagerId: voyageIdForPayment,
                sponsorId: userId,
                user: "VoyagerUserId"
            )
            showPaymentPopup = false
        }
    }

    private func performHandlePendingPrimaryConfirm(voyageId: String) {
        voyageIdForPayment = voyageId
        performVoyageConfirmation(voyageId: voyageId)
        showPendingText = true
    }

    func makePaymentSheet() -> PaymentSheet? {
        guard let secret = stripeClientSecret else { return nil }
        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "Boat Sharing"
        return PaymentSheet(paymentIntentClientSecret: secret, configuration: config)
    }

    private func performHandleStripePaymentResult(_ result: PaymentSheetResult) {
        showStripeSheet = false
        stripeClientSecret = nil
        let intentId = stripePaymentIntentId
        let voyageId = voyageIdForPayment
        switch result {
        case .completed:
            toastMessage = "Payment successful"; isShowToast = true
            performSponsorPaymentConfirmation(voyageId: voyageId, paymentIntentId: intentId)
            loadVoyagesWithMissingUserToast()
        case .canceled:
            toastMessage = "Payment canceled"; isShowToast = true
        case .failed(let error):
            toastMessage = "Payment failed: \(error.localizedDescription)"; isShowToast = true
        }
    }

    // MARK: - Combine wiring

    private func bindPaymentConfirmedPipeline() {
        $PaymentConfirmed
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] confirmed in
                guard let self, confirmed else { return }
                self.performVoyageConfirmation(voyageId: self.voyageIdForPayment)
                self.PaymentConfirmed = false
            }
            .store(in: &cancellables)
    }

    private func bindPayNowPipeline() {
        $payNowTrigger
            .removeDuplicates()
            .filter { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in withAnimation { self?.showPaymentPopup = true } }
            .store(in: &cancellables)
    }

    private func bindSponsorPaymentInitiationPipeline() {
        sponsorPaymentRequestViewModel.paymentDataPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] data in self?.handlePaymentInitiationData(data) }
            .store(in: &cancellables)
    }

    private func handlePaymentInitiationData(_ data: PaymentInitiationData?) {
        guard let secret = data?.clientSecret else { return }
        stripePaymentIntentId = data?.paymentIntentId ?? ""
        stripeClientSecret = secret
        showStripeSheet = true
    }

    // MARK: - Private network

    private func fetchFutureVoyages(userid: String) {
        isFutureVoyageLoading = true
        voyageErrorMessage = nil
        Task {
            do {
                let response = try await networkRepository.voyager_getFutureBookedVoyages(userId: userid)
                self.isFutureVoyageLoading = false
                self.futureVoyageDetails = response.obj
            } catch {
                self.isFutureVoyageLoading = false
                self.voyageErrorMessage = error.localizedDescription
            }
        }
    }

    private func performVoyageCancellation(voyageId: String) {
        loadingVoyageId = voyageId
        isCancelling = true
        Task {
            do {
                _ = try await networkRepository.voyage_cancel(voyageId: voyageId)
                self.loadingVoyageId = nil
                self.isCancelling = false
                if let userID = self.requiredUserId { self.fetchFutureVoyages(userid: userID) }
                else { self.voyageErrorMessage = "Missing user id." }
            } catch {
                self.loadingVoyageId = nil
                self.isCancelling = false
                if let userID = self.requiredUserId { self.fetchFutureVoyages(userid: userID) }
                self.voyageErrorMessage = error.localizedDescription
            }
        }
    }

    private func performVoyageConfirmation(voyageId: String) {
        loadingVoyageId = voyageId
        isConfirming = true
        Task {
            do {
                let response: VoyageConfirmationResponse = try await networkRepository.voyage_confirm(voyageId: voyageId)
                self.loadingVoyageId = nil
                self.isConfirming = false
                if response.status == 200 {
                    guard let userID = self.requiredUserId else { self.voyageErrorMessage = "Missing user id."; return }
                    self.fetchFutureVoyages(userid: userID)
                } else if response.status == 400 || response.message == "Please Pay Completely first then you can confirm your voyage" {
                    self.payNowTrigger = true
                    self.showPaymentPopup = true
                } else {
                    guard let userID = self.requiredUserId else { self.voyageErrorMessage = "Missing user id."; return }
                    self.fetchFutureVoyages(userid: userID)
                }
            } catch let error as APIError {
                self.loadingVoyageId = nil
                self.isConfirming = false
                if case .serverError(let code, _) = error, code == 400 {
                    self.payNowTrigger = true
                    self.showPaymentPopup = true
                } else {
                    if let userID = self.requiredUserId { self.fetchFutureVoyages(userid: userID) }
                    self.voyageErrorMessage = error.localizedDescription
                }
            } catch {
                self.loadingVoyageId = nil
                self.isConfirming = false
                if let userID = self.requiredUserId { self.fetchFutureVoyages(userid: userID) }
                self.voyageErrorMessage = error.localizedDescription
            }
        }
    }

    private func performSponsorPaymentConfirmation(voyageId: String, paymentIntentId: String) {
        Task {
            do {
                _ = try await networkRepository.voyage_sponsorPaymentConfirm(voyageId: voyageId, paymentIntentId: paymentIntentId)
                self.PaymentConfirmed = true
            } catch {
                self.voyageErrorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Public action helpers

    func getActiveVoyager(userid: String) { fetchFutureVoyages(userid: userid) }
    func VoyageValidation(Voyageid: String) { send(.confirmCancel) }
    func VoyageConfirmation(Voyageid: String) { send(.pendingPrimaryConfirm(Voyageid)) }
    func sponsorsPaymentSuccess(voyageId: String, paymentIntentId: String) {
        performSponsorPaymentConfirmation(voyageId: voyageId, paymentIntentId: paymentIntentId)
    }
    func onAppearLoadVoyagesIfNeeded() { send(.onAppear) }
    func resetInitialLoadForDismiss() { send(.dismissForBackNavigation) }
    func retryAfterError() { send(.retry) }
    func selectSection(_ section: Section) { send(.selectSection(section)) }
    func dismissSponsorPaymentPopupOnly() { send(.dismissPaymentPopup) }
    func startSponsorPaymentOnBehalf_public() { send(.payNow) }
    func presentCancelConfirmation(voyageId: String) { send(.presentCancelConfirmation(voyageId)) }
    func confirmCancelVoyage() { send(.confirmCancel) }
    func handlePendingPrimaryConfirm(voyageId: String) { send(.pendingPrimaryConfirm(voyageId)) }
    func handleStripePaymentResult(_ result: PaymentSheetResult) { send(.handleStripeResult(result)) }
}

