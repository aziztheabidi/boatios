import Foundation

struct VoyageBookingDetails: Equatable {
    /// Voyage / booking identifier (API `Id`).
    let voyageID: String
    /// Display name for the rider / counterparty row (e.g. voyager or captain name).
    let voyagerName: String
    let voyagerCount: Int
    let pickupDock: String
    let dropOffDock: String
    let amountToPay: Double
    let duration: String
    let waterStay: String
    let bookingDateTime: String
    let voyagerPhone: String
    /// Firebase / chat peer user id (never the voyage id).
    let chatPeerUserId: String
}
