import Foundation
import Alamofire

/// Repository for authentication-related operations.
/// Networking: `apiClient.request` only (in production the shared `APIClientWithRetry` to base `APIClient` path).
/// Encoding is derived automatically inside APIClient from the HTTP method â€” no Alamofire encoding types here.
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
        let response: LoginResponse = try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.login,
            method: HTTPMethod.post,
            parameters: ["Email": email, "Password": password],
            requiresAuth: false
        )

        guard response.Status == 200 else {
            throw APIError.serverError(
                statusCode: response.Status,
                message: response.Message.isEmpty ? "Login failed" : response.Message
            )
        }
        guard let userData = response.obj else { throw APIError.invalidResponse }

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
        return userData
    }

    func loginDecodedUserData(email: String, password: String) async throws -> UserData {
        let response: BaseResponse<UserData> = try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.login,
            method: HTTPMethod.post,
            parameters: ["Email": email, "Password": password],
            requiresAuth: false
        )
        return try APIResponseValidator.requireSuccess(response)
    }

    func register(userData: RegistrationData) async throws -> RegistrationResult {
        let response: BaseResponse<RegistrationResult> = try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.register,
            method: HTTPMethod.post,
            parameters: userData.toDictionary(),
            requiresAuth: false
        )
        guard response.isSuccess, let result = response.obj else {
            throw APIError.serverError(statusCode: response.Status, message: response.Message)
        }
        return result
    }

    func forgotPassword(email: String) async throws -> Bool {
        let response: EmptyResponse = try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.forgotPassword,
            method: HTTPMethod.post,
            parameters: ["Email": email],
            requiresAuth: false
        )
        return response.isSuccess
    }

    func resetPassword(email: String, otp: String, newPassword: String) async throws -> Bool {
        let response: EmptyResponse = try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.resetPassword,
            method: HTTPMethod.post,
            parameters: ["Email": email, "OTP": otp, "NewPassword": newPassword],
            requiresAuth: false
        )
        return response.isSuccess
    }

    func updateDeviceToken(userId: String, token: String) async throws -> Bool {
        let response: DeviceTokenResponse = try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.updateDeviceToken,
            method: HTTPMethod.post,
            parameters: ["UserId": userId, "DeviceToken": token],
            requiresAuth: true
        )
        return response.Status == 200
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

