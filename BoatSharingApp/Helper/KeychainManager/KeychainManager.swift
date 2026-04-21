import Security
import Foundation

protocol KeychainStoring {
    func saveSecureValue(_ value: String, for key: String) -> Bool
    func retrieveSecureValue(for key: String) -> String?
    func deleteSecureValue(for key: String) -> Bool
}

final class KeychainManager: KeychainStoring {
    private let service = "com.boatit.boatitt"

    private let allowedSecureKeys: Set<String> = [
        AppConfiguration.KeychainKeys.accessToken,
        AppConfiguration.KeychainKeys.refreshToken,
        AppConfiguration.KeychainKeys.deviceToken,
        AppConfiguration.KeychainKeys.fcmToken
    ]

    func saveSecureValue(_ value: String, for key: String) -> Bool {
        guard allowedSecureKeys.contains(key) else {
            assertionFailure("Attempted to save non-secure key in KeychainManager: \(key)")
            return false
        }
        return saveSecure(key: key, value: value)
    }

    func retrieveSecureValue(for key: String) -> String? {
        guard allowedSecureKeys.contains(key) else {
            assertionFailure("Attempted to retrieve non-secure key from KeychainManager: \(key)")
            return nil
        }
        return retrieveSecure(key: key)
    }

    func deleteSecureValue(for key: String) -> Bool {
        guard allowedSecureKeys.contains(key) else {
            assertionFailure("Attempted to delete non-secure key in KeychainManager: \(key)")
            return false
        }
        return deleteSecure(key: key)
    }

    private func saveSecure(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary) // Delete existing item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func retrieveSecure(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    private func deleteSecure(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}
