import Foundation

/// Keychain-backed storage for **secrets only** (access token, refresh token, APNS device token per `TokenStoring`).
/// FCM and other non-secret identifiers use `PreferenceStore` / `DeviceIdentifierStoring`.
final class TokenStore: TokenStoring {
    private let keychain: KeychainStoring

    init(keychain: KeychainStoring) {
        self.keychain = keychain
    }

    var accessToken: String? {
        get { keychain.retrieveSecureValue(for: AppConfiguration.KeychainKeys.accessToken) }
        set {
            if let newValue {
                _ = keychain.saveSecureValue(newValue, for: AppConfiguration.KeychainKeys.accessToken)
            } else {
                _ = keychain.deleteSecureValue(for: AppConfiguration.KeychainKeys.accessToken)
            }
        }
    }

    var refreshToken: String? {
        get { keychain.retrieveSecureValue(for: AppConfiguration.KeychainKeys.refreshToken) }
        set {
            if let newValue {
                _ = keychain.saveSecureValue(newValue, for: AppConfiguration.KeychainKeys.refreshToken)
            } else {
                _ = keychain.deleteSecureValue(for: AppConfiguration.KeychainKeys.refreshToken)
            }
        }
    }

    var deviceToken: String? {
        get { keychain.retrieveSecureValue(for: AppConfiguration.KeychainKeys.deviceToken) }
        set {
            if let newValue {
                _ = keychain.saveSecureValue(newValue, for: AppConfiguration.KeychainKeys.deviceToken)
            } else {
                _ = keychain.deleteSecureValue(for: AppConfiguration.KeychainKeys.deviceToken)
            }
        }
    }

    func clearSessionTokens() {
        accessToken = nil
        refreshToken = nil
    }
}
