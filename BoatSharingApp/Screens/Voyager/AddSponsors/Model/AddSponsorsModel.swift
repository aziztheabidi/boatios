//
//  SplitPaymentModel.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 10/04/2025.
//

import Foundation

// MARK: - Root Response
struct AddSponsorsModel: Codable {
    let status: Int
    let message: String
    let obj: FollowedVoyagerObject

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
}

// MARK: - Object Container
struct FollowedVoyagerObject: Codable {
    let mySelf: VoyagerProfile
    let followed: [VoyagerProfile]

    enum CodingKeys: String, CodingKey {
        case mySelf = "MySelf"
        case followed = "Followed"
    }
}

// MARK: - Voyager Profile
struct VoyagerProfile: Codable, Identifiable {
    var id: String { userId }

    let phoneNumber: String
    let firstName: String
    let lastName: String
    let address: String
    let dateOfBirth: String
    let stripeEmail: String
    let userId: String
    let changedOn: String
    let changedBy: String

    enum CodingKeys: String, CodingKey {
        case phoneNumber = "PhoneNumber"
        case firstName = "FirstName"
        case lastName = "LastName"
        case address = "Address"
        case dateOfBirth = "DateOfBirth"
        case stripeEmail = "StripeEmail"
        case userId = "UserId"
        case changedOn = "ChangedOn"
        case changedBy = "ChangedBy"
    }
}

