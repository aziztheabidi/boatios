import SwiftUI
import Combine

final class TrackRideKeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map(\.height)
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.height = $0 }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.height = 0 }
            .store(in: &cancellables)
    }
}
