import Foundation
import Alamofire

// MARK: - Networking stack
//
// Single pipeline for app HTTP:
// - `APIClient`: one Alamofire `Session`, attaches Bearer when `requiresAuth`, decodes `T`.
//   Encoding is derived automatically: GET / DELETE use URLEncoding.queryString, all others use JSONEncoding.default.
// - `APIClientWithRetry`: wraps `APIClient` only; on `APIError.unauthorized` with `requiresAuth`,
//   calls `SessionManaging.refreshToken()` once, then repeats the **same** `APIClient.request`.
// - Token refresh HTTP itself lives on `APIClient` (`refreshSessionTokens`) so it is not a
//   second ad-hoc stack in `SessionManager` / `LiveRefreshTokenService`.
// - Repositories and ViewModels depend on `APIClientProtocol` only. They MUST NOT import Alamofire.

// MARK: - API Error
enum APIError: Error, LocalizedError {
    case invalidResponse
    case decodingFailed(Error)
    case networkError(Error)
    case serverError(statusCode: Int, message: String)
    case unauthorized
    case sessionExpired
    case noInternetConnection
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidResponse:          return "Invalid response from server"
        case .decodingFailed(let e):    return "Failed to decode response: \(e.localizedDescription)"
        case .networkError(let e):      return "Network error: \(e.localizedDescription)"
        case .serverError(_, let msg):  return msg
        case .unauthorized:             return "Unauthorized access"
        case .sessionExpired:           return "Your session has expired. Please login again."
        case .noInternetConnection:     return "No internet connection available"
        case .timeout:                  return "Request timed out. Please try again."
        }
    }
}

// MARK: - Token refresh response (decoded by `APIClient.refreshSessionTokens` only)
struct RefreshTokenResponse: Codable {
    let Status: Int
    let Message: String
    let obj: SessionTokenData
}

struct SessionTokenData: Codable {
    let Accesstoken: String
    let Refreshtoken: String
}

// MARK: - API Client Implementation
final class APIClient: APIClientProtocol {
    private let baseURL: String
    private let session: Session
    private let sessionManager: SessionManaging
    private let routingNotifierValue: AppRoutingNotifying

    var routingNotifier: AppRoutingNotifying { routingNotifierValue }

