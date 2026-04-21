import Foundation

// MARK: - Base API Response
/// Generic base response model that wraps most API responses from the BoatIT API
struct BaseResponse<T: Codable>: Codable {
    let Status: Int
    let Message: String
    let obj: T?
    
    var isSuccess: Bool {
        return Status == 200
    }
}

// MARK: - Empty Response
/// Used for endpoints that don't return data in the obj field
struct EmptyResponse: Codable {
    let Status: Int
    let Message: String
    
    var isSuccess: Bool {
        return Status == 200
    }
}

// MARK: - Pagination Response
struct PaginatedResponse<T: Codable>: Codable {
    let Status: Int
    let Message: String
    let obj: PaginatedData<T>?
}

struct PaginatedData<T: Codable>: Codable {
    let items: [T]
    let totalCount: Int
    let currentPage: Int
    let pageSize: Int
    let totalPages: Int
}

// MARK: - Common Response Types
struct DeviceTokenResponse: Codable {
    let Status: Int
    let Message: String
}

struct MessageOnlyResponse: Codable {
    let Message: String
}
