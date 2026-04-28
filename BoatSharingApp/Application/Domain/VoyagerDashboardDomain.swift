import Foundation

/// Decoded active dock list mapped for UI and booking flows (not `Codable`).
struct ActiveDocks: Equatable, Sendable {
    let all: [DockLocation]
    let business: [DockLocation]
}

/// Pickup/dropoff location shown in voyager home, find-boat, and dock pickers.
struct DockLocation: Identifiable, Equatable, Sendable {
    let id: UUID
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

    /// Synthetic row for business-driven voyage selection (no full dock record from `/Dock/GetActive`).
    static func businessSelection(businessID: String, displayName: String) -> DockLocation {
        DockLocation(
            id: UUID(),
            name: displayName,
            zone: "",
            state: "",
            city: "",
            zipCode: "",
            shoreLine: "",
            address: "",
            latitude: 0,
            longitude: 0,
            dockTypeId: 0,
            dockType: "",
            userId: businessID,
            changedOn: "",
            changedBy: nil
        )
    }
}

/// In-flight voyage details for voyager home overlays and new-request popups (domain; not `Codable`).
struct VoyageSession: Identifiable, Equatable, Sendable {
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
    let rating: Double
    let status: String
    let voyagerUserId: String?
    let voyagerName: String?
    let voyagerPhoneNumber: String?
    let numberOfVoyagers: Int
    let duration: String
    let waterStay: String
    let bookingDateTime: String
}