    /// Dedicated Alamofire session for **unauthenticated** token refresh only (no retry wrapper, no Bearer).
    private static let refreshSession: Session = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = AppConfiguration.API.timeout
        cfg.timeoutIntervalForResource = AppConfiguration.API.timeout
        return Session(configuration: cfg)
    }()

    init(
        baseURL: String = AppConfiguration.API.baseURL,
        sessionManager: SessionManaging,
        routingNotifier: AppRoutingNotifying
    ) {
        self.baseURL = baseURL
        self.sessionManager = sessionManager
        self.routingNotifierValue = routingNotifier

        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = AppConfiguration.API.timeout
        cfg.timeoutIntervalForResource = AppConfiguration.API.timeout
        self.session = Session(configuration: cfg)
    }

    /// Performs the refresh-token POST using the same base URL and timeouts as authenticated traffic,
    /// but **never** goes through `APIClientWithRetry` (avoids refresh, 401, refresh recursion).
    static func refreshSessionTokens(accessToken: String, refreshToken: String) async throws -> SessionTokenData {
        let url = "\(AppConfiguration.API.baseURL)\(AppConfiguration.API.Endpoints.refreshToken)"
        let parameters: Parameters = [
            "Accesstoken": accessToken,
            "Refreshtoken": refreshToken
        ]

        return try await withCheckedThrowingContinuation { continuation in
            Self.refreshSession
                .request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
                .validate(statusCode: 200..<600)
                .responseDecodable(of: RefreshTokenResponse.self) { response in
                    switch response.result {
                    case .success(let data):
                        guard data.Status == 200 else {
                            continuation.resume(throwing: APIError.serverError(statusCode: data.Status, message: data.Message))
                            return
                        }
                        continuation.resume(returning: data.obj)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    /// Central request entry point.
    /// Encoding is derived from `method` by default:
    ///   - GET / DELETE use URLEncoding.queryString  (params become `?key=value`)
    ///   - All others use JSONEncoding.default       (params go in the JSON body)
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: Parameters?,
        requiresAuth: Bool
    ) async throws -> T {
        let encoding: ParameterEncoding = (method == .get || method == .delete)
            ? URLEncoding.queryString
            : JSONEncoding.default
        return try await _request(endpoint: endpoint, method: method, parameters: parameters, encoding: encoding, requiresAuth: requiresAuth)
    }

    private func _request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: Parameters?,
        encoding: ParameterEncoding,
        requiresAuth: Bool
    ) async throws -> T {
        let url = "\(baseURL)\(endpoint)"
        var headers = HTTPHeaders(["Content-Type": "application/json"])

        if requiresAuth {
            guard let token = sessionManager.accessToken else {
                throw APIError.unauthorized
            }
            headers.add(.authorization(bearerToken: token))
        }

        return try await withCheckedThrowingContinuation { continuation in
            session.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
                .validate(statusCode: 200..<600)
                .responseData { response in
                    if let statusCode = response.response?.statusCode, statusCode == 401, requiresAuth {
                        continuation.resume(throwing: APIError.unauthorized)
                        return
                    }

                    switch response.result {
                    case .success(let data):
                        do {
                            let decoded = try JSONDecoder().decode(T.self, from: data)
                            continuation.resume(returning: decoded)
                        } catch {
                            continuation.resume(throwing: APIError.decodingFailed(error))
                        }

                    case .failure(let error):
                        if let statusCode = response.response?.statusCode, statusCode == 401, requiresAuth {
                            continuation.resume(throwing: APIError.unauthorized)
                            return
                        }
                        continuation.resume(throwing: self.handleAFError(error))
                    }
                }
        }
    }

    private func handleAFError(_ error: AFError) -> APIError {
        if let underlyingError = error.underlyingError as NSError? {
            switch underlyingError.code {
            case NSURLErrorTimedOut:                                        return .timeout
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost: return .noInternetConnection
            default: break
            }
        }
        if case .responseSerializationFailed(let reason) = error,
           case .decodingFailed(let decodeError) = reason {
            return .decodingFailed(decodeError)
        }
        return .networkError(error)
    }
}

// MARK: - API Client with Auto-Retry
final class APIClientWithRetry: APIClientProtocol {
    private let baseClient: APIClient
    private let sessionManager: SessionManaging

    var routingNotifier: AppRoutingNotifying { baseClient.routingNotifier }

    init(baseClient: APIClient, sessionManager: SessionManaging) {
        self.baseClient = baseClient
        self.sessionManager = sessionManager
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: Parameters?,
        requiresAuth: Bool
    ) async throws -> T {
        do {
            return try await baseClient.request(
                endpoint: endpoint, method: method,
                parameters: parameters, requiresAuth: requiresAuth
            )
        } catch APIError.unauthorized {
            guard requiresAuth else { throw APIError.unauthorized }

            let refreshed = await sessionManager.refreshToken()
            guard refreshed else { throw APIError.sessionExpired }

            return try await baseClient.request(
                endpoint: endpoint, method: method,
                parameters: parameters, requiresAuth: requiresAuth
            )
        }
    }
}

// MARK: - Error mapping (completion bridge / AFError interop)

enum NetworkErrorMapper {
    static func mapToAFError(_ error: Error) -> AFError {
        if let afError = error as? AFError { return afError }
        if let apiError = error as? APIError {
            switch apiError {
            case .timeout:
                return .sessionTaskFailed(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut,
                    userInfo: [NSLocalizedDescriptionKey: apiError.localizedDescription]))
            case .noInternetConnection:
                return .sessionTaskFailed(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet,
                    userInfo: [NSLocalizedDescriptionKey: apiError.localizedDescription]))
            case .unauthorized, .sessionExpired:
                return .responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
            case .serverError(let code, _):
                return .responseValidationFailed(reason: .unacceptableStatusCode(code: code))
            case .decodingFailed(let e):
                return .responseSerializationFailed(reason: .decodingFailed(error: e))
            default:
                return .sessionTaskFailed(error: NSError(domain: "com.boatit.network", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: apiError.localizedDescription]))
            }
        }
        return .sessionTaskFailed(error: error)
    }
}
