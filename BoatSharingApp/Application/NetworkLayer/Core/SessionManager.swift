import Foundation
import Alamofire
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
    private var isRefreshing = false
    private var refreshContinuations: [CheckedContinuation<Bool, Never>] = []
    private let refreshLock = NSLock()
    
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
        refreshLock.lock()
        if isRefreshing {
            refreshLock.unlock()
            return await withCheckedContinuation { continuation in
                refreshLock.lock()
                refreshContinuations.append(continuation)
                refreshLock.unlock()
            }
        }
        isRefreshing = true
        refreshLock.unlock()

        guard let accessToken = self.accessToken,
              let refreshToken = self.refreshToken else {
            expireSessionForRefreshFailure()
            completeRefresh(success: false)
            return false
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
            completeRefresh(success: true)
            return true
        } catch {
            expireSessionForRefreshFailure()
            completeRefresh(success: false)
            return false
        }
    }

    private func completeRefresh(success: Bool) {
        refreshLock.lock()
        isRefreshing = false
        let waiters = refreshContinuations
        refreshContinuations.removeAll()
        refreshLock.unlock()
        waiters.forEach { $0.resume(returning: success) }
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
    
    func logout() {
        clearTokens()
        clearUserData()
        eventPublisher.send(.loginRequired)
    }
}

extension SessionManager: SessionManaging {}

struct LiveRefreshTokenService: RefreshTokenServicing {
    func refreshToken(accessToken: String, refreshToken: String) async throws -> SessionTokenData {
        try await APIClient.refreshSessionTokens(accessToken: accessToken, refreshToken: refreshToken)
    }
}
