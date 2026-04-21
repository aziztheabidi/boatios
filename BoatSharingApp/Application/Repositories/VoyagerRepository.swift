import Foundation

/// Repository for Voyager-related operations.
/// Networking: `apiClient.request` only (no direct Alamofire / duplicate retry stacks).
/// Encoding is derived automatically inside APIClient from the HTTP method.
protocol VoyagerRepositoryProtocol {
    func getActiveVoyage() async throws -> VoyageData?
    func getPastVoyages() async throws -> [VoyageData]
    func getFutureVoyages(userId: String) async throws -> [VoyageData]
    func getRelationships() async throws -> [RelationshipData]
    func followVoyager(followeeId: String) async throws -> Bool
    func unfollowVoyager(followeeId: String) async throws -> Bool
}

final class VoyagerRepository: VoyagerRepositoryProtocol {

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func getActiveVoyage() async throws -> VoyageData? {
        let response: BaseResponse<VoyageData> = try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.voyagerActiveVoyage,
            method: .get,
            parameters: nil,
            requiresAuth: true
        )
        return response.obj
    }

    func getPastVoyages() async throws -> [VoyageData] {
        let response: BaseResponse<[VoyageData]> = try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.voyagerPastVoyages,
            method: .get,
            parameters: nil,
            requiresAuth: true
        )
        return response.obj ?? []
    }

    func getFutureVoyages(userId: String) async throws -> [VoyageData] {
        // GET with query param — APIClient auto-applies URLEncoding.queryString for GET requests
        let response: BaseResponse<[VoyageData]> = try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.voyagerFutureVoyages,
            method: .get,
            parameters: ["UserId": userId],
            requiresAuth: true
        )
        return response.obj ?? []
    }

    func getRelationships() async throws -> [RelationshipData] {
        let response: BaseResponse<[RelationshipData]> = try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.voyagerRelationship,
            method: .get,
            parameters: nil,
            requiresAuth: true
        )
        return response.obj ?? []
    }

    func followVoyager(followeeId: String) async throws -> Bool {
        let response: EmptyResponse = try await apiClient.request(
            endpoint: "/Voyager/Follow",
            method: .post,
            parameters: ["FolloweeId": followeeId],
            requiresAuth: true
        )
        return response.isSuccess
    }

    func unfollowVoyager(followeeId: String) async throws -> Bool {
        let response: EmptyResponse = try await apiClient.request(
            endpoint: "/Voyager/UnFollow",
            method: .post,
            parameters: ["FolloweeId": followeeId],
            requiresAuth: true
        )
        return response.isSuccess
    }
}

// MARK: - Domain Models
struct VoyageData: Codable, Identifiable {
    let id: String?
    let voyageId: String?
    let captainId: String?
    let captainName: String?
    let boatName: String?
    let departureTime: String?
    let arrivalTime: String?
    let status: String?
    let fare: Double?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case voyageId = "VoyageId"
        case captainId = "CaptainId"
        case captainName = "CaptainName"
        case boatName = "BoatName"
        case departureTime = "DepartureTime"
        case arrivalTime = "ArrivalTime"
        case status = "Status"
        case fare = "Fare"
    }
}

struct RelationshipData: Codable {
    let followeeId: String?
    let followeeName: String?
    let followeeEmail: String?
    let isFollowing: Bool?

    enum CodingKeys: String, CodingKey {
        case followeeId    = "FolloweeId"
        case followeeName  = "FolloweeName"
        case followeeEmail = "FolloweeEmail"
        case isFollowing   = "IsFollowing"
    }
}
