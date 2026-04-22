import Foundation

@MainActor
final class SplashViewModel: ObservableObject {

    struct State: Equatable {
        var isActive = false
        var fcmToken: String = "Fetching..."
        var route: Route?
    }

    enum Action: Equatable {
        case onAppear
        case didReceiveFcmToken(String)
        case didReceivePushNotification(Any?)
    }

    enum Route: Equatable {
        case intro
    }

    @Published private(set) var state = State()

    private let deviceIdentifierStore: DeviceIdentifierStoring

    init(deviceIdentifierStore: DeviceIdentifierStoring) {
        self.deviceIdentifierStore = deviceIdentifierStore
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear: handleAppear()
        case .didReceiveFcmToken(let token): handleFcmToken(token)
        case .didReceivePushNotification: break
        }
    }

    private func mutate(_ update: (inout State) -> Void) {
        var next = state
        update(&next)
        state = next
    }

    private func handleAppear() {
        mutate {
            $0.fcmToken = deviceIdentifierStore.fcmToken ?? "No token available"
            $0.isActive = true
            $0.route = .intro
        }
    }

    private func handleFcmToken(_ token: String) {
        mutate { $0.fcmToken = token }
    }
}


