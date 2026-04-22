import Foundation

// Voyage Status Enum
enum VoyageStatus: String, Codable {
    case confirmed = "Accepted"
    case unconfirmed = "Pending"
}

// Voyage Model
struct Voyage: Codable, Identifiable {
    var id: String
    var name: String
    var captainUserId: String
    var captainName: String
    var pickupDock: String
    var pickupDockLatitude: Double
    var pickupDockLongitude: Double
    var dropOffDock: String
    var dropOffDockLatitude: Double
    var dropOffDockLongitude: Double
    var boatName: String
    var boatModel: String
    var otp: Int
    var amountToPay: Double
    var waterStay: String
    var noOfvoyagers: Int
    var duration: String
    var BookingDateTime: String
    var sponsors: [Sponsor]?

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
        case amountToPay = "AmountToPay"
        case noOfvoyagers = "NoOfVoyagers"
        case waterStay = "WaterStay"
        case duration = "Duration"
        case BookingDateTime = "BookingDateTime"
        case sponsors = "Sponsers"
    }
}
struct Sponsor: Codable, Identifiable {
    var id: String { VoyagerUserId }
    let VoyagerUserId: String
    let VoyagerUserName: String
    let AmountToPay: Double
    let Status: String
}
// Response Model
struct FutureVoyageResponse: Codable {
    let status: Int
    let message: String
    let obj: FutureVoyageDetails
    
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
    
}

// Voyage Details Model
struct FutureVoyageDetails: Codable {
    let unConfirmed: Voyage?   // Single Voyage
    let confirmed: [Voyage]
    
    enum CodingKeys: String, CodingKey {
        case unConfirmed = "UnConfirmed"
        case confirmed = "Confirmed"
    }
}


// Cancel Voyage

struct VoyageValidationResponse: Codable {
    let status: Int
    let message: String
    let obj: String
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
}
// Voyage Confirmation
struct VoyageConfirmationResponse: Codable {
    let status: Int
    let message: String
    let obj: String
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
}




