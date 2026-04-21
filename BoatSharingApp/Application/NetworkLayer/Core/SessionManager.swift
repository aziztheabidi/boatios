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
    private let refreshStateQueue = DispatchQueue(label: "com.boatit.session.refresh-state")
    
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
        // If already refreshing, wait for the result.
        let currentlyRefreshing = refreshStateQueue.sync { isRefreshing }
        if currentlyRefreshing {
            return await withCheckedContinuation { continuation in
                refreshStateQueue.sync {
                    refreshContinuations.append(continuation)
                }
            }
        }

        refreshStateQueue.sync {
            isRefreshing = true
        }
        
        guard let accessToken = self.accessToken,
              let refreshToken = self.refreshToken else {
            expireSessionForRefreshFailure()
            completeRefresh(success: false)
            return false
        }
        
        return await withCheckedContinuation { continuation in
            Task {
                do {
                    let refreshed = try await self.refreshService.refreshToken(
                        accessToken: accessToken,
                        refreshToken: refreshToken
                    )
                    self.saveTokens(
                        accessToken: refreshed.Accesstoken,
                        refreshToken: refreshed.Refreshtoken
                    )
                    self.eventPublisher.send(.tokenRefreshed)
                    self.completeRefresh(success: true)
                    continuation.resume(returning: true)
                } catch {
                    self.expireSessionForRefreshFailure()
                    self.completeRefresh(success: false)
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private func completeRefresh(success: Bool) {
        refreshStateQueue.sync {
            isRefreshing = false
            refreshContinuations.forEach { $0.resume(returning: success) }
            refreshContinuations.removeAll()
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
