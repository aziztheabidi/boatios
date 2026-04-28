import SwiftUI
import Combine

@MainActor
final class VoyagerHomeViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let docks: [DockLocation]
        let errorMessage: String?
        let voyage: VoyageSession?
        let isVoyageLoading: Bool
        let showFindBoatSheet: Bool
        let isCaptainFind: Bool
        let stackDestination: StackDestination?
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
            stackDestination: stackDestination,
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
            reset(); showFindBoatSheet = false; stackDestination = .spinMenu
        case .dismissCaptainOverlay:
            isCaptainFind = false
        case .captainOverlayWheelTapped(let reset):
            reset(); isCaptainFind = false; stackDestination = .spinMenu
        case .tokenExpiredAcknowledged:
            stackDestination = .login
        }
    }

    // MARK: - Stack navigation (single source of truth for pushed screens)

    enum StackDestination: Hashable {
        case spinMenu
        case createVoyage
        case login
    }

    @Published var stackDestination: StackDestination?

    // MARK: - Published state

    @Published var docks: [DockLocation] = []
    @Published var errorMessage: String?
    @Published var voyage: VoyageSession?
    @Published var isVoyageLoading: Bool = false
    @Published var voyageErrorMessage: String?
    @Published var isTokenExpired: Bool = false
    @Published var showFindBoatSheet: Bool = false
    @Published var isCaptainFind: Bool = false
    @Published var pickupLocation: DockLocation?
    @Published var dropoffLocation: DockLocation?

    // MARK: - Dependencies

    private let networkRepository: AppNetworkRepositoryProtocol
    private let identityProvider: SessionPreferenceStoring

    init(networkRepository: AppNetworkRepositoryProtocol, identityProvider: SessionPreferenceStoring) {
        self.networkRepository = networkRepository
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
        stackDestination = .spinMenu
    }

    /// Called after find-boat validation succeeds.
    func navigateToCreateVoyageAfterBooking() {
        stackDestination = .createVoyage
    }

    // MARK: - Private network

    private func fetchActiveDocks() {
        guard !hasFetchedDocks else { return }
        Task {
            do {
                let docks = try await networkRepository.dock_getActive()
                self.docks = docks.all
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
                let session = try await networkRepository.voyagerDashboard_getActiveVoyage(voyagerUserId: userid)
                self.isVoyageLoading = false
                self.voyage = session
                self.applyVoyageUpdate(session)
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

    private func applyVoyageUpdate(_ voyage: VoyageSession?) {
        guard isViewActive, let voyage else { return }
        isCaptainFind = !voyage.status.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Public action helpers

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

