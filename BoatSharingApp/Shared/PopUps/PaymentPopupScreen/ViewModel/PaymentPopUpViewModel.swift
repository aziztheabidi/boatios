import Foundation

@MainActor
final class PaymentPopUpViewModel: ObservableObject {
    struct State: Equatable {
        var navigateToHome: Bool = false
    }

    enum Action: Equatable {
        case primaryTapped
    }

    @Published private(set) var state = State()

    private let type: TypeOfController

    init(type: TypeOfController) {
        self.type = type
    }

    var primaryButtonTitle: String {
        switch type {
        case .SponsorPayment: return "Go To Home"
        case .VoyagerPayment: return "Track Boat"
        }
    }

    var receiptLabel: String {
        "We have sent an email to %@ with the receipt of this voyage"
    }

    func send(_ action: Action) {
        switch action {
        case .primaryTapped:
            state.navigateToHome = true
        }
    }
}
