import SwiftUI
import Combine

@MainActor
final class LoginAuthViewModel: ObservableObject {
    struct ValidationResult {
        let emailError: String?
        let passwordError: String?

        var isValid: Bool { emailError == nil && passwordError == nil }
    }

    struct State: Equatable {
        var isAuthenticated: Bool
        var isLoading: Bool
        var errorMessage: String?
        var role: String
        var userId: String
        var missingStep: Int
        var emailError: String?
        var passwordError: String?
        var showValidationErrors: Bool
        var route: Route?
    }

    enum Action: Equatable {
        case submitLogin(email: String, password: String)
        case login(email: String, password: String)
        case logout
        case updateFcmForAuthenticatedUser
    }

    enum Route: Equatable {
        case authenticatedHome
        case login
    }

    @Published private(set) var state: State

    private let authRepository: AuthRepositoryProtocol
    private let sessionManager: SessionManaging
    private let preferences: PreferenceStoring
    private let tokenStore: TokenStoring
    private let routingNotifier: AppRoutingNotifying

    init(
        authRepository: AuthRepositoryProtocol,
        sessionManager: SessionManaging,
        preferences: PreferenceStoring,
        tokenStore: TokenStoring,
        routingNotifier: AppRoutingNotifying
    ) {
        self.authRepository = authRepository
        self.sessionManager = sessionManager
        self.preferences = preferences
        self.tokenStore = tokenStore
        self.routingNotifier = routingNotifier
        self.state = State(
            isAuthenticated: false,
            isLoading: false,
            errorMessage: nil,
            role: "",
            userId: "",
            missingStep: 1,
            emailError: nil,
            passwordError: nil,
            showValidationErrors: false,
            route: nil
        )
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

    func submitLogin(email: String, password: String) { send(.submitLogin(email: email, password: password)) }
    func login(email: String, password: String) { send(.login(email: email, password: password)) }
    func logout() { send(.logout) }

    private func mutate(_ update: (inout State) -> Void) {
        var next = state
        update(&next)
        state = next
    }

    private func performSubmitLogin(email: String, password: String) {
        mutate {
            $0.showValidationErrors = true
        }
        let validation = validate(email: email, password: password)
        mutate {
            $0.emailError = validation.emailError
            $0.passwordError = validation.passwordError
        }
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
        mutate {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        Task { @MainActor in
            do {
                let user = try await authRepository.loginDecodedUserData(email: email, password: password)

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

                let role = user.role ?? ""
                let userId = user.userId ?? ""
                let missing = user.MissingStep ?? 1

                preferences.isLoggedIn = true
                preferences.userRole = role
                preferences.missingStep = missing
                routingNotifier.syncRoutingFromStorageIfNeeded()

                mutate {
                    $0.role = role
                    $0.userId = userId
                    $0.missingStep = missing
                    $0.isAuthenticated = true
                    $0.isLoading = false
                    $0.route = .authenticatedHome
                }
            } catch {
                mutate {
                    $0.errorMessage = ErrorHandler.extractErrorMessage(from: error)
                    $0.isAuthenticated = false
                    $0.isLoading = false
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func performUpdateFcmToken(userId: String, token: String) {
        Task { @MainActor in
            do {
                _ = try await authRepository.updateDeviceToken(userId: userId, token: token)
            } catch {
            }
        }
    }

    private func performUpdateFcmForAuthenticatedUser() {
        let trimmedUserId = state.userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUserId.isEmpty else { return }
        let deviceToken = tokenStore.deviceToken ?? "DeviceToken"
        performUpdateFcmToken(userId: trimmedUserId, token: deviceToken)
    }

    private func performLogout() {
        sessionManager.logout()
        routingNotifier.syncRoutingFromStorageIfNeeded()
        mutate {
            $0.isAuthenticated = false
            $0.route = .login
        }
    }
}

