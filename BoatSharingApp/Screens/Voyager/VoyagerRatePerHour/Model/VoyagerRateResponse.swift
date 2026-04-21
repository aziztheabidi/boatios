//
//  VoyagerRateResponse.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 10/04/2025.
//

import Foundation

struct VoyagerRateResponse: Codable {
    let status: Int
    let message: String
    let obj: DockRate?
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj
    }
}

struct DockRate: Codable {
    let perHourRate: Double
    let totalFair: Double
    
    enum CodingKeys: String, CodingKey {
        case perHourRate = "PerHourRate"
        case totalFair = "TotalFair"
    }
}

// immedidely Booking / Find boat,...

struct FindBoatResponse: Codable {
    let status: Int
    let message: String
    let obj: String?
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj
    }
    
}

// Book Voyage
struct VoyageBookingResponse: Codable {
    let status: Int
    let message: String
    let obj: String

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
}


