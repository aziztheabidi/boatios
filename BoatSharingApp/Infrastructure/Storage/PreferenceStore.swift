import Foundation

/// Persisted **non-secret** app state (UserDefaults).
///
/// Boundaries:
/// - **Access / refresh tokens** live in `TokenStore` / Keychain only — never here.
/// - **Session identity fields** (`userID`, `userEmail`, `username`, role, onboarding step) are persisted for
///   launch routing and API identity; they are cleared by `clearSessionPreferences()` on logout / session expiry.
///   Transient booking / popup UI belongs in view models and `UIFlowState`, not re-derived from these keys.
/// - **FCM registration token** is a public push identifier (`DeviceIdentifierStoring`), not a Keychain secret.
final class PreferenceStore: SessionPreferenceStoring, PreferenceStoring, DeviceIdentifierStoring {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isLoggedIn: Bool {
        get { defaults.bool(forKey: AppConfiguration.PreferenceKeys.isLoggedIn) }
        set { defaults.set(newValue, forKey: AppConfiguration.PreferenceKeys.isLoggedIn) }
    }

    var userRole: String {
        get {
            let raw = defaults.string(forKey: AppConfiguration.PreferenceKeys.userRole) ?? ""
            return AppConfiguration.UserRole.normalize(raw)
        }
        set {
            defaults.set(
                AppConfiguration.UserRole.normalize(newValue),
                forKey: AppConfiguration.PreferenceKeys.userRole
            )
        }
    }

    var missingStep: Int {
        get {
            let value = defaults.integer(forKey: AppConfiguration.PreferenceKeys.missingStep)
            return value == 0 ? 1 : value
        }
        set { defaults.set(newValue, forKey: AppConfiguration.PreferenceKeys.missingStep) }
    }

    var userID: String {
        get { defaults.string(forKey: AppConfiguration.PreferenceKeys.userID) ?? "" }
        set { defaults.set(newValue, forKey: AppConfiguration.PreferenceKeys.userID) }
    }

    var username: String {
        get { defaults.string(forKey: AppConfiguration.PreferenceKeys.username) ?? "" }
        set { defaults.set(newValue, forKey: AppConfiguration.PreferenceKeys.username) }
    }

    var userEmail: String {
        get { defaults.string(forKey: AppConfiguration.PreferenceKeys.userEmail) ?? "" }
        set { defaults.set(newValue, forKey: AppConfiguration.PreferenceKeys.userEmail) }
    }

    var captainStatus: Bool {
        get { defaults.bool(forKey: AppConfiguration.PreferenceKeys.captainStatus) }
        set { defaults.set(newValue, forKey: AppConfiguration.PreferenceKeys.captainStatus) }
    }

    /// FCM token is a public device identifier (not a secret) — stored in UserDefaults, not Keychain.
    var fcmToken: String? {
        get { defaults.string(forKey: "fcmRegistrationToken") }
        set { defaults.set(newValue, forKey: "fcmRegistrationToken") }
    }

    func clearSessionPreferences() {
        defaults.removeObject(forKey: AppConfiguration.PreferenceKeys.userID)
        defaults.removeObject(forKey: AppConfiguration.PreferenceKeys.username)
        defaults.removeObject(forKey: AppConfiguration.PreferenceKeys.userEmail)
        defaults.removeObject(forKey: AppConfiguration.PreferenceKeys.userRole)
        defaults.removeObject(forKey: AppConfiguration.PreferenceKeys.missingStep)
        defaults.set(false, forKey: AppConfiguration.PreferenceKeys.isLoggedIn)
        defaults.set(false, forKey: AppConfiguration.PreferenceKeys.captainStatus)
    }
}
