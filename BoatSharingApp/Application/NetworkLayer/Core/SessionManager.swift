import Foundation
import Combine

// MARK: - Session Event
enum SessionEvent: Equatable {
    case sessionExpired
    case tokenRefreshed
    case loginRequired
}

// MARK: - Session Manager
class SessionManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated: Bool = false
    
    // Event publisher for session-related events
    let eventPublisher = PassthroughSubject<SessionEvent, Never>()
    
    private let tokenStore: TokenStoring
    private let preferences: SessionPreferenceStoring
    private let refreshService: RefreshTokenServicing
    private let refreshCoordinator = RefreshCoordinator()
    
    init(
        tokenStore: TokenStoring,
        preferences: SessionPreferenceStoring,
        refreshService: RefreshTokenServicing
    ) {
        self.tokenStore = tokenStore
        self.preferences = preferences
        self.refreshService = refreshService
        self.isAuthenticated = self.hasValidSession()
    }
    
    // MARK: - Token Management
    
    var accessToken: String? {
        tokenStore.accessToken
    }
    
    var refreshToken: String? {
        tokenStore.refreshToken
    }
    
    func saveTokens(accessToken: String, refreshToken: String) {
        tokenStore.accessToken = accessToken
        tokenStore.refreshToken = refreshToken
        isAuthenticated = true
    }
    
    func clearTokens() {
        tokenStore.clearSessionTokens()
        isAuthenticated = false
    }
    
    // MARK: - User Data Management
    
    func saveUserData(userID: String, username: String, email: String, role: String, missingStep: Int? = nil) {
        preferences.userID = userID
        preferences.username = username
        preferences.userEmail = email
        preferences.userRole = AppConfiguration.UserRole.normalize(role)
        preferences.isLoggedIn = true
        preferences.missingStep = missingStep ?? 1
    }
    
    func clearUserData() {
        preferences.clearSessionPreferences()
    }
    
    var userRole: String? {
        preferences.userRole
    }
    
    var missingStep: Int? {
        preferences.missingStep
    }
    
    // MARK: - Session Management
    
    func hasValidSession() -> Bool {
        return accessToken != nil && refreshToken != nil
    }
    
    func refreshToken() async -> Bool {
        if let sharedResult = await refreshCoordinator.waitForOngoingRefreshOrMarkRunning() {
            return sharedResult
        }

        guard let accessToken = self.accessToken,
              let refreshToken = self.refreshToken else {
            expireSessionForRefreshFailure()
            return await completeRefreshAndReturn(false)
        }

        do {
            let refreshed = try await refreshService.refreshToken(
                accessToken: accessToken,
                refreshToken: refreshToken
            )
            saveTokens(
                accessToken: refreshed.Accesstoken,
                refreshToken: refreshed.Refreshtoken
            )
            eventPublisher.send(.tokenRefreshed)
            return await completeRefreshAndReturn(true)
        } catch {
            expireSessionForRefreshFailure()
            return await completeRefreshAndReturn(false)
        }
    }
    
    /// Force-expire session with storage clearing first, then event emission.
    /// This guarantees logout is not coupled to UI availability.
    private func expireSessionForRefreshFailure() {
        clearTokens()
        clearUserData()
        Task { @MainActor in
            self.eventPublisher.send(.sessionExpired)
        }
    }

    private func completeRefreshAndReturn(_ success: Bool) async -> Bool {
        await refreshCoordinator.completeRefresh(success: success)
        return success
    }
    
    func logout() {
        clearTokens()
        clearUserData()
        eventPublisher.send(.loginRequired)
    }
}

extension SessionManager: SessionManaging {}

private actor RefreshCoordinator {
    private var isRefreshing = false
    private var refreshContinuations: [CheckedContinuation<Bool, Never>] = []

    /// Atomically decides whether caller should wait for an in-flight refresh or start a new one.
    func waitForOngoingRefreshOrMarkRunning() async -> Bool? {
        guard isRefreshing else {
            isRefreshing = true
            return nil
        }
        return await withCheckedContinuation { continuation in
            refreshContinuations.append(continuation)
        }
    }

    func completeRefresh(success: Bool) {
        isRefreshing = false
        let waiters = refreshContinuations
        refreshContinuations.removeAll()
        waiters.forEach { $0.resume(returning: success) }
    }
}

struct LiveRefreshTokenService: RefreshTokenServicing {
    func refreshToken(accessToken: String, refreshToken: String) async throws -> SessionTokenData {
        try await APIClient.refreshSessionTokens(accessToken: accessToken, refreshToken: refreshToken)
    }
}
