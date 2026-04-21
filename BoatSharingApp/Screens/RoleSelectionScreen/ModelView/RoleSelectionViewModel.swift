import SwiftUI

@MainActor
final class RoleSelectionViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let isAuthenticated: Bool
        let isLoading: Bool
        let errorMessage: String?
        let selectedRole: String?
    }

    var state: State {
        State(
            isAuthenticated: isAuthenticated,
            isLoading: isLoading,
            errorMessage: errorMessage,
            selectedRole: selectedRole
        )
    }

    // MARK: - Actions

    enum Action {
        case selectRole(String)
        case updateRole(userId: String, role: String)
        case clearError
    }

    func send(_ action: Action) {
        switch action {
        case .selectRole(let role):              selectedRole = role
        case .updateRole(let uid, let role):     performUpdateRole(userId: uid, role: role)
        case .clearError:                        errorMessage = nil
        }
    }

    // MARK: - Published state

    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedRole: String?

    // MARK: - Dependencies

    private let sessionManager: SessionManaging
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol, sessionManager: SessionManaging) {
        self.apiClient = apiClient
        self.sessionManager = sessionManager
    }

    // MARK: - Private network

    private func performUpdateRole(userId: String, role: String) {
        isAuthenticated = false
        errorMessage = nil
        selectedRole = role

        guard let token = sessionManager.accessToken, !token.isEmpty else {
            errorMessage = "Authentication token missing. Please try again."
            return
        }
        isLoading = true
        let parameters: [String: Any] = ["UserId": userId, "Role": role, "Token": token]
        Task {
            do {
                let response: RoleSectionModel = try await apiClient.request(
                    endpoint: "/Account/UpdateRole",
                    method: .post,
                    parameters: parameters,
                    requiresAuth: true
                )
                self.isLoading = false
                if response.Status == 200, let roleData = response.obj {
                    self.isAuthenticated = true
                    // Route token storage through SessionManager so refresh machinery stays in sync
                    self.sessionManager.saveTokens(
                        accessToken: roleData.accessToken ?? "",
                        refreshToken: roleData.refreshToken ?? ""
                    )
                } else {
                    self.isAuthenticated = false
                    self.errorMessage = response.Message.isEmpty ? "Invalid response from server" : response.Message
                }
            } catch {
                self.isLoading = false
                self.isAuthenticated = false
                self.errorMessage = mapRoleError(error)
            }
        }
    }

    private func mapRoleError(_ error: Error) -> String {
        let description = error.localizedDescription
        if description.lowercased().contains("session") ||
           description.lowercased().contains("expire") ||
           description.lowercased().contains("unauthorized") {
            return "Unable to update role. Please try again."
        }
        if description.lowercased().contains("cancelled") {
            return "Request cancelled. Please try again."
        }
        return description
    }

    // MARK: - Legacy call-site compat

    func updateRole(userId: String, role: String) { send(.updateRole(userId: userId, role: role)) }
}
