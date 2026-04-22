import SwiftUI
import Combine

@MainActor
final class CreatePasswordViewModel: ObservableObject {

    private let tokenStore: TokenStoring
    private let networkRepository: AppNetworkRepositoryProtocol
    private let sessionPreferences: SessionPreferenceStoring

    init(
        tokenStore: TokenStoring,
        networkRepository: AppNetworkRepositoryProtocol,
        sessionPreferences: SessionPreferenceStoring
    ) {
        self.tokenStore = tokenStore
        self.networkRepository = networkRepository
        self.sessionPreferences = sessionPreferences
    }

    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var message: String = ""
    @Published var isLoading: Bool = false

    func createUser(password: String) {
        let token = tokenStore.accessToken ?? ""
        let parameters: [String: Any] = ["Password": password, "Token": token]
        isLoading = true
        Task {
            do {
                let userdata = try await networkRepository.account_register(parameters: parameters)
                self.isLoading = false
                self.isAuthenticated = true
                self.message = userdata.message
                if let obj = userdata.obj {
                    self.saveUserData(obj)
                }
            } catch {
                self.isLoading = false
                self.errorMessage = self.mapRegistrationError(error)
            }
        }
    }

    private func saveUserData(_ userData: RegisterUserData) {
        tokenStore.accessToken = userData.accessToken ?? ""
        tokenStore.refreshToken = userData.refreshToken ?? ""
        sessionPreferences.username = userData.username ?? ""
        sessionPreferences.userEmail = userData.email ?? ""
        sessionPreferences.userID = userData.userId ?? ""
        sessionPreferences.userRole = userData.role ?? ""
        sessionPreferences.missingStep = userData.MissingStep ?? 1
        sessionPreferences.isLoggedIn = true
    }

    private func mapRegistrationError(_ error: Error) -> String {
        let description = error.localizedDescription
        if description.lowercased().contains("session") ||
           description.lowercased().contains("expire") ||
           description.lowercased().contains("unauthorized") {
            return "Unable to create account. Please try again."
        }
        return description
    }
}

