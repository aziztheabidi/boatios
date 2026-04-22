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
        let stackDestination: StackDestination?
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
            stackDestination: stackDestination
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
        case .menuTapped:
            stackDestination = .spinMenu
        case .offlinePromptShown:   showOfflinePopup = true
        case .offlinePromptDismissed: showOfflinePopup = false
        case .welcomeWheelTapped:   handleWheelTap()
        case .confirmGoOffline:     goOffline()
        }
    }

    // MARK: - Stack navigation

    enum StackDestination: Hashable {
        case spinMenu
    }

    @Published var stackDestination: StackDestination?

    // MARK: - Published state

    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var role: String = ""
    @Published var showWelcomeScreen: Bool = true
    @Published var isLoading: Bool = false
    @Published var isButtonBlue: Bool = false
    @Published var showOfflinePopup: Bool = false
    @Published var isUpdatingStatus: Bool = false

    // MARK: - Dependencies

    private let preferences: PreferenceStoring
    private let networkRepository: AppNetworkRepositoryProtocol

    init(preferences: PreferenceStoring, networkRepository: AppNetworkRepositoryProtocol) {
        self.preferences = preferences
        self.networkRepository = networkRepository
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
        do {
            _ = try await networkRepository.captainProfile_setAvailability(
                userId: userId,
                isAvailable: isAvailable
            )
            self.isAuthenticated = true
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }

}

extension CaptainHomeViewModel {
    func handleMenuTapped() { send(.menuTapped) }
    func handleOfflinePromptShown() { send(.offlinePromptShown) }
    func handleOfflinePromptDismissed() { send(.offlinePromptDismissed) }
    func handleWelcomeWheelTapped() { send(.welcomeWheelTapped) }
    func confirmGoOffline() { send(.confirmGoOffline) }
}

