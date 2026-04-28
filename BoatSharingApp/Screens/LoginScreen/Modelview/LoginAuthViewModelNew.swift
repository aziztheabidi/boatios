import SwiftUI
import Combine

@MainActor
final class LoginAuthViewModelNew: ObservableObject {

    // MARK: - State

    struct State {
        let isAuthenticated: Bool
        let isLoading: Bool
        let errorMessage: String?
        let userRole: String
        let userId: String
        let missingStep: Int
    }

    var state: State {
        State(
            isAuthenticated: isAuthenticated,
            isLoading: isLoading,
            errorMessage: errorMessage,
            userRole: userRole,
            userId: userId,
            missingStep: missingStep
        )
    }

    // MARK: - Actions

    enum Action {
        case login(email: String, password: String)
        case logout
        case updateDeviceToken(userId: String, token: String)
    }

    func send(_ action: Action) {
        switch action {
        case .login(let email, let password): performLogin(email: email, password: password)
        case .logout:                         performLogout()
        case .updateDeviceToken(let uid, let tok): performUpdateDeviceToken(userId: uid, token: tok)
        }
    }

    // MARK: - Published state

    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userRole: String = ""
    @Published var userId: String = ""
    @Published var missingStep: Int = 1

    // MARK: - Dependencies

    private let authRepository: AuthRepositoryProtocol
    private let sessionManager: SessionManaging
    private let tokenStore: TokenStoring
    private var cancellables = Set<AnyCancellable>()

    init(
        authRepository: AuthRepositoryProtocol,
        sessionManager: SessionManaging,
        tokenStore: TokenStoring
    ) {
        self.authRepository = authRepository
        self.sessionManager = sessionManager
        self.tokenStore = tokenStore

        sessionManager.eventPublisher
            .sink { [weak self] event in self?.handleSessionEvent(event) }
            .store(in: &cancellables)
    }

    // MARK: - Private

    private func performLogin(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let userData = try await authRepository.login(email: email, password: password)
                sessionManager.saveTokens(
                    accessToken: userData.Accesstoken ?? "",
                    refreshToken: userData.Refreshtoken ?? ""
                )
                sessionManager.saveUserData(
                    userID: userData.UserId ?? "",
                    username: userData.Username ?? "",
                    email: userData.Email ?? "",
                    role: userData.Role ?? "",
                    missingStep: userData.MissingStep
                )
                self.userId = userData.UserId ?? ""
                self.userRole = userData.Role ?? ""
                self.missingStep = userData.MissingStep ?? 1
                self.isAuthenticated = true
                self.isLoading = false
                if let deviceToken = tokenStore.deviceToken {
                    performUpdateDeviceToken(userId: self.userId, token: deviceToken)
                }
            } catch {
                self.errorMessage = ErrorHandler.extractErrorMessage(from: error)
                self.isLoading = false
                self.isAuthenticated = false
            }
        }
    }

    private func performLogout() {
        sessionManager.logout()
        isAuthenticated = false
        userRole = ""
        userId = ""
        missingStep = 1
    }

    private func performUpdateDeviceToken(userId: String, token: String) {
        Task {
            do {
                _ = try await authRepository.updateDeviceToken(userId: userId, token: token)
            } catch {
                // Background operation — suppress user-facing error
            }
        }
    }

    private func handleSessionEvent(_ event: SessionEvent) {
        switch event {
        case .sessionExpired, .loginRequired: isAuthenticated = false
        case .tokenRefreshed: break
        }
    }

    // MARK: - Public action helpers

    func login(email: String, password: String) { send(.login(email: email, password: password)) }
    func logout() { send(.logout) }
    func updateDeviceToken(userId: String, token: String) { send(.updateDeviceToken(userId: userId, token: token)) }
}

// MARK: - Response Models

struct LoginResponse: Codable {
    let Status: Int
    let Message: String
    let obj: LoginUserData?
}

struct LoginUserData: Codable {
    let UserId: String?
    let Username: String?
    let Email: String?
    let Role: String?
    let Accesstoken: String?
    let Refreshtoken: String?
    let MissingStep: Int?

    enum CodingKeys: String, CodingKey {
        case UserId, Username, Email, Role, Accesstoken, Refreshtoken, MissingStep
    }
}

