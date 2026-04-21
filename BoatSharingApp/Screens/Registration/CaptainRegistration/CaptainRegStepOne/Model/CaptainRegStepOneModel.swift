//
//  CaptainRegStepOneModel.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 25/02/2025.
//

import Foundation

struct CaptainRegStepOneModel: Decodable {
    let Status: Int
    let Message: String
    let obj: String
}
// MARK: - Captain Profile Response
struct CaptainProfileOneResponse: Codable {
    let status: Int
    let message: String
    let profile: CaptainProfile

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case profile = "obj"
    }
}

// MARK: - Captain Profile Model
struct CaptainProfile: Codable, Equatable {
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







