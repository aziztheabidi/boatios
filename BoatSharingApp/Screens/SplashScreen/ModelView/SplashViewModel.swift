import Foundation

@MainActor
final class SplashViewModel: ObservableObject {
    struct State {
        var isActive = false
        var fcmToken: String = "Fetching..."
    }

    enum Action {
        case onAppear
        case didReceiveFcmToken(String)
        case didReceivePushNotification(Any?)
    }

    enum Route {
        case intro
    }

    @Published private(set) var state = State()
    @Published var route: Route?

    /// FCM token is now in DeviceIdentifierStoring (PreferenceStore), not TokenStore.
    private let deviceIdentifierStore: DeviceIdentifierStoring

    init(deviceIdentifierStore: DeviceIdentifierStoring = AppDependencies.live.deviceIdentifierStore) {
        self.deviceIdentifierStore = deviceIdentifierStore
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:               handleAppear()
        case .didReceiveFcmToken(let token):  handleFcmToken(token)
        case .didReceivePushNotification:     break // no-op – payload not used
        }
    }

    private func handleAppear() {
        state.fcmToken = deviceIdentifierStore.fcmToken ?? "No token available"
        state.isActive = true
        route = .intro
    }

    private func handleFcmToken(_ token: String) {
        state.fcmToken = token
    }
}
