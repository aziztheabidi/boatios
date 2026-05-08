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
    /// Back-compat alias: some writers use `isSpendOnWater` - redirect here.
    var isSpendOnWater: Bool {
        get { isStayOnWater }
        set { isStayOnWater = newValue }
    }
}

@MainActor
final class UIFlowState: ObservableObject {
    // MARK: - Voyage and cross-screen flow state (transient, non-persisted)

    @Published var businessVoyageSelection: BusinessVoyageSelection?
    @Published var voyageDraft = VoyageDraft()
    @Published var isFindingBoat: Bool = false

    // MARK: - UI-only menu presentation state (transient)

    @Published var showCaptainMenu: Bool = false
    @Published var showBusinessMenu: Bool = false

    // MARK: - Navigation source hints (transient)

    /// Transient navigation flag: view arrived here via a Business Detail screen tap.
    /// NOT persisted - resets on every app launch automatically.
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
        resetVoyageFlowState()
        resetMenuState()
        resetTransientFlags()
    }

    private func resetVoyageFlowState() {
        clearBusinessSelection()
        voyageDraft = VoyageDraft()
        isFindingBoat = false
    }

    private func resetMenuState() {
        showCaptainMenu = false
        showBusinessMenu = false
    }
}

