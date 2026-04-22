//
//  BusinessVoyageModel.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 14/06/2025.
//

import Foundation

// MARK: - Root Response
struct BusinessVoyageModel: Codable {
    let status: StatusCode
    let message: String
    let obj: BusinessRelationshipObject

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj
    }
}

// MARK: - Main Object
struct BusinessRelationshipObject: Codable {
    let followed: [BusinessRelationship]
    let unFollowed: [BusinessRelationship]

    enum CodingKeys: String, CodingKey {
        case followed = "Followed"
        case unFollowed = "UnFollowed"
    }
}

// MARK: - Business Model
struct BusinessRelationship: Codable, Identifiable {
    let id: Int
    let name: String
    let logoPath: String
    let businessType: String
    let yearOfEstablishment: Int
    let description: String
    let imagesPath: [String]
    let location: String
    let businessHours: [BusinessHour]

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case logoPath = "LogoPath"
        case businessType = "BusinessType"
        case yearOfEstablishment = "YearOfEstablishment"
        case description = "Description"
        case imagesPath = "ImagesPath"
        case location = "Location"
        case businessHours = "BusinessHours"
    }
}

// MARK: - Business Hours
struct BusinessHour: Codable {
    let day: String
    let startTime: String
    let endTimeTime: String

    enum CodingKeys: String, CodingKey {
        case day = "Day"
        case startTime = "StartTime"
        case endTimeTime = "EndTimeTime"
    }
}

// follow business
struct FollowBusinessUpdateResponse: Codable {
    let status: StatusCode
    let message: String
    let obj: String
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj
    }
    
    
}

enum StatusCode: Int, Codable {
    case success = 200
    case created = 201
    case badRequest = 400
    case unauthorized = 401
    case notFound = 404
    case serverError = 500

    var isSuccess: Bool {
        return self == .success || self == .created
    }
}

