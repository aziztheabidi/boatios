import Foundation
import Combine

protocol TokenStoring: AnyObject {
    var accessToken: String? { get set }
    var refreshToken: String? { get set }
    /// APNS device token — used for push routing; stored in keychain since AppDelegate writes it before preferences load.
    var deviceToken: String? { get set }
    func clearSessionTokens()
}

/// Non-secret device identifiers that do not belong in the Keychain.
protocol DeviceIdentifierStoring: AnyObject {
    /// FCM registration token (public push identifier — NOT a secret).
    var fcmToken: String? { get set }
}

protocol SessionManaging: AnyObject {
    var accessToken: String? { get }
    var refreshToken: String? { get }
    var eventPublisher: PassthroughSubject<SessionEvent, Never> { get }
    func saveTokens(accessToken: String, refreshToken: String)
    func saveUserData(userID: String, username: String, email: String, role: String, missingStep: Int?)
    func clearTokens()
    func clearUserData()
    func refreshToken() async -> Bool
    func hasValidSession() -> Bool
    func logout()
}

protocol PreferenceStoring: AnyObject {
    var isLoggedIn: Bool { get set }
    var userRole: String { get set }
    var missingStep: Int { get set }
}

/// Session-facing user preferences (identity, role, onboarding step). Implemented by `PreferenceStore`.
protocol SessionPreferenceStoring: AnyObject {
    var isLoggedIn: Bool { get set }
    var userRole: String { get set }
    var missingStep: Int { get set }
    var userID: String { get set }
    var username: String { get set }
    var userEmail: String { get set }
    func clearSessionPreferences()
}

/// Performs refresh-token HTTP using the same contract as `SessionManager` / `LiveRefreshTokenService`.
protocol RefreshTokenServicing {
    func refreshToken(accessToken: String, refreshToken: String) async throws -> SessionTokenData
}
