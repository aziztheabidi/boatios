import Foundation
import Alamofire

// MARK: - HTTP client abstraction
//
// Production: `APIClient` / `APIClientWithRetry`. Tests and previews: mocks conforming to this protocol.
// Encoding is derived from the HTTP method in the concrete client — call sites never deal with Alamofire types.

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
    /// Prefer the async `request` overload for new code.
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
