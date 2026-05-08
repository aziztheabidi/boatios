import Foundation

/// Repository for authentication-related operations.
/// Networking: `apiClient.request` only (in production the shared `APIClientWithRetry` to base `APIClient` path).
/// Encoding is derived automatically inside APIClient from the HTTP method - no Alamofire encoding types here.
protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws -> LoginUserData
    /// Same login endpoint as `login`, decoded as `BaseResponse<UserData>` for existing `LoginAuthViewModel` flows.
    func loginDecodedUserData(email: String, password: String) async throws -> UserData
    func register(userData: RegistrationData) async throws -> RegistrationResult
    func forgotPassword(email: String) async throws -> Bool
    func resetPassword(email: String, otp: String, newPassword: String) async throws -> Bool
    func updateDeviceToken(userId: String, token: String) async throws -> Bool
}

final class AuthRepository: AuthRepositoryProtocol {

    private let apiClient: APIClientProtocol
    private let sessionManager: SessionManaging

    init(apiClient: APIClientProtocol, sessionManager: SessionManaging) {
        self.apiClient = apiClient
        self.sessionManager = sessionManager
    }

    func login(email: String, password: String) async throws -> LoginUserData {
        let response: LoginResponse = try await requestAuth(
            endpoint: AppConfiguration.API.Endpoints.login,
            parameters: loginParameters(email: email, password: password),
            requiresAuth: false
        )

        guard response.Status == 200 else {
            throw APIError.serverError(
                statusCode: response.Status,
                message: response.Message.isEmpty ? "Login failed" : response.Message
            )
        }
        guard let userData = response.obj else { throw APIError.invalidResponse }

        persistSession(from: userData)
        return userData
    }

    func loginDecodedUserData(email: String, password: String) async throws -> UserData {
        let response: BaseResponse<UserData> = try await requestAuth(
            endpoint: AppConfiguration.API.Endpoints.login,
            parameters: loginParameters(email: email, password: password),
            requiresAuth: false
        )
        return try APIResponseValidator.requireSuccess(response)
    }

    func register(userData: RegistrationData) async throws -> RegistrationResult {
        let response: BaseResponse<RegistrationResult> = try await requestAuth(
            endpoint: AppConfiguration.API.Endpoints.register,
            parameters: userData.toDictionary(),
            requiresAuth: false
        )
        guard response.isSuccess, let result = response.obj else {
            throw APIError.serverError(statusCode: response.Status, message: response.Message)
        }
        return result
    }

    func forgotPassword(email: String) async throws -> Bool {
        let response: EmptyResponse = try await requestAuth(
            endpoint: AppConfiguration.API.Endpoints.forgotPassword,
            parameters: ["Email": email],
            requiresAuth: false
        )
        return response.isSuccess
    }

    func resetPassword(email: String, otp: String, newPassword: String) async throws -> Bool {
        let response: EmptyResponse = try await requestAuth(
            endpoint: AppConfiguration.API.Endpoints.resetPassword,
            parameters: ["Email": email, "OTP": otp, "NewPassword": newPassword],
            requiresAuth: false
        )
        return response.isSuccess
    }

    func updateDeviceToken(userId: String, token: String) async throws -> Bool {
        let response: DeviceTokenResponse = try await requestAuth(
            endpoint: AppConfiguration.API.Endpoints.updateDeviceToken,
            parameters: ["UserId": userId, "DeviceToken": token],
            requiresAuth: true
        )
        return response.Status == 200
    }

    private func requestAuth<T: Decodable>(
        endpoint: String,
        parameters: [String: Any],
        requiresAuth: Bool
    ) async throws -> T {
        try await apiClient.request(
            endpoint: endpoint,
            method: .post,
            parameters: parameters,
            requiresAuth: requiresAuth
        )
    }

    private func loginParameters(email: String, password: String) -> [String: Any] {
        ["Email": email, "Password": password]
    }

    private func persistSession(from userData: LoginUserData) {
        if let accessToken = userData.Accesstoken, let refreshToken = userData.Refreshtoken {
            sessionManager.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
        }
        sessionManager.saveUserData(
            userID: userData.UserId ?? "",
            username: userData.Username ?? "",
            email: userData.Email ?? "",
            role: userData.Role ?? "",
            missingStep: userData.MissingStep
        )
    }
}

// MARK: - Supporting Models
struct RegistrationData {
    let email: String
    let password: String
    let username: String
    let phoneNumber: String?
    let role: String

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "Email": email, "Password": password,
            "Username": username, "Role": role
        ]
        if let phone = phoneNumber { dict["PhoneNumber"] = phone }
        return dict
    }
}

struct RegistrationResult: Codable {
    let UserId: String?
    let Message: String?
}

