import Foundation

protocol BusinessRepositoryProtocol {
    func getBusinessDashboard() async throws -> BusinessDashboard
    func getLockedDock() async throws -> DockDropdownData
    func saveBusinessDashboard(parameters: [String: Any]) async throws -> String?
    func deleteImage(path: String) async throws -> String
}

final class BusinessRepository: BusinessRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func getBusinessDashboard() async throws -> BusinessDashboard {
        let response: BaseResponse<BusinessDashboard> = try await requestAuthorized(
            endpoint: "/Business/Get",
            method: .get,
            parameters: nil
        )
        return try requireObject(
            in: response,
            errorMessage: "Invalid response or missing business dashboard data"
        )
    }

    func getLockedDock() async throws -> DockDropdownData {
        let response: BaseResponse<DockDropdownData> = try await requestAuthorized(
            endpoint: "/Lookup/Dock",
            method: .get,
            parameters: nil
        )
        return try requireObject(
            in: response,
            errorMessage: "Invalid response or missing dock data"
        )
    }

    func saveBusinessDashboard(parameters: [String: Any]) async throws -> String? {
        let response: BaseResponse<String> = try await requestAuthorized(
            endpoint: "/Business/Save",
            method: .post,
            parameters: parameters
        )
        return response.obj
    }

    func deleteImage(path: String) async throws -> String {
        let response: BaseResponse<String> = try await requestAuthorized(
            endpoint: "/BusinessInfo/DeleteImage",
            method: .post,
            parameters: ["Path": path]
        )
        return try requireObject(
            in: response,
            errorMessage: "Invalid response from delete image"
        )
    }

    private func requestAuthorized<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]?
    ) async throws -> BaseResponse<T> {
        try await apiClient.request(
            endpoint: endpoint,
            method: method,
            parameters: parameters,
            requiresAuth: true
        )
    }

    private func requireObject<T>(
        in response: BaseResponse<T>,
        errorMessage: String
    ) throws -> T {
        guard let object = response.obj else {
            throw AppError.networkError(errorMessage)
        }
        return object
    }
}
