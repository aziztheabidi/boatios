import Foundation

// ✅ Main response model
struct LoginResponseModel: Codable {
    let status: Int
    let message: String
    let obj: UserData?

    // Match JSON keys
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj
    }
}

// ✅ User Data model (Nested under "obj")
struct UserData: Codable {
    let email: String?
    let userId: String?
    let username: String?
    let role: String?
    let password: String?
    let MissingStep: Int?
    let accessToken: String?
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case email = "Email"
        case userId = "UserId"
        case username = "Username"
        case role = "Role"
        case password = "Password"
        case MissingStep = "MissingStep"
        case accessToken = "Accesstoken"
        case refreshToken = "Refreshtoken"
    }
}

