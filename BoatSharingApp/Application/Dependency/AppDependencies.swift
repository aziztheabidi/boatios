import Foundation

/// Weak bridge so auth failures can refresh SwiftUI routing without coupling `APIClient` to `AppState`.
protocol RoutableAppState: AnyObject {
    func syncFromStorage()
    var isLoggedIn: Bool { get set }
}

protocol AppRoutingNotifying: AnyObject {
    func bind(_ state: RoutableAppState?)
    func syncRoutingFromStorageIfNeeded()
    func setRoutingIsLoggedIn(_ value: Bool)
}

/// Test doubles and `APIClientProtocol` defaults use this instead of a global singleton.
final class NoOpAppRoutingNotifier: AppRoutingNotifying {
    func bind(_ state: RoutableAppState?) {}
    func syncRoutingFromStorageIfNeeded() {}
    func setRoutingIsLoggedIn(_ value: Bool) {}
}

final class AppRoutingNotifier: AppRoutingNotifying {
    private weak var appState: RoutableAppState?

    func bind(_ state: RoutableAppState?) {
        appState = state
    }

    func syncRoutingFromStorageIfNeeded() {
        runOnMain { [weak self] in
            self?.appState?.syncFromStorage()
        }
    }

    func setRoutingIsLoggedIn(_ value: Bool) {
        runOnMain { [weak self] in
            self?.appState?.isLoggedIn = value
        }
    }

    private func runOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}

struct AppDependencies {
    /// Production: `APIClientWithRetry` wrapping a single `APIClient` (token attach → request → 401 → refresh → retry).
    let apiClient: APIClientProtocol
    let sessionManager: SessionManaging
    let preferences: PreferenceStoring
    /// User id, username, email, role, etc. (same concrete store as `preferences` in `.live`.)
    let sessionPreferences: SessionPreferenceStoring
    let tokenStore: TokenStoring
    let dateFormatter: DateFormatting
    let routingNotifier: AppRoutingNotifier
    let businessSaveMediaUploader: BusinessSaveMediaUploading
    let businessRepository: BusinessRepositoryProtocol
    /// Non-secret device identifiers (FCM token etc) — NOT the Keychain.
    let deviceIdentifierStore: DeviceIdentifierStoring

    /// Single composition root: one Alamofire-backed client and one retry wrapper shared by all call sites.
    static let live: AppDependencies = {
        let preferencesStore = PreferenceStore()
        let keychainStore = KeychainManager()
        let tokenStore = TokenStore(keychain: keychainStore)
        let sessionManager = SessionManager(
            tokenStore: tokenStore,
            preferences: preferencesStore,
            refreshService: LiveRefreshTokenService()
        )
        let routingNotifier = AppRoutingNotifier()
        let businessSaveMediaUploader = AlamofireBusinessSaveMediaUploader(tokenStore: tokenStore)
        let baseHTTPClient = APIClient(sessionManager: sessionManager, routingNotifier: routingNotifier)
        let apiClient = APIClientWithRetry(baseClient: baseHTTPClient, sessionManager: sessionManager)
        let businessRepository = BusinessRepository(apiClient: apiClient)
        return AppDependencies(
            apiClient: apiClient,
            sessionManager: sessionManager,
            preferences: preferencesStore,
            sessionPreferences: preferencesStore,
            tokenStore: tokenStore,
            dateFormatter: DateFormatterHelper(),
            routingNotifier: routingNotifier,
            businessSaveMediaUploader: businessSaveMediaUploader,
            businessRepository: businessRepository,
            deviceIdentifierStore: preferencesStore
        )
    }()
}
