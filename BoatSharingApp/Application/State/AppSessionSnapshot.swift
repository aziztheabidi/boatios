import Foundation

/// Read-only view of the active session for call sites that are not yet fully dependency-injected.
/// Configure once at app launch via `configure(_:)` (see `BoatSharingAppApp`).
enum AppSessionSnapshot {
    private static var sessionPreferences: SessionPreferenceStoring?

    static func configure(_ store: SessionPreferenceStoring) {
        sessionPreferences = store
    }

    static var userID: String {
        guard let sessionPreferences else { return "" }
        return sessionPreferences.userID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var username: String {
        guard let sessionPreferences else { return "" }
        return sessionPreferences.username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var userEmail: String {
        guard let sessionPreferences else { return "" }
        return sessionPreferences.userEmail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var userRole: String {
        sessionPreferences?.userRole ?? ""
    }
}
