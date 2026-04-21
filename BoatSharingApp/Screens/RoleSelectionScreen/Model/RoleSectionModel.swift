import Foundation

/// Response model for the role-update endpoint.
struct RoleSectionModel: Decodable {
    let Status: Int
    let Message: String
    let obj: RoleRegistrationData?
}

/// Decoded token pair returned after a successful role selection.
struct RoleRegistrationData: Decodable {
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken  = "Accesstoken"
        case refreshToken = "Refreshtoken"
    }
}
