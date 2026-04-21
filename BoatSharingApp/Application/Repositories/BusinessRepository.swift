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
        let response: BaseResponse<BusinessDashboard> = try await apiClient.request(
            endpoint: "/Business/Get",
            method: .get,
            parameters: nil,
            requiresAuth: true
        )
        guard let data = response.obj else {
            throw AppError.networkError("Invalid response or missing business dashboard data")
        }
        return data
    }

    func getLockedDock() async throws -> DockDropdownData {
        let response: BaseResponse<DockDropdownData> = try await apiClient.request(
            endpoint: "/Lookup/Dock",
            method: .get,
            parameters: nil,
            requiresAuth: true
        )
        guard let data = response.obj else {
            throw AppError.networkError("Invalid response or missing dock data")
        }
        return data
    }

    func saveBusinessDashboard(parameters: [String: Any]) async throws -> String? {
        let response: BaseResponse<String> = try await apiClient.request(
            endpoint: "/Business/Save",
            method: .post,
            parameters: parameters,
            requiresAuth: true
        )
        return response.obj
    }

    func deleteImage(path: String) async throws -> String {
        let response: BaseResponse<String> = try await apiClient.request(
            endpoint: "/BusinessInfo/DeleteImage",
            method: .post,
            parameters: ["Path": path],
            requiresAuth: true
        )
        guard let data = response.obj else {
            throw AppError.networkError("Invalid response from delete image")
        }
        return data
    }
}
