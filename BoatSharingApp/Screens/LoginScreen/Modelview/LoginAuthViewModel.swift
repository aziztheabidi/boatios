import SwiftUI

@MainActor
final class LoginAuthViewModel: ObservableObject {
    struct ValidationResult {
        let emailError: String?
        let passwordError: String?

        var isValid: Bool { emailError == nil && passwordError == nil }
    }

    struct State {
        var isAuthenticated: Bool
        var isLoading: Bool
        var errorMessage: String?
        var role: String
        var userId: String
        var missingStep: Int
        var emailError: String?
        var passwordError: String?
        var showValidationErrors: Bool
    }

    enum Action {
        case submitLogin(email: String, password: String)
        case login(email: String, password: String)
        case logout
        case updateFcmForAuthenticatedUser
    }

    enum Route {
        case authenticatedHome
        case login
    }

    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var role: String = ""
    @Published var userId: String = ""
    @Published var missingStep: Int = 1
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var showValidationErrors = false
    @Published var route: Route?

    var state: State {
        State(
            isAuthenticated: isAuthenticated,
            isLoading: isLoading,
            errorMessage: errorMessage,
            role: role,
            userId: userId,
            missingStep: missingStep,
            emailError: emailError,
            passwordError: passwordError,
            showValidationErrors: showValidationErrors
        )
    }

    private let apiClient: APIClientProtocol
    private let sessionManager: SessionManaging
    private let preferences: PreferenceStoring
    private let tokenStore: TokenStoring
    private let routingNotifier: AppRoutingNotifying

    init(
        apiClient: APIClientProtocol,
        sessionManager: SessionManaging,
        preferences: PreferenceStoring,
        tokenStore: TokenStoring,
        routingNotifier: AppRoutingNotifying
    ) {
        self.apiClient = apiClient
        self.sessionManager = sessionManager
        self.preferences = preferences
        self.tokenStore = tokenStore
        self.routingNotifier = routingNotifier
    }

    func send(_ action: Action) {
        switch action {
        case .submitLogin(let email, let password):
            performSubmitLogin(email: email, password: password)
        case .login(let email, let password):
            performLogin(email: email, password: password)
        case .logout:
            performLogout()
        case .updateFcmForAuthenticatedUser:
            performUpdateFcmForAuthenticatedUser()
        }
    }

    // MARK: - Legacy entry points (delegate to `send`; keeps tests and callers unchanged)

    func submitLogin(email: String, password: String) {
        send(.submitLogin(email: email, password: password))
    }

    func login(email: String, password: String) {
        send(.login(email: email, password: password))
    }

    func logout() {
        send(.logout)
    }

    // MARK: - Private

    private func performSubmitLogin(email: String, password: String) {
        showValidationErrors = true
        let validation = validate(email: email, password: password)
        emailError = validation.emailError
        passwordError = validation.passwordError
        guard validation.isValid else { return }
        performLogin(email: email, password: password)
    }

    private func validate(email: String, password: String) -> ValidationResult {
        let sanitizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailError: String?
        if sanitizedEmail.isEmpty {
            emailError = "Email cannot be empty"
        } else if !isValidEmail(sanitizedEmail) {
            emailError = "Invalid email format"
        } else {
            emailError = nil
        }

        let passwordError: String?
        if password.isEmpty {
            passwordError = "Password cannot be empty"
        } else if password.count < 8 {
            passwordError = "Password must be at least 8 characters"
        } else {
            passwordError = nil
        }

        return ValidationResult(emailError: emailError, passwordError: passwordError)
    }

    private func performLogin(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let parameters: Parameters = [
                    "Email": email,
                    "Password": password
                ]
                let response: BaseResponse<UserData> = try await apiClient.request(
                    endpoint: AppConfiguration.API.Endpoints.login,
                    method: .post,
                    parameters: parameters,
                    requiresAuth: false
                )
                let user = try APIResponseValidator.requireSuccess(response)

                sessionManager.saveTokens(
                    accessToken: user.accessToken ?? "",
                    refreshToken: user.refreshToken ?? ""
                )
                sessionManager.saveUserData(
                    userID: user.userId ?? "",
                    username: user.username ?? "",
                    email: user.email ?? "",
                    role: user.role ?? "",
                    missingStep: user.MissingStep
                )

                role = user.role ?? ""
                userId = user.userId ?? ""
                missingStep = user.MissingStep ?? 1
                isAuthenticated = true
                isLoading = false
                route = .authenticatedHome

                preferences.isLoggedIn = true
                preferences.userRole = role
                preferences.missingStep = missingStep
                routingNotifier.syncRoutingFromStorageIfNeeded()
            } catch {
                errorMessage = ErrorHandler.extractErrorMessage(from: error)
                isAuthenticated = false
                isLoading = false
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func performUpdateFcmToken(userId: String, token: String) {
        Task {
            do {
                let parameters: Parameters = [
                    "UserId": userId,
                    "DeviceToken": token
                ]
                let _: DeviceTokenResponse = try await apiClient.request(
                    endpoint: AppConfiguration.API.Endpoints.updateDeviceToken,
                    method: .post,
                    parameters: parameters,
                    requiresAuth: true
                )
            } catch {
            }
        }
    }

    private func performUpdateFcmForAuthenticatedUser() {
        let trimmedUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUserId.isEmpty else { return }
        let deviceToken = tokenStore.deviceToken ?? "DeviceToken"
        performUpdateFcmToken(userId: trimmedUserId, token: deviceToken)
    }

    private func performLogout() {
        sessionManager.logout()
        routingNotifier.syncRoutingFromStorageIfNeeded()
        isAuthenticated = false
        route = .login
    }
}
