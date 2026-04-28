import Foundation

@MainActor
final class SpinWheelMenuViewModel: ObservableObject {

    struct State: Equatable {
        var route: Route?
    }

    enum Action: Equatable {
        case onAppear
        case onDisappear
        case logout
    }

    enum Route: Equatable {
        case none
    }

    @Published private(set) var state = State()

    private let sessionManager: SessionManaging

    init(sessionManager: SessionManaging) {
        self.sessionManager = sessionManager
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear, .onDisappear:
            break
        case .logout:
            sessionManager.logout()
        }
    }

    func logout() {
        send(.logout)
    }
}

