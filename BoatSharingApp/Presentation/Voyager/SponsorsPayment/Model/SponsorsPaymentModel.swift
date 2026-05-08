import Foundation

// MARK: - Root Response
struct SponsorPaymentResponse: Codable {
    let status: Int
    let message: String
    let obj: [SponsorPayment]
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj
    }
}

// MARK: - Voyager Payment Object
struct SponsorPayment: Codable, Identifiable {
    let id: String
    let name: String
    let voyagerName: String
    let voyagerPhoneNumber: String
    let pickupDock: String
    let pickupDockLatitude: Double
    let pickupDockLongitude: Double
    let dropOffDock: String
    let dropOffDockLatitude: Double
    let dropOffDockLongitude: Double
    let amountToPay: Double
    let noOfVoyagers: Int
    let waterStay: String
    let duration: String
    let VoyageStatus: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case voyagerName = "VoyagerName"
        case voyagerPhoneNumber = "VoyagerPhoneNumber"
        case pickupDock = "PickupDock"
        case pickupDockLatitude = "PickupDockLatitude"
        case pickupDockLongitude = "PickupDockLongitude"
        case dropOffDock = "DropOffDock"
        case dropOffDockLatitude = "DropOffDockLatitude"
        case dropOffDockLongitude = "DropOffDockLongitude"
        case amountToPay = "AmountToPay"
        case noOfVoyagers = "NoOfVoyagers"
        case waterStay = "WaterStay"
        case duration = "Duration"
        case VoyageStatus = "VoyageStatus"
    }
}

