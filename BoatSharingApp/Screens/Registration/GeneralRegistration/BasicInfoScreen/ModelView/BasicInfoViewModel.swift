import SwiftUI
import Combine

@MainActor
final class BasicInfoViewModel: ObservableObject {

    struct State: Equatable {
        var message: String = ""
        var isSuccess: Bool = false
        var isLoading: Bool = false
        var shouldNavigate: Bool = false
    }

    enum Action: Equatable {
        case register(name: String, email: String, phone: String)
        case resetNavigation
    }

    @Published private(set) var state = State()

    private let networkRepository: AppNetworkRepositoryProtocol

    init(networkRepository: AppNetworkRepositoryProtocol) {
        self.networkRepository = networkRepository
    }

    func send(_ action: Action) {
        switch action {
        case .register(let name, let email, let phone):
            performRegister(name: name, email: email, phone: phone)
        case .resetNavigation:
            mutate { $0.shouldNavigate = false }
        }
    }

    func registerUser(name: String, email: String, phone: String) {
        send(.register(name: name, email: email, phone: phone))
    }

    private func mutate(_ update: (inout State) -> Void) {
        var next = state
        update(&next)
        state = next
    }

    private func performRegister(name: String, email: String, phone: String) {
        mutate { $0.isLoading = true }
        let parameters: [String: Any] = [
            "Username": name,
            "Email": email,
            "PhoneNumber": phone
        ]
        Task { @MainActor in
            do {
                let response = try await networkRepository.registrationTemp_add(parameters: parameters)
                mutate {
                    $0.isLoading = false
                    $0.message = response.Message
                    $0.isSuccess = response.Status == 200
                    if response.Status == 200 { $0.shouldNavigate = true }
                }
            } catch {
                let errorMsg = error.localizedDescription
                let mapped: String
                if errorMsg.lowercased().contains("session") ||
                   errorMsg.lowercased().contains("expire") ||
                   errorMsg.lowercased().contains("unauthorized") {
                    mapped = "Unable to register. Please try again."
                } else {
                    mapped = errorMsg
                }
                mutate {
                    $0.isLoading = false
                    $0.message = mapped
                    $0.isSuccess = false
                }
            }
        }
    }
}

