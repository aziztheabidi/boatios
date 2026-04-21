import SwiftUI
import Combine

@MainActor
final class VoyagerHomeViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let docks: [Dock]
        let errorMessage: String?
        let voyage: VoyagerVoyage?
        let isVoyageLoading: Bool
        let showFindBoatSheet: Bool
        let isCaptainFind: Bool
        let moveToMenu: Bool
        let moveToNext: Bool
        let moveToLogin: Bool
        let isTokenExpired: Bool
    }

    var state: State {
        State(
            docks: docks,
            errorMessage: errorMessage,
            voyage: voyage,
            isVoyageLoading: isVoyageLoading,
            showFindBoatSheet: showFindBoatSheet,
            isCaptainFind: isCaptainFind,
            moveToMenu: moveToMenu,
            moveToNext: moveToNext,
            moveToLogin: moveToLogin,
            isTokenExpired: isTokenExpired
        )
    }

    // MARK: - Actions

    enum Action {
        case onAppear(UIFlowState)
        case onDisappear
        case ensureDocksLoaded
        case menuTapped(resetRoleMenus: () -> Void)
        case findBoatTapped
        case dismissFindBoat
        case dismissFindBoatToMenu(resetRoleMenus: () -> Void)
        case dismissCaptainOverlay
        case captainOverlayWheelTapped(resetRoleMenus: () -> Void)
        case tokenExpiredAcknowledged
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear(let flowState):
            onAppearLoad(uiFlowState: flowState)
        case .onDisappear:
            onDisappearReset()
        case .ensureDocksLoaded:
            fetchActiveDocks()
        case .menuTapped(let reset):
            handleMenuTapped(resetRoleMenus: reset)
        case .findBoatTapped:
            showFindBoatSheet = true
        case .dismissFindBoat:
            showFindBoatSheet = false
        case .dismissFindBoatToMenu(let reset):
            reset(); showFindBoatSheet = false; moveToMenu = true; route = .menu
        case .dismissCaptainOverlay:
            isCaptainFind = false
        case .captainOverlayWheelTapped(let reset):
            reset(); isCaptainFind = false; moveToMenu = true; route = .menu
        case .tokenExpiredAcknowledged:
            moveToLogin = true; route = .login
        }
    }

    // MARK: - Route

    enum Route { case menu; case next; case login }
    @Published var route: Route?

    // MARK: - Published state

    @Published var docks: [Dock] = []
    @Published var errorMessage: String?
    @Published var voyage: VoyagerVoyage?
    @Published var isVoyageLoading: Bool = false
    @Published var voyageErrorMessage: String?
    @Published var isTokenExpired: Bool = false
    @Published var showFindBoatSheet: Bool = false
    @Published var moveToMenu: Bool = false
    @Published var moveToNext: Bool = false
    @Published var isCaptainFind: Bool = false
    @Published var moveToLogin: Bool = false
    @Published var isConfirmPayment: Bool = false
    @Published var pickupLocation: Dock?
    @Published var dropoffLocation: Dock?

    // MARK: - Dependencies

    private let apiClient: APIClientProtocol
    private let identityProvider: SessionPreferenceStoring

    init(apiClient: APIClientProtocol, identityProvider: SessionPreferenceStoring) {
        self.apiClient = apiClient
        self.identityProvider = identityProvider
    }

    // MARK: - Private state

    private var hasFetchedDocks = false
    private var isViewActive = false
    private var pendingPresentFindBoatSheet = false
    private var initialVoyageLoadCancellable: AnyCancellable?
    private var voyageRefreshCancellable: AnyCancellable?

    private var currentUserId: String? {
        let id = identityProvider.userID.trimmingCharacters(in: .whitespacesAndNewlines)
        return id.isEmpty ? nil : id
    }

    // MARK: - Private lifecycle

    private func onAppearLoad(uiFlowState: UIFlowState) {
        guard !isViewActive else { return }
        isViewActive = true

        if uiFlowState.businessVoyageSelection != nil { pendingPresentFindBoatSheet = true }
        fetchActiveDocks()
        if pendingPresentFindBoatSheet, hasFetchedDocks { presentFindBoatSheetIfPending() }
        if uiFlowState.isFindingBoat { isCaptainFind = true }

        initialVoyageLoadCancellable?.cancel()
        initialVoyageLoadCancellable = Just(())
            .delay(for: .seconds(3), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, self.isViewActive else { return }
                guard let userId = self.currentUserId else {
                    self.voyageErrorMessage = "Missing voyager user id."
                    return
                }
                self.fetchActiveVoyage(userid: userId)
            }
        startActiveVoyagePolling()
    }

    private func onDisappearReset() {
        isViewActive = false
        initialVoyageLoadCancellable?.cancel()
        initialVoyageLoadCancellable = nil
        voyageRefreshCancellable?.cancel()
        voyageRefreshCancellable = nil
        pickupLocation = nil
        dropoffLocation = nil
    }

    private func presentFindBoatSheetIfPending() {
        guard isViewActive, pendingPresentFindBoatSheet else { return }
        pendingPresentFindBoatSheet = false
        showFindBoatSheet = true
    }

    private func startActiveVoyagePolling() {
        voyageRefreshCancellable?.cancel()
        voyageRefreshCancellable = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.isViewActive else { return }
                guard let userId = self.currentUserId else {
                    self.voyageErrorMessage = "Missing voyager user id."
                    return
                }
                self.fetchActiveVoyage(userid: userId)
            }
    }

    private func handleMenuTapped(resetRoleMenus: () -> Void) {
        resetRoleMenus()
        moveToMenu = true
        route = .menu
    }

    // MARK: - Private network

    private func fetchActiveDocks() {
        guard !hasFetchedDocks else { return }
        Task {
            do {
                let response: ActiveDocksResponse = try await apiClient.request(
                    endpoint: "/Dock/GetActive",
                    method: .get,
                    parameters: nil,
                    requiresAuth: true
                )
                self.docks = response.obj.all
                self.hasFetchedDocks = true
                self.presentFindBoatSheetIfPending()
            } catch let error as APIError {
                if case .unauthorized = error { self.isTokenExpired = true }
                else { self.errorMessage = error.localizedDescription }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func fetchActiveVoyage(userid: String) {
        isVoyageLoading = true
        voyageErrorMessage = nil
        Task {
            do {
                let response: ActiveVoyagerResponse = try await apiClient.request(
                    endpoint: "/VoyagerDashboard/GetActiveVoyage?VoyagerUserId=\(userid)",
                    method: .get,
                    parameters: nil,
                    requiresAuth: true
                )
                self.isVoyageLoading = false
                self.voyage = response.obj
                self.applyVoyageUpdate(response.obj)
            } catch let error as APIError {
                self.isVoyageLoading = false
                if case .unauthorized = error { self.isTokenExpired = true }
                else { self.voyageErrorMessage = error.localizedDescription }
            } catch {
                self.isVoyageLoading = false
                self.voyageErrorMessage = error.localizedDescription
            }
        }
    }

    private func applyVoyageUpdate(_ voyage: VoyagerVoyage?) {
        guard isViewActive, let voyage else { return }
        isCaptainFind = !(voyage.status.isEmpty ?? true)
    }

    // MARK: - Legacy public surface kept for existing view call-sites

    func getActiveDockList() { fetchActiveDocks() }
    func resetDockCache() { hasFetchedDocks = false; docks = [] }
    func getActiveVoyager(userid: String) { fetchActiveVoyage(userid: userid) }
    func handleMenuTapped(resetRoleMenus: () -> Void) { send(.menuTapped(resetRoleMenus: resetRoleMenus)) }
    func handleFindBoatTapped() { send(.findBoatTapped) }
    func handleFindBoatOverlayDismiss() { send(.dismissFindBoat) }
    func handleFindBoatWheelDismissToMenu(resetRoleMenus: () -> Void) { send(.dismissFindBoatToMenu(resetRoleMenus: resetRoleMenus)) }
    func handleCaptainOverlayDismiss() { send(.dismissCaptainOverlay) }
    func handleCaptainOverlayWheelTapped(resetRoleMenus: () -> Void) { send(.captainOverlayWheelTapped(resetRoleMenus: resetRoleMenus)) }
    func handleTokenExpiredAcknowledged() { send(.tokenExpiredAcknowledged) }
    func onAppearLoad(uiFlowState: UIFlowState) { send(.onAppear(uiFlowState)) }
    func onDisappearReset() { send(.onDisappear) }
}
