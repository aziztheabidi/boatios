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
        Task { @MainActor [weak self] in
            self?.appState?.isLoggedIn = value
        }
    }

    private func runOnMain(_ block: @escaping () -> Void) {
        Task { @MainActor in
            block()
        }
    }
}

struct AppDependencies {
    /// Production: `APIClientWithRetry` wrapping a single `APIClient` (token attach, request, 401, refresh, retry).
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
    let authRepository: AuthRepositoryProtocol
    /// Feature networking surface (voyager/captain/business flows). ViewModels use this instead of `apiClient`.
    let networkRepository: AppNetworkRepositoryProtocol
    /// Non-secret device identifiers (FCM token etc) — NOT the Keychain.
    let deviceIdentifierStore: DeviceIdentifierStoring

    /// Single composition root: one Alamofire-backed client and one retry wrapper shared by all call sites.
    static let live: AppDependencies = {
        let graph = DependencyGraph.make()
        return AppDependencies(
            apiClient: graph.apiClient,
            sessionManager: graph.sessionManager,
            preferences: graph.preferencesStore,
            sessionPreferences: graph.preferencesStore,
            tokenStore: graph.tokenStore,
            dateFormatter: DateFormatterHelper(),
            routingNotifier: graph.routingNotifier,
            businessSaveMediaUploader: graph.businessSaveMediaUploader,
            businessRepository: graph.businessRepository,
            authRepository: graph.authRepository,
            networkRepository: graph.networkRepository,
            deviceIdentifierStore: graph.preferencesStore
        )
    }()
}

private struct DependencyGraph {
    let preferencesStore: PreferenceStore
    let tokenStore: TokenStore
    let sessionManager: SessionManager
    let routingNotifier: AppRoutingNotifier
    let apiClient: APIClientProtocol
    let businessSaveMediaUploader: BusinessSaveMediaUploading
    let businessRepository: BusinessRepositoryProtocol
    let authRepository: AuthRepositoryProtocol
    let networkRepository: AppNetworkRepositoryProtocol

    static func make() -> DependencyGraph {
        let preferencesStore = PreferenceStore()
        let keychainStore = KeychainManager()
        let tokenStore = TokenStore(keychain: keychainStore)
        let sessionManager = SessionManager(
            tokenStore: tokenStore,
            preferences: preferencesStore,
            refreshService: LiveRefreshTokenService()
        )
        let routingNotifier = AppRoutingNotifier()
        let baseHTTPClient = APIClient(sessionManager: sessionManager, routingNotifier: routingNotifier)
        let apiClient = APIClientWithRetry(baseClient: baseHTTPClient, sessionManager: sessionManager)
        let businessSaveMediaUploader = AlamofireBusinessSaveMediaUploader(tokenStore: tokenStore)

        return DependencyGraph(
            preferencesStore: preferencesStore,
            tokenStore: tokenStore,
            sessionManager: sessionManager,
            routingNotifier: routingNotifier,
            apiClient: apiClient,
            businessSaveMediaUploader: businessSaveMediaUploader,
            businessRepository: BusinessRepository(apiClient: apiClient),
            authRepository: AuthRepository(apiClient: apiClient, sessionManager: sessionManager),
            networkRepository: AppNetworkRepository(apiClient: apiClient)
        )
    }
}
