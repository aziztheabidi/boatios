//
//  PastVoyageModel.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 22/08/2025.
//
//
//  PastVoyageViewModel.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 22/08/2025.
//

import Foundation

// MARK: - Root Response
struct PastVoyageResponse: Codable {
    let status: Int
    let message: String
    let voyages: [PastVoyage]

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case voyages = "obj"
    }
}

// MARK: - Voyage Model
struct PastVoyage: Codable, Identifiable {
    let id: String
    let name: String
    let captainUserId: String
    let captainName: String
    let pickupDock: String
    let pickupDockLatitude: Double
    let pickupDockLongitude: Double
    let dropOffDock: String
    let dropOffDockLatitude: Double
    let dropOffDockLongitude: Double
    let boatName: String
    let boatModel: String
    let rating: Int?
    let otp: Int
    let noOfVoyagers: Int
    let amountToPay: Double
    let waterStay: String
    let duration: String
    let bookingDateTime: String
    let sponsors: [Sponsorarray]

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case captainUserId = "CaptainUserId"
        case captainName = "CaptainName"
        case pickupDock = "PickupDock"
        case pickupDockLatitude = "PickupDockLatitude"
        case pickupDockLongitude = "PickupDockLongitude"
        case dropOffDock = "DropOffDock"
        case dropOffDockLatitude = "DropOffDockLatitude"
        case dropOffDockLongitude = "DropOffDockLongitude"
        case boatName = "BoatName"
        case boatModel = "BoatModel"
        case rating = "Rating"
        case otp = "OTP"
        case noOfVoyagers = "NoOfVoyagers"
        case amountToPay = "AmountToPay"
        case waterStay = "WaterStay"
        case duration = "Duration"
        case bookingDateTime = "BookingDateTime"
        case sponsors = "Sponsers"
    }
}

// Captain

// MARK: - Root Response
struct CaptainCompletedVoyagesResponse: Codable {
    let status: Int
    let message: String
    let voyages: [CaptainCompletedVoyage]

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case voyages = "obj"
    }
}

// MARK: - Captain Completed Voyage
struct CaptainCompletedVoyage: Codable, Identifiable {
    let id: String
    let name: String
    let voyagerUserId: String
    let voyagerName: String
    let voyagerPhoneNumber: String
    let rating: String?              // can be null
    let pickupDock: String
    let pickupDockLatitude: Double
    let pickupDockLongitude: Double
    let dropOffDock: String
    let dropOffDockLatitude: Double
    let dropOffDockLongitude: Double
    let noOfVoyager: Int
    let amountToPay: Double
    let waterStay: String
    let duration: String
    let bookingDateTime: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case voyagerUserId = "VoyagerUserId"
        case voyagerName = "VoyagerName"
        case voyagerPhoneNumber = "VoyagerPhoneNumber"
        case rating = "Rating"
        case pickupDock = "PickupDock"
        case pickupDockLatitude = "PickupDockLatitude"
        case pickupDockLongitude = "PickupDockLongitude"
        case dropOffDock = "DropOffDock"
        case dropOffDockLatitude = "DropOffDockLatitude"
        case dropOffDockLongitude = "DropOffDockLongitude"
        case noOfVoyager = "NoOfVoyager"
        case amountToPay = "AmountToPay"
        case waterStay = "WaterStay"
        case duration = "Duration"
        case bookingDateTime = "BookingDateTime"
    }
}







// MARK: - Sponsor Model
struct Sponsorarray: Codable, Identifiable {
    let id = UUID()  // since your example shows empty array, no fields provided
}


