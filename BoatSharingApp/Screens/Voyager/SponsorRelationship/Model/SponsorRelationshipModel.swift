//
//  SponsorRelationshipModel.swift
//  BoatSharingApp
//
//  Created by Mac User on 06/05/2025.
//

import Foundation

// MARK: - VoyagerRelationshipResponse
struct SponsorRelationshipModel: Codable {
    let status: Int
    let message: String
    let obj: VoyagerRelationshipData

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
}


// MARK: - VoyagerRelationshipData
struct VoyagerRelationshipData: Codable {
    let mySelf: VoyagerUser
    let followed: [VoyagerUser]
    let unFollowed: [VoyagerUser]

    enum CodingKeys: String, CodingKey {
        case mySelf = "MySelf"
        case followed = "Followed"
        case unFollowed = "UnFollowed"
    }
}

// MARK: - VoyagerUser
struct VoyagerUser: Codable, Identifiable {
    var id: String { userId }
    let userId: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let address: String
    let dateOfBirth: String

    enum CodingKeys: String, CodingKey {
        case userId = "UserId"
        case firstName = "FirstName"
        case lastName = "LastName"
        case phoneNumber = "PhoneNumber"
        case address = "Address"
        case dateOfBirth = "DateOfBirth"
    }
}

// follow
struct FollowResponseModel: Decodable {
    let status: Int
    let message: String
    let obj: String  // or use optional `Any?` if `obj` can be of different types

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
}


