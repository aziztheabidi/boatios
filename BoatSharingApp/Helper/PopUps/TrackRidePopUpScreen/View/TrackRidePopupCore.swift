import SwiftUI
import Combine
import GoogleMaps

enum TrackRidePopupMode {
    case standard
    case autoSubmit
    case confirmation

    var title: String {
        switch self {
        case .standard:
            return "Please enter the pin:"
        case .autoSubmit, .confirmation:
            return "PIN for the Voyage is:"
        }
    }

    var heading: String {
        switch self {
        case .standard:
            return "Voyage from pickup to drop-off dock"
        case .autoSubmit:
            return "Meet at pickup point for your destination in a few minutes."
        case .confirmation:
            return "Voyage from pickup location to destination"
        }
    }

    var shouldAutoSubmit: Bool {
        self == .autoSubmit
    }

    var showActionButtons: Bool {
        self != .autoSubmit
    }
}

struct TrackRidePopupConfiguration {
    let mode: TrackRidePopupMode
    let isCaptain: Bool
    let currentUserId: String
    let details: VoyageBookingDetails

    static func captain(
        mode: TrackRidePopupMode,
        details: VoyageBookingDetails,
        currentUserId: String
    ) -> TrackRidePopupConfiguration {
        TrackRidePopupConfiguration(
            mode: mode,
            isCaptain: true,
            currentUserId: currentUserId,
            details: details
        )
    }
}

struct TrackRidePopupReusableView: View {
    @Binding var showSheet: Bool
    let configuration: TrackRidePopupConfiguration
    var onPinEntered: (String) -> Void
    var onDecline: (String) -> Void

    var body: some View {
        TrackRidePopupCore(
            showSheet: $showSheet,
            mode: configuration.mode,
            details: configuration.details,
            isCaptain: configuration.isCaptain,
            currentUserId: configuration.currentUserId,
            onPinEntered: onPinEntered,
            onDecline: onDecline
        )
    }
}

struct TrackRidePopupCore: View {
    @Binding var showSheet: Bool
    let mode: TrackRidePopupMode
    let details: VoyageBookingDetails
    let isCaptain: Bool
    let currentUserId: String
    var onPinEntered: (String) -> Void
    var onDecline: (String) -> Void

    @State private var enteredPin: [String] = Array(repeating: "", count: 5)
    @FocusState private var focusedField: Int?
    @StateObject private var viewModel = TrackRidePopupCoreViewModel()
    @StateObject private var keyboard = KeyboardObserver()

