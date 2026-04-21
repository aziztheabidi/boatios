import Foundation

@MainActor
final class SpinWheelMenuViewModel: ObservableObject {
    struct State { let route: Route? }
    enum Action { case onAppear; case onDisappear }
    enum Route { case none }
    @Published var route: Route?
    var state: State { State(route: route) }
    func send(_ action: Action) {}
    private let sessionManager: SessionManaging

    init(sessionManager: SessionManaging) {
        self.sessionManager = sessionManager
    }

    func logout() {
        sessionManager.logout()
    }
}
