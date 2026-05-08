import SwiftUI
import GoogleMaps

struct PaymentPopupConfirmation: View {
    @Binding var showSheet: Bool
    let details: VoyageBookingDetails
    let currentUserId: String
    var onPinEntered: (String) -> Void
    var onDecline: (String) -> Void

    var body: some View {
        TrackRidePopupReusableView(
            showSheet: $showSheet,
            configuration: .captain(mode: .confirmation, details: details, currentUserId: currentUserId),
            onPinEntered: onPinEntered,
            onDecline: onDecline
        )
    }
}
struct PaymentPopupVC_Previews: PreviewProvider {
    static var previews: some View {
        PaymentPopupConfirmation(
            showSheet: .constant(true),
            details: VoyageBookingDetails(
                voyageID: "v1",
                voyagerName: "Voyager",
                voyagerCount: 2,
                pickupDock: "Dock A",
                dropOffDock: "Dock B",
                amountToPay: 25,
                duration: "1h",
                waterStay: "No",
                bookingDateTime: "Today",
                voyagerPhone: "000",
                chatPeerUserId: "voyager-user-1"
            ),
            currentUserId: "captain-1",
            onPinEntered: { pin in
            },
            onDecline: { id in
            }
        )
    }
}
