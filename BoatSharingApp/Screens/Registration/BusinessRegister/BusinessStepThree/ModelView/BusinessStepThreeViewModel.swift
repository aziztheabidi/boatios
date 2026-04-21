import SwiftUI

@MainActor
final class BusinessStepThreeViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let isLoading: Bool
        let isSuccess: Bool
        let message: String
        let shouldNavigate: Bool
    }

    var state: State {
        State(isLoading: isLoading, isSuccess: isSuccess, message: message, shouldNavigate: shouldNavigate)
    }

    // MARK: - Actions

    enum Action {
        case saveBusiness(description: String, isDock: Bool, userId: String)
    }

    func send(_ action: Action) {
        switch action {
        case .saveBusiness(let desc, let dock, let uid):
            performSaveBusiness(description: desc, isDock: dock, userId: uid)
        }
    }

    // MARK: - Published state

    @Published var message: String = ""
    @Published var isSuccess: Bool = false
    @Published var isLoading: Bool = false
    @Published var shouldNavigate: Bool = false

    // MARK: - Dependencies

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    // MARK: - Private network

    private func performSaveBusiness(description: String, isDock: Bool, userId: String) {
        isLoading = true
        let parameters: [String: Any] = [
            "Description": description,
            "IsDock": isDock,
            "UserId": userId
        ]
        Task {
            do {
                let response: BusinessStepThreeModel = try await apiClient.request(
                    endpoint: "/BusinessInfo/SaveAbout", method: .post,
                    parameters: parameters, requiresAuth: true
                )
                self.isLoading      = false
                self.message        = response.Message
                self.isSuccess      = response.Status == 200
                self.shouldNavigate = self.isSuccess
            } catch {
                self.isLoading = false
                self.message   = error.localizedDescription
                self.isSuccess = false
            }
        }
    }

}
