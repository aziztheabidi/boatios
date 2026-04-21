import Foundation
import CoreLocation

// MARK: - Active Docks Response
struct ActiveDocksResponse: Codable {
    let status: Int
    let message: String
    let obj: ActiveDockCategories

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
}

// MARK: - Object that holds categorized docks
struct ActiveDockCategories: Codable {
    let all: [Dock]
    let business: [Dock]

    enum CodingKeys: String, CodingKey {
        case all = "All"
        case business = "Business"
    }
}

// MARK: - Dock Model
struct Dock: Codable, Identifiable, Equatable {
    let id: UUID = UUID() // Local UUID for SwiftUI
    let name: String
    let zone: String
    let state: String
    let city: String
    let zipCode: String
    let shoreLine: String
    let address: String
    let latitude: Double
    let longitude: Double
    let dockTypeId: Int
    let dockType: String
    let userId: String?
    let changedOn: String
    let changedBy: String?

    // Convenience initializer for UserDefaults
    init(businessID: String, name: String) {
        self.name = name
        self.zone = ""
        self.state = ""
        self.city = ""
        self.zipCode = ""
        self.shoreLine = ""
        self.address = ""
        self.latitude = 0.0
        self.longitude = 0.0
        self.dockTypeId = 0
        self.dockType = ""
        self.userId = businessID // Store businessID in userId, or adjust as needed
        self.changedOn = ""
        self.changedBy = nil
    }

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case zone = "Zone"
        case state = "State"
        case city = "City"
        case zipCode = "ZipCode"
        case shoreLine = "ShoreLine"
        case address = "Address"
        case latitude = "Latitude"
        case longitude = "Longitude"
        case dockTypeId = "DockTypeId"
        case dockType = "DockType"
        case userId = "UserId"
        case changedOn = "ChangedOn"
        case changedBy = "ChangedBy"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        zone = try container.decode(String.self, forKey: .zone)
        state = try container.decode(String.self, forKey: .state)
        city = try container.decode(String.self, forKey: .city)
        zipCode = try container.decode(String.self, forKey: .zipCode)
        shoreLine = try container.decode(String.self, forKey: .shoreLine)
        address = try container.decode(String.self, forKey: .address)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        dockTypeId = try container.decode(Int.self, forKey: .dockTypeId)
        dockType = try container.decode(String.self, forKey: .dockType)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        changedOn = try container.decodeIfPresent(String.self, forKey: .changedOn) ?? ""
        changedBy = try container.decodeIfPresent(String.self, forKey: .changedBy)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(zone, forKey: .zone)
        try container.encode(state, forKey: .state)
        try container.encode(city, forKey: .city)
        try container.encode(zipCode, forKey: .zipCode)
        try container.encode(shoreLine, forKey: .shoreLine)
        try container.encode(address, forKey: .address)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(dockTypeId, forKey: .dockTypeId)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encode(changedOn, forKey: .changedOn)
        try container.encodeIfPresent(changedBy, forKey: .changedBy)
    }

    static func ==(lhs: Dock, rhs: Dock) -> Bool {
        lhs.id == rhs.id // Adjust if equality should consider other properties
    }
}
// Get Active voyager
struct ActiveVoyagerResponse: Codable {
    let status: Int
    let message: String
    let obj: VoyagerVoyage

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
}

// MARK: - Voyager Voyage
struct VoyagerVoyage: Codable, Identifiable, Equatable {
    let id: String
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
    let otp: Int
    let amountToPay: Double
    let Rating: Double
    let status: String
    /// Included on some payloads (e.g. captain-facing) for chat and display.
    let voyagerUserId: String?
    let voyagerName: String?
    let voyagerPhoneNumber: String?
    let noOfVoyagers: Int?
    let duration: String?
    let waterStay: String?
    let bookingDateTime: String?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
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
        case Rating = "Rating"
        case status = "Status"
        case voyagerUserId = "VoyagerUserId"
        case voyagerName = "VoyagerName"
        case voyagerPhoneNumber = "VoyagerPhoneNumber"
        case noOfVoyagers = "NoOfVoyagers"
        case duration = "Duration"
        case waterStay = "WaterStay"
        case bookingDateTime = "BookingDateTime"
    }
}




