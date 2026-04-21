import Foundation
import Combine
import Alamofire

// MARK: - Session / refresh contracts
// These protocols are shared across SessionManager, PreferenceStore, live token refresh, and
// preview/test stubs. They live here so AppDependencies can reference them from one location.

protocol SessionPreferenceStoring: AnyObject {
    var isLoggedIn: Bool { get set }
    var userRole: String { get set }
    var missingStep: Int { get set }
    var userID: String { get set }
    var username: String { get set }
    var userEmail: String { get set }
    func clearSessionPreferences()
}

protocol RefreshTokenServicing {
    func refreshToken(accessToken: String, refreshToken: String) async throws -> SessionTokenData
}

// MARK: - HTTP client abstraction
// Production: APIClientWithRetry → APIClient. Test/preview: a mock conforming to this protocol.
// Encoding is derived automatically from the HTTP method — call sites never deal with Alamofire types.

protocol APIClientProtocol {
    var routingNotifier: AppRoutingNotifying { get }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: Parameters?,
        requiresAuth: Bool
    ) async throws -> T
}

// MARK: - Default implementations

private enum DefaultAPIClientRoutingNotifier {
    static let defaultNoOp = NoOpAppRoutingNotifier()
}

extension APIClientProtocol {
    var routingNotifier: AppRoutingNotifying { DefaultAPIClientRoutingNotifier.defaultNoOp }

    /// Completion bridge for callers that have not yet adopted async/await.
    /// Do not add new callers — use the async `request` overload instead.
    func requestDeliveringResult<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: Parameters?,
        completion: @escaping (Result<T, AFError>) -> Void
    ) {
        Task {
            do {
                let decoded: T = try await request(
                    endpoint: endpoint,
                    method: method,
                    parameters: parameters,
                    requiresAuth: false
                )
                await MainActor.run { completion(.success(decoded)) }
            } catch {
                if ErrorHandler.isAuthenticationError(error) {
                    await MainActor.run { self.routingNotifier.syncRoutingFromStorageIfNeeded() }
                }
                let afError = NetworkErrorMapper.mapToAFError(error)
                await MainActor.run { completion(.failure(afError)) }
            }
        }
    }
}
