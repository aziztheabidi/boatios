//
//  CreatePasswordModel.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 24/02/2025.
//

import Foundation

struct CreatePasswordModel: Decodable {
    let status: Int
    let message: String
    let obj: RegisterUserData?
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj
    }
}
struct RegisterUserData: Decodable {
    let email: String?
    let userId: String?
    let username: String?
    let role: String?
    let MissingStep: Int?
    let password: String?
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
