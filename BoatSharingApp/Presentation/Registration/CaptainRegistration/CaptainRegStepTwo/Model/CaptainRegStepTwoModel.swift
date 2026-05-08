//
//  Untitled.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 25/02/2025.
//

import Foundation

struct CaptainRegStepTwoModel: Decodable {
    let Status: Int
    let Message: String
    let obj: String
}




// MARK: - Captain Document Response
struct CaptainDocumentResponse: Codable {
    let status: Int
    let message: String
    let document: CaptainDocument

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case document = "obj"
    }
}

// MARK: - License Type Enum
enum LicenseType: String, Codable {
    case basic = "Basic"
    case commercial = "Commercial"
    case advanced = "Advanced"
    case unknown = ""

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = LicenseType(rawValue: value) ?? .unknown
    }
}

// MARK: - Captain Document Model
struct CaptainDocument: Codable, Equatable {
    let licenseNumber: String
    let licenseExpiration: String
    let typeOfLicense: String
    let insuranceCompany: String
    let policyNumber: String
    let policyExpiration: String
    let userId: String
    let changedOn: String
    let changedBy: String

    enum CodingKeys: String, CodingKey {
        case licenseNumber = "LicenseNumber"
        case licenseExpiration = "LicenseExpiration"
        case typeOfLicense = "TypeOfLicense"
        case insuranceCompany = "InsuranceCompany"
        case policyNumber = "PolicyNumber"
        case policyExpiration = "PolicyExpiration"
        case userId = "UserId"
        case changedOn = "ChangedOn"
        case changedBy = "ChangedBy"
    }
}




