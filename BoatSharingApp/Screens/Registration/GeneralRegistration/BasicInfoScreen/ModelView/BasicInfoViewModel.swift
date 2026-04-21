import SwiftUI

@MainActor
final class BasicInfoViewModel: ObservableObject {

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    @Published var message: String = ""
    @Published var isSuccess: Bool = false
    @Published var isLoading: Bool = false
    @Published var shouldNavigate: Bool = false

    func registerUser(name: String, email: String, phone: String) {
        isLoading = true
        let parameters: [String: Any] = [
            "Username": name,
            "Email": email,
            "PhoneNumber": phone
        ]
        Task {
            do {
                let response: BasicInfoModel = try await apiClient.request(
                    endpoint: "/RegistrationTemp/Add",
                    method: .post,
                    parameters: parameters,
                    requiresAuth: false
                )
                self.isLoading = false
                self.message = response.Message
                self.isSuccess = response.Status == 200
                if self.isSuccess {
                    self.shouldNavigate = true
                }
            } catch {
                self.isLoading = false
                let errorMsg = error.localizedDescription
                if errorMsg.lowercased().contains("session") ||
                   errorMsg.lowercased().contains("expire") ||
                   errorMsg.lowercased().contains("unauthorized") {
                    self.message = "Unable to register. Please try again."
                } else {
                    self.message = errorMsg
                }
                self.isSuccess = false
            }
        }
    }
}
