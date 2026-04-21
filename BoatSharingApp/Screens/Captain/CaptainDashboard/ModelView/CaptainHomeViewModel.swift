import SwiftUI

@MainActor
final class CaptainHomeViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let isAuthenticated: Bool
        let errorMessage: String?
        let role: String
        let showWelcomeScreen: Bool
        let isLoading: Bool
        let isButtonBlue: Bool
        let showOfflinePopup: Bool
        let isUpdatingStatus: Bool
        let moveToMenu: Bool
    }

    var state: State {
        State(
            isAuthenticated: isAuthenticated,
            errorMessage: errorMessage,
            role: role,
            showWelcomeScreen: showWelcomeScreen,
            isLoading: isLoading,
            isButtonBlue: isButtonBlue,
            showOfflinePopup: showOfflinePopup,
            isUpdatingStatus: isUpdatingStatus,
            moveToMenu: moveToMenu
        )
    }

    // MARK: - Actions

    enum Action {
        case menuTapped
        case offlinePromptShown
        case offlinePromptDismissed
        case welcomeWheelTapped
        case confirmGoOffline
    }

    func send(_ action: Action) {
        switch action {
        case .menuTapped:           moveToMenu = true; route = .menu
        case .offlinePromptShown:   showOfflinePopup = true
        case .offlinePromptDismissed: showOfflinePopup = false
        case .welcomeWheelTapped:   handleWheelTap()
        case .confirmGoOffline:     goOffline()
        }
    }

    // MARK: - Route

    enum Route { case menu }
    @Published var route: Route?

    // MARK: - Published state

    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var role: String = ""
    @Published var showWelcomeScreen: Bool = true
    @Published var isLoading: Bool = false
    @Published var isButtonBlue: Bool = false
    @Published var showOfflinePopup: Bool = false
    @Published var isUpdatingStatus: Bool = false
    @Published var moveToMenu: Bool = false

    // MARK: - Dependencies

    private let preferences: PreferenceStoring
    private let apiClient: APIClientProtocol

    init(preferences: PreferenceStoring, apiClient: APIClientProtocol) {
        self.preferences = preferences
        self.apiClient = apiClient
        let isCaptainOnline = preferences.captainStatus
        showWelcomeScreen = !isCaptainOnline
        isButtonBlue = isCaptainOnline
    }

    // MARK: - Private logic

    private func handleWheelTap() {
        if isButtonBlue { showWelcomeScreen = false; return }
        goOnline()
    }

    private func goOnline() {
        isLoading = true
        let userId = preferences.userID.isEmpty ? "User ID" : preferences.userID
        Task {
            let success = await performUpdateCaptainStatus(userId: userId, isAvailable: "true")
            self.isLoading = false
            if success {
                self.isButtonBlue = true
                self.preferences.captainStatus = true
            }
        }
    }

    private func goOffline() {
        isUpdatingStatus = true
        let userId = preferences.userID.isEmpty ? "User ID" : preferences.userID
        Task {
            let success = await performUpdateCaptainStatus(userId: userId, isAvailable: "false")
            self.isUpdatingStatus = false
            if success {
                self.isButtonBlue = false
                self.preferences.captainStatus = false
                self.showWelcomeScreen = true
                self.showOfflinePopup = false
            }
        }
    }

    // MARK: - Private network

    /// Returns true on success, false on failure. Sets errorMessage on failure.
    @discardableResult
    private func performUpdateCaptainStatus(userId: String, isAvailable: String) async -> Bool {
        let parameters: [String: Any] = ["UserId": userId, "IsAvailable": isAvailable]
        do {
            let _: DeviceTokenResponse = try await apiClient.request(
                endpoint: "/CaptainProfile/Availability",
                method: .post,
                parameters: parameters,
                requiresAuth: true
            )
            self.isAuthenticated = true
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }

    /// Completion-based entry point for callers that predate async/await.
    func updateCaptainStatus(userId: String, isAvailable: String, completion: @escaping (Bool) -> Void) {
        Task {
            let success = await performUpdateCaptainStatus(userId: userId, isAvailable: isAvailable)
            completion(success)
        }
    }
}
