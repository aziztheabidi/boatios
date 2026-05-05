import Foundation
import Combine

/// In-memory **cross-screen flow** state only (SwiftUI `EnvironmentObject`). Not persisted; never read from
/// `UserDefaults` / Keychain. Reset on logout via `resetAfterLogout()` so booking / voyage UI is not rebuilt
/// from stale in-memory values for a different session.
struct BusinessVoyageSelection {
    enum VoyageType {
        case pickup
        case dropoff
    }

    let businessID: String
    let businessName: String
    let voyageType: VoyageType
}

struct VoyageDraft {
    var pickupDockID: String = ""
    var dropOffDockID: String = ""
    var pickupLocationName: String = ""
    var dropOffLocationName: String = ""
    var numberOfVoyagers: String = ""
    var voyageCategoryID: String = "0"
    var startDateISO8601: String = ""
    var startTime: String = "00:00"
    var endTime: String = "00:00"
    var estimatedHours: String = "0"
    var isTravelNow: Bool = false
    /// Whether the voyager wants to spend time on (stay on) water. Canonical name throughout the app.
    var isStayOnWater: Bool = false
    /// Back-compat alias: some writers use `isSpendOnWater` â€” redirect here.
    var isSpendOnWater: Bool {
        get { isStayOnWater }
        set { isStayOnWater = newValue }
    }
}

final class UIFlowState: ObservableObject {
    @Published var businessVoyageSelection: BusinessVoyageSelection?
    @Published var voyageDraft = VoyageDraft()
    @Published var isFindingBoat: Bool = false
    @Published var showCaptainMenu: Bool = false
    @Published var showBusinessMenu: Bool = false

    /// Transient navigation flag: view arrived here via a Business Detail screen tap.
    /// NOT persisted â€” resets on every app launch automatically.
    @Published var fromBusinessDetail: Bool = false

    func clearBusinessSelection() {
        businessVoyageSelection = nil
    }

    /// Call on app launch to guarantee transient flags start clean.
    func resetTransientFlags() {
        fromBusinessDetail = false
    }

    /// Clears voyage / booking flow state when the user logs out so nothing carries across sessions in-memory.
    func resetAfterLogout() {
        clearBusinessSelection()
        voyageDraft = VoyageDraft()
        isFindingBoat = false
        showCaptainMenu = false
        showBusinessMenu = false
        resetTransientFlags()
    }
}

