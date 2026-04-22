//
//  CaptainActiveVoyageModel.swift
//  BoatSharingApp
//
//  Created by Mac User on 13/05/2025.
//

import Foundation

// MARK: - Voyage Status Enum
enum CaptainVoyageStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case accepted = "Accepted"
    case started = "Started"
}

// MARK: - Top-Level Response
struct CaptainActiveVoyagesResponse: Codable {
    let status: Int
    let message: String
    let obj: VoyageGroups
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
    
}

// MARK: - Voyage Groups Container
struct VoyageGroups: Codable {
    let pending: [CaptainVoyage]
    let accepted: [CaptainVoyage]
    let started: [CaptainVoyage]

    enum CodingKeys: String, CodingKey {
        case pending = "Pending"
        case accepted = "Accepted"
        case started = "Started"
    }
}

// MARK: - Shared Voyage Model
struct CaptainVoyage: Codable, Identifiable {
    let id: String
    let name: String
    let voyagerUserId: String
    let voyagerName: String
    let voyagerPhoneNumber: String
    let pickupDock: String
    let pickupDockLatitude: Double
    let pickupDockLongitude: Double
    let dropOffDock: String
    let dropOffDockLatitude: Double
    let dropOffDockLongitude: Double
    let noOfVoyager: Int
    let bookingDateTime: String
    let amountToPay: Double
    let waterStay: String
    let duration: String?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case voyagerUserId = "VoyagerUserId"
        case voyagerName = "VoyagerName"
        case voyagerPhoneNumber = "VoyagerPhoneNumber"
        case pickupDock = "PickupDock"
        case pickupDockLatitude = "PickupDockLatitude"
        case pickupDockLongitude = "PickupDockLongitude"
        case dropOffDock = "DropOffDock"
        case dropOffDockLatitude = "DropOffDockLatitude"
        case dropOffDockLongitude = "DropOffDockLongitude"
        case noOfVoyager = "NoOfVoyager"
        case bookingDateTime = "BookingDateTime"
        case amountToPay = "AmountToPay"
        case waterStay = "WaterStay"
        case duration = "Duration"
    }
}

struct AcceptVoyageResponse: Decodable {
    let status: Int
    let message: String
    let obj: String

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
}

