import SwiftUI
import GoogleMaps

struct TrackRidePopupVC: View {
    @Binding var showSheet: Bool
    let details: VoyageBookingDetails
    let currentUserId: String
    var onPinEntered: (String) -> Void
    var onDecline: (String) -> Void

    var body: some View {
        TrackRidePopupReusableView(
            showSheet: $showSheet,
            configuration: .captain(mode: .standard, details: details, currentUserId: currentUserId),
            onPinEntered: onPinEntered,
            onDecline: onDecline
        )
    }
}
struct TrackRidePopupVC_Previews: PreviewProvider {
    static var previews: some View {
        // Example preview with mock closures
        TrackRidePopupVC(
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
final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0

    init() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.height = frame.height
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.height = 0
        }
    }
}
