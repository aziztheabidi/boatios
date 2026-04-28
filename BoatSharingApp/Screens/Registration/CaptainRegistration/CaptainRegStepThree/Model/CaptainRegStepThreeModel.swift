//
//  CaptainRegStepThreeModel.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 25/02/2025.
//

import Foundation

struct CaptainRegStepThreeModel: Decodable {
    let Status: Int
    let Message: String
    let obj: String
}

struct CaptainBoatResponse: Codable {
    let status: Int
    let message: String
    let obj: CaptainBoat?
}

struct CaptainBoat: Codable, Equatable {
    let name: String
    let make: String
    let model: String
    let year: Int
    let size: Int
    let capacity: Int
    let userId: String
    let changedOn: Date
    let changedBy: String

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case make = "Make"
        case model = "Model"
        case year = "Year"
        case size = "Size"
        case capacity = "Capacity"
        case userId = "UserId"
        case changedOn = "ChangedOn"
        case changedBy = "ChangedBy"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        make = try container.decode(String.self, forKey: .make)
        model = try container.decode(String.self, forKey: .model)
        year = try container.decode(Int.self, forKey: .year)
        size = try container.decode(Int.self, forKey: .size)
        capacity = try container.decode(Int.self, forKey: .capacity)
        userId = try container.decode(String.self, forKey: .userId)
        changedBy = try container.decode(String.self, forKey: .changedBy)

        let dateString = try container.decode(String.self, forKey: .changedOn)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let date = formatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .changedOn, in: container, debugDescription: "Date string does not match format.")
        }

        changedOn = date
    }
}