    var body: some View {
        NavigationStack {
            ZStack {
                MapsView()
                    .ignoresSafeArea()

                VStack(spacing: 8) {
                    Text(mode.heading)
                        .font(.headline)
                        .multilineTextAlignment(.leading)

                    Divider()

                    VStack(alignment: .leading) {
                        Text(mode.title)
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)

                        PinCodeInputView(digits: $enteredPin, focusedField: _focusedField)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .onChange(of: enteredPin) { _, _ in
                                if mode.shouldAutoSubmit {
                                    submitIfValid()
                                }
                            }
                    }

                    Divider()

                    riderInfoSection
                    chatButton

                    if mode.showActionButtons {
                        actionButtons
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(radius: 5)
                )
                .padding(.horizontal, 12)
                .padding(.bottom, keyboard.height == 0 ? 20 : keyboard.height - 20)
                .frame(maxHeight: .infinity, alignment: .bottom)

                if viewModel.isShowToast {
                    ToastView(message: viewModel.toastMsg, isPresented: $viewModel.isShowToast)
                        .transition(.scale)
                }

                if viewModel.showDeclineAlert {
                    AppConfirmationAlert(
                        message: "Are you sure you want to decline current voyage?",
                        isPresented: $viewModel.showDeclineAlert,
                        onConfirm: {
                            viewModel.confirmDecline(details: details, onDecline: onDecline)
                            showSheet = false
                        }
                    )
                    .transition(.scale)
                }
            }
            .fullScreenCover(item: $viewModel.chatSession) { session in
                CaptainChatView(
                    chatId: session.chatId,
                    currentUserId: session.currentUserId,
                    receiver: session.receiverUserId
                )
            }
            .onAppear {
                viewModel.handleAppear { focusedField = 0 }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var riderInfoSection: some View {
        HStack {
            HStack(spacing: 10) {
                Text(String(details.voyagerName.prefix(1)))
                    .font(.title)
                    .foregroundColor(.black)
                    .frame(width: 70, height: 70)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(details.voyagerName)
                        .font(.headline)
                    if isCaptain {
                        Text("$\(String(format: "%.2f", details.amountToPay))")
                            .font(.footnote)
                    } else {
                        Text("Exclusive")
                            .font(.footnote)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var chatButton: some View {
        Button {
            viewModel.handleChatTapped(currentUserId: currentUserId, chatPeerUserId: details.chatPeerUserId)
        } label: {
            Text("Connect with voyager?")
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 1)
                )
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.handleDeclineTapped()
            } label: {
                Text("Decline")
                    .fontWeight(.bold)
                    .foregroundColor(.AppColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.AppColor, lineWidth: 1)
                    )
            }

            Button {
                submitIfValid()
            } label: {
                Text("Accept")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.AppColor)
                    .cornerRadius(8)
            }
        }
    }

    private func submitIfValid() {
        if viewModel.submitPin(enteredPin, onPinEntered: onPinEntered) {
            showSheet = false
        }
    }
}

@MainActor
final class TrackRidePopupCoreViewModel: ObservableObject {
    struct State { let route: Route? }
    enum Action { case onAppear; case onDisappear }
    enum Route { case none }
    @Published var route: Route?
    var state: State { State(route: route) }
    func send(_ action: Action) {}
    struct ChatSession: Identifiable, Equatable {
        let id: String
        let chatId: String
        let currentUserId: String
        let receiverUserId: String
    }

    @Published var chatSession: ChatSession?
    @Published var showDeclineAlert = false
    @Published var isShowToast = false
    @Published var toastMsg = ""

    func handleAppear(_ focus: () -> Void) {
        focus()
    }

    func handleChatTapped(currentUserId: String, chatPeerUserId: String) {
        let selfId = currentUserId.trimmingCharacters(in: .whitespacesAndNewlines)
        let peerId = chatPeerUserId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !selfId.isEmpty, !peerId.isEmpty else {
            toastMsg = "Unable to open chat."
            isShowToast = true
            return
        }
        let chatId = ChatServiceViewModel.getOrCreateChatId(currentUserId: selfId, otherUserId: peerId)
        chatSession = ChatSession(id: chatId, chatId: chatId, currentUserId: selfId, receiverUserId: peerId)
    }

    func handleDeclineTapped() {
        showDeclineAlert = true
    }

    func confirmDecline(details: VoyageBookingDetails, onDecline: (String) -> Void) {
        onDecline(details.voyageID)
    }

    func submitPin(_ enteredPin: [String], onPinEntered: (String) -> Void) -> Bool {
        let pin = enteredPin.joined()
        guard pin.count == 5 else {
            toastMsg = "Please enter a 5-digit PIN"
            isShowToast = true
            return false
        }
        onPinEntered(pin)
        return true
    }
}

struct PinCodeInputView: View {
    @Binding var digits: [String]
    @FocusState var focusedField: Int?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<5, id: \.self) { index in
                TextField("", text: $digits[index])
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 50, height: 50)
                    .cornerRadius(10)
                    .focused($focusedField, equals: index)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                    .onChange(of: digits[index]) { _, newValue in
                        let filtered = String(newValue.filter { $0.isNumber }.prefix(1))
                        if filtered != newValue {
                            digits[index] = filtered
                            return
                        }
                        if filtered.count == 1 && index < 4 {
                            focusedField = index + 1
                        } else if filtered.isEmpty && index > 0 {
                            focusedField = index - 1
                        }
                    }
            }
        }
    }
}

struct AppConfirmationAlert: View {
    let message: String
    @Binding var isPresented: Bool
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 18) {
                Text(message)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)

                    Button("Confirm") {
                        isPresented = false
                        onConfirm()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.AppColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: 320)
            .background(Color.white)
            .cornerRadius(16)
        }
    }
}
