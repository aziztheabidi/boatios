import SwiftUI
import Combine

@MainActor
final class ResetPasswordViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let isLoading: Bool
        let isEmailSent: Bool
        let message: String
        let errorMessage: String?
    }

    var state: State {
        State(isLoading: isLoading, isEmailSent: isEmailSent, message: Message, errorMessage: errorMessage)
    }

    // MARK: - Actions

    enum Action {
        case forgotPassword(email: String)
        case clearError
    }

    func send(_ action: Action) {
        switch action {
        case .forgotPassword(let email): performForgotPassword(email: email)
        case .clearError:                errorMessage = nil
        }
    }

    // MARK: - Published state

    @Published var isLoading = false
    @Published var isEmailSent = false
    @Published var Message = ""
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    // MARK: - Private network

    private func performForgotPassword(email: String) {
        isLoading = true
        Task {
            do {
                let response: ResetPasswordModel = try await apiClient.request(
                    endpoint: "/Account/ForgotPassword",
                    method: .post,
                    parameters: ["Email": email],
                    requiresAuth: false
                )
                self.isLoading    = false
                self.isEmailSent  = true
                self.Message      = response.Message
                self.errorMessage = nil
            } catch {
                self.isLoading   = false
                self.isEmailSent = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Legacy call-site compat

    func forgotPassword(email: String) { send(.forgotPassword(email: email)) }
}
