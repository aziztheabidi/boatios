import SwiftUI
import Combine

@MainActor
final class RoleSelectionViewModel: ObservableObject {

    struct State: Equatable {
        var isAuthenticated: Bool = false
        var isLoading: Bool = false
        var errorMessage: String?
        var selectedRole: String?
    }

    enum Action: Equatable {
        case selectRole(String)
        case updateRole(userId: String, role: String)
        case clearError
    }

    @Published private(set) var state = State()

    private let sessionManager: SessionManaging
    private let networkRepository: AppNetworkRepositoryProtocol
    private let sessionPreferences: SessionPreferenceStoring

    init(networkRepository: AppNetworkRepositoryProtocol, sessionManager: SessionManaging, sessionPreferences: SessionPreferenceStoring) {
        self.networkRepository = networkRepository
        self.sessionManager = sessionManager
        self.sessionPreferences = sessionPreferences
    }

    var roleSelectionUserId: String {
        sessionPreferences.userID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func send(_ action: Action) {
        switch action {
        case .selectRole(let role):
            mutate { $0.selectedRole = role }
        case .updateRole(let uid, let role):
            performUpdateRole(userId: uid, role: role)
        case .clearError:
            mutate { $0.errorMessage = nil }
        }
    }

    func updateRole(userId: String, role: String) { send(.updateRole(userId: userId, role: role)) }

    private func mutate(_ update: (inout State) -> Void) {
        var next = state
        update(&next)
        state = next
    }

    private func performUpdateRole(userId: String, role: String) {
        mutate {
            $0.isAuthenticated = false
            $0.errorMessage = nil
            $0.selectedRole = role
        }

        guard let token = sessionManager.accessToken, !token.isEmpty else {
            mutate { $0.errorMessage = "Authentication token missing. Please try again." }
            return
        }
        mutate { $0.isLoading = true }
        let parameters: [String: Any] = ["UserId": userId, "Role": role, "Token": token]
        Task { @MainActor in
            do {
                let response = try await networkRepository.account_updateRole(parameters: parameters)
                mutate { $0.isLoading = false }
                if response.Status == 200, let roleData = response.obj {
                    mutate { $0.isAuthenticated = true }
                    sessionManager.saveTokens(
                        accessToken: roleData.accessToken ?? "",
                        refreshToken: roleData.refreshToken ?? ""
                    )
                } else {
                    mutate {
                        $0.isAuthenticated = false
                        $0.errorMessage = response.Message.isEmpty ? "Invalid response from server" : response.Message
                    }
                }
            } catch {
                mutate {
                    $0.isLoading = false
                    $0.isAuthenticated = false
                    $0.errorMessage = mapRoleError(error)
                }
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
}

