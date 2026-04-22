import Foundation

struct TravelNowVoyage: Codable, Identifiable {
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
    let otp: Int?
    let noOfVoyagers: Int
    let amountToPay: Double
    let waterStay: String
    let duration: String
    let bookingDateTime: String
    let sponsors: [String]

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
        case otp = "OTP"
        case noOfVoyagers = "NoOfVoyagers"
        case amountToPay = "AmountToPay"
        case waterStay = "WaterStay"
        case duration = "Duration"
        case bookingDateTime = "BookingDateTime"
        case sponsors = "Sponsers"
    }
}
import Foundation

struct TravelVoyageResponse: Codable {
    let status: Int
    let message: String
    let obj: TravelNowVoyage

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj
    }
}


