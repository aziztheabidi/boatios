//
//  VoyagerPaymentModel.swift
//  BoatSharingApp
//
//  Created by Mac User on 01/06/2025.
//

import Foundation

struct VoyagerPaymentResponse: Codable {
    let status: Int
    let message: String
    let obj: [VoyageDetail]

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj
    }
}

struct VoyageDetail: Codable, Identifiable {
    let id: String = UUID().uuidString // Added for Identifiable
    let voyagerName: String
    let voyagerPhoneNumber: String
    let pickupDock: String
    let dropOffDock: String
    let boatName: String
    let boatModel: String
    let noOfVoyagers: Int
    let bookingDateTime: String

    enum CodingKeys: String, CodingKey {
        case voyagerName = "VoyagerName"
        case voyagerPhoneNumber = "VoyagerPhoneNumber"
        case pickupDock = "PickupDock"
        case dropOffDock = "DropOffDock"
        case boatName = "BoatName"
        case boatModel = "BoatModel"
        case noOfVoyagers = "NoOfVoyagers"
        case bookingDateTime = "BookingDateTime"
    }
}

