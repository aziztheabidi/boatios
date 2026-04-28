import Foundation
import Alamofire
@testable import BoatSharingApp

final class GenericEndpointAPIClient: APIClientProtocol {
    private let handler: (String) -> Result<Any, Error>
    private(set) var requestedEndpoints: [String] = []

    init(handler: @escaping (String) -> Result<Any, Error>) {
        self.handler = handler
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: Parameters?,
        requiresAuth: Bool
    ) async throws -> T {
        requestedEndpoints.append(endpoint)
        switch handler(endpoint) {
        case .success(let value):
            guard let typed = value as? T else {
                throw APIError.invalidResponse
            }
            return typed
        case .failure(let error):
            throw error
        }
    }
}

final class CapturingEndpointAPIClient: APIClientProtocol {
    struct RequestRecord {
        let endpoint: String
        let parameters: Parameters?
    }

    private let handler: (String, Parameters?) -> Result<Any, Error>
    private(set) var requestRecords: [RequestRecord] = []

    init(handler: @escaping (String, Parameters?) -> Result<Any, Error>) {
        self.handler = handler
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: Parameters?,
        requiresAuth: Bool
    ) async throws -> T {
        requestRecords.append(.init(endpoint: endpoint, parameters: parameters))
        switch handler(endpoint, parameters) {
        case .success(let value):
            guard let typed = value as? T else {
                throw APIError.invalidResponse
            }
            return typed
        case .failure(let error):
            throw error
        }
    }
}

final class ViewModelSessionPreferenceStore: SessionPreferenceStoring, PreferenceStoring {
    var isLoggedIn: Bool = false
    var userRole: String = ""
    var missingStep: Int = 1
    var userID: String = ""
    var username: String = ""
    var userEmail: String = ""
    var fromBusinessDetail: Bool = false

    func clearSessionPreferences() {
        isLoggedIn = false
        userRole = ""
        missingStep = 1
        userID = ""
        username = ""
        userEmail = ""
    }
}

