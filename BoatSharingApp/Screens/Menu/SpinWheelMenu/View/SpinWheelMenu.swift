import SwiftUI
import Combine

struct SpinWheelMenu: View {
    @EnvironmentObject private var appState: AppState
    private let dependencies: AppDependencies
    @StateObject private var viewModel: SpinWheelMenuViewModel

    /// Canonical role from persisted session (`AppState`), not a caller-supplied string.
    private var activeRole: String {
        AppConfiguration.UserRole.normalize(appState.userRole)
    }
    @State private var rotation: Angle = .zero
    @State private var lastRotation: Angle = .zero
    @State private var selectedItem: String? = nil
    @State private var showAlert: Bool = false
    @State private var navigateToLogin = false
    @State private var navigateToSponsorPayments = false
    @State private var navigateToUpcomingVoyages = false
    @State private var navigateToSponsorRelationship = false
    @State private var navigateToVoyagerChat = false
    @State private var navigateToSettings = false
    @State private var navigateToBusinessActiveVoyages = false
    @State private var navigateToBusinessVoyage = false
    @State private var navigateToCaptainActiveVoyages = false
    @State private var navigateToResetPassword = false
    @State private var navigateToCaptainProfile = false
    @State private var navigateToBusinessProfile = false
    @State private var navigateToVoyagerProfile = false
    @State private var selectedType: RegistrationType?
    @State private var navigateToTravelNow = false
    @State private var navigateToPastVoyages = false

    @State private var goToVoyagerDashboard = false
    @State private var goToCaptainDashboard = false
    @State private var goToBusinessDashboard = false

    
    
    let menuItems: [(name: String, image: String)] = [
        ("Logout", "logout"),
        ("Connect with Voyagers", "Connect_With_Voyagers"),
        ("Sponsors", "Connect_With_Sponsor"),
        ("upcoming Voyage", "UpcomingVoyage"),
        ("Past Voyage", "UpcomingVoyage"),
        ("Travel Now", "TravelNow"),
        ("Sponsors List", "NewSponsors"),
        ("Business", "TravelNow"),
        ("Setting", "Setting")
    ]

    let wheelSize: CGFloat = 220
    @Environment(\.presentationMode) var presentationMode

    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: SpinWheelMenuViewModel(sessionManager: dependencies.sessionManager)
        )
    }

    var filteredMenuItems: [(name: String, image: String)] {
        let normalizedUsername = activeRole
        if normalizedUsername == AppConfiguration.UserRole.captain.rawValue {
            return menuItems.filter {
                $0.name == "upcoming Voyage" || $0.name == "Past Voyage" ||
                $0.name == "Setting" || $0.name == "Logout"
            }
        } else if normalizedUsername == AppConfiguration.UserRole.business.rawValue {
            return menuItems.filter {
                $0.name == "upcoming Voyage" ||
                $0.name == "Setting" || $0.name == "Logout"
            }
        } else {
            return menuItems
        }
    }

    // Find the index of the item closest to 0 degrees (top center of screen)
    private var topItemIndex: Int {
        guard !filteredMenuItems.isEmpty else { return 0 }
        let itemAngle = 360.0 / Double(filteredMenuItems.count)
        let normalizedRotation = (rotation.degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let topAngle = 0.0 // Top center is 0 degrees
        var minAngleDiff = Double.infinity
        var closestIndex = 0

        for index in 0..<filteredMenuItems.count {
            let itemBaseAngle = Double(index) * itemAngle
            let itemCurrentAngle = (itemBaseAngle + normalizedRotation).truncatingRemainder(dividingBy: 360)
            let angleDiff = min(
                abs(itemCurrentAngle - topAngle),
                360 - abs(itemCurrentAngle - topAngle)
            )
            if angleDiff < minAngleDiff {
                minAngleDiff = angleDiff
                closestIndex = index
            }
        }
        return closestIndex
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                wheelView
                cancelButtonView
                navigationLinks
            }
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $navigateToSettings) {
                SettingsPopup(
                    onDismiss: { navigateToSettings = false },
                    navigateToResetPassword: $navigateToResetPassword,
                    navigateToCaptainProfile: $navigateToCaptainProfile,
                    navigateToBusinessProfile: $navigateToBusinessProfile,
                    navigateToVoyagerProfile: $navigateToVoyagerProfile,
                    selectedType: $selectedType
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
        }
    }

    private var backgroundView: some View {
        Image("arrow.left")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea(.all)
    }

    private var wheelView: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(gradient: Gradient(colors: [Color.white, Color.white.opacity(0.2)]),
                                   center: .center,
                                   startRadius: 0,
                                   endRadius: wheelSize)
                )
                .frame(width: wheelSize, height: wheelSize)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)

            Image("Union")
                .resizable()
                .scaledToFit()
                .frame(width: wheelSize, height: wheelSize)
                .rotationEffect(rotation)
                .gesture(
                    DragGesture(minimumDistance: 0) // Reduced minimum distance for responsiveness
                        .onChanged { value in
                            let center = CGPoint(x: wheelSize / 2, y: wheelSize / 2)
                            let startAngle = angleFromPoint(center: center, point: value.startLocation)
                            let currentAngle = angleFromPoint(center: center, point: value.location)
                            let angleDifference = currentAngle - startAngle
                            rotation = lastRotation + Angle.degrees(angleDifference)
                        }
                        .onEnded { _ in
                            lastRotation = rotation
                            snapToNearestItem()
                        }
                )

            // Wheel items
            ForEach(0..<filteredMenuItems.count, id: \.self) { index in
                let angle = Angle.degrees(Double(index) * (360.0 / Double(filteredMenuItems.count)))
                let item = filteredMenuItems[index]
                let isTopItem = index == topItemIndex

                WheelMenuItem(
                    title: item.name,
                    imageName: item.image,
                    angle: angle,
                    isSelected: isTopItem,
                    wheelRotation: rotation,
                    isTop: isTopItem
                )
                .onTapGesture {
                    if isTopItem {
                        handleSelection(for: item.name)
                    }
                }
            }

            // Center hub
            Circle()
                .fill(Color.white)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        }
        .frame(height: wheelSize)
    }

    private func handleSelection(for name: String) {
        if name == "Logout" {
            showAlert = true
            viewModel.logout()
            appState.syncFromStorage()
            navigateToLogin = true
        } else if name == "Connect with Voyagers" {
            navigateToVoyagerChat = true
        } else if name == "upcoming Voyage" {
            let normalizedUsername = AppConfiguration.UserRole.normalize(activeRole)
            if normalizedUsername == AppConfiguration.UserRole.captain.rawValue {
                navigateToCaptainActiveVoyages = true
            } else if normalizedUsername == AppConfiguration.UserRole.business.rawValue {
                navigateToBusinessActiveVoyages = true
            } else {
                navigateToUpcomingVoyages = true
            }
        } else if name == "Sponsors List" {
            navigateToSponsorRelationship = true
        } else if name == "Sponsors" {
            navigateToSponsorPayments = true
        } else if name == "Travel Now" {
            navigateToTravelNow = true
        } else if name == "Setting" {
            navigateToSettings = true
        } else if name == "Business" {
            navigateToBusinessVoyage = true
        } else if name == "Past Voyage" {
            navigateToPastVoyages = true
        }
    }

    private var cancelButtonView: some View {
        Button {
            handleCancelNavigation()
        } label: {
            Image("Cancel_menu")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .padding(10)
                .clipShape(Circle())
                .shadow(radius: 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .zIndex(1)
    }
    private func handleCancelNavigation() {
        let normalizedUsername = activeRole
        if normalizedUsername == AppConfiguration.UserRole.captain.rawValue {
            goToCaptainDashboard = true
        } else if normalizedUsername == AppConfiguration.UserRole.business.rawValue {
            goToBusinessDashboard = true
        } else {
            goToVoyagerDashboard = true
        }
    }

    private var navigationLinks: some View {
        Group {
            
            NavigationLink(
                destination: CaptainHomeVC(dependencies: dependencies),
                isActive: $goToCaptainDashboard
            ) { EmptyView() }

            NavigationLink(
                destination: DashboardVC(dependencies: dependencies),
                isActive: $goToBusinessDashboard
            ) { EmptyView() }

            NavigationLink(
                destination: VoyagerHomeView(dependencies: dependencies),
                isActive: $goToVoyagerDashboard
            ) { EmptyView() }

            
            NavigationLink(destination: SponsorPaymentsView(), isActive: $navigateToSponsorPayments) {
                EmptyView().navigationBarBackButtonHidden(true)
            }

            NavigationLink(destination: BusinessActiveVoyageView(dependencies: dependencies), isActive: $navigateToBusinessActiveVoyages) {
                EmptyView().navigationBarBackButtonHidden(true)
            }

            NavigationLink(destination: LoginScreenView(dependencies: dependencies), isActive: $navigateToLogin) {
                EmptyView().navigationBarBackButtonHidden(true)
            }

            NavigationLink(destination: FutureVoyagesView(dependencies: dependencies), isActive: $navigateToUpcomingVoyages) {
                EmptyView().navigationBarBackButtonHidden(true)
            }

            NavigationLink(destination: SponsorRelationshipView(dependencies: dependencies), isActive: $navigateToSponsorRelationship) {
                EmptyView().navigationBarBackButtonHidden(true)
            }

            NavigationLink(destination: CaptainActiveVoyageView(dependencies: dependencies), isActive: $navigateToCaptainActiveVoyages) {
                EmptyView().navigationBarBackButtonHidden(true)
            }

            NavigationLink(destination: VoyagerChatView(dependencies: dependencies), isActive: $navigateToVoyagerChat) {
                EmptyView().navigationBarBackButtonHidden(true)
            }

            NavigationLink(destination: TravelNowView(dependencies: dependencies), isActive: $navigateToTravelNow) {
                EmptyView().navigationBarBackButtonHidden(true)
            }

            NavigationLink(destination: BusinessVoyageView(dependencies: dependencies), isActive: $navigateToBusinessVoyage) {
                EmptyView().navigationBarBackButtonHidden(true)
            }

            NavigationLink(destination: ResetPasswordVC(dependencies: dependencies), isActive: $navigateToResetPassword) {
                EmptyView().navigationBarBackButtonHidden(true)
            }

            NavigationLink(destination: PastVoyagesView(lastController: activeRole as NSString, dependencies: dependencies), isActive: $navigateToPastVoyages) {
                EmptyView().navigationBarBackButtonHidden(true)
            }

            NavigationLink(
                destination: CaptainRegStepOne(lastController: "CaptainProfileOne", dependencies: dependencies),
                isActive: $navigateToCaptainProfile
            ) {
                EmptyView().navigationBarBackButtonHidden(true)
            }

            NavigationLink(
                destination: BusinessRegStepOne(registrationType: selectedType ?? .business, lastController: "BusinessSpinMenu", dependencies: dependencies),
                isActive: $navigateToBusinessProfile
            ) {
                EmptyView().navigationBarBackButtonHidden(true)
            }

            NavigationLink(
                destination: BusinessRegStepOne(registrationType: selectedType ?? .voyager, lastController: "VoyagerSpinMenu", dependencies: dependencies),
                isActive: $navigateToVoyagerProfile
            ) {
                EmptyView().navigationBarBackButtonHidden(true)
            }

            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Logout"),
                    message: Text("\(selectedItem ?? "") was done"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func angleFromPoint(center: CGPoint, point: CGPoint) -> Double {
        let deltaX = point.x - center.x
        let deltaY = point.y - center.y
        let angle = atan2(deltaY, deltaX) * 180 / .pi
        return angle < 0 ? angle + 360 : angle
    }

    private func snapToNearestItem() {
        guard !filteredMenuItems.isEmpty else { return }

        let normalizedDegrees = (rotation.degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let itemAngle = 360.0 / Double(filteredMenuItems.count)

        let closestIndex = Int(round(normalizedDegrees / itemAngle)) % filteredMenuItems.count
        let targetAngle = Angle.degrees(Double(closestIndex) * itemAngle)

        withAnimation(.easeInOut(duration: 0.3)) { // Smooth snapping animation
            rotation = targetAngle
            lastRotation = targetAngle
            selectedItem = filteredMenuItems[closestIndex].name
        }
    }
}


struct SettingsPopup: View {
    @EnvironmentObject private var appState: AppState
    var onDismiss: () -> Void
    @Binding var navigateToResetPassword: Bool
    @Binding var navigateToCaptainProfile: Bool
    @Binding var navigateToBusinessProfile: Bool
    @Binding var navigateToVoyagerProfile: Bool
    @Binding var selectedType: RegistrationType?

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        onDismiss()
                    }) {
                        Image("Cancel_menu")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                            .shadow(radius: 5)
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }

                Text("Settings")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.top, 10)

                VStack(spacing: 20) {
                    Button(action: {
                        navigateToResetPassword = true
                        onDismiss()
                    }) {
                        Text("Forgot Password")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                            )
                    }

                    Button(action: {
                        let normalizedUsername = AppConfiguration.UserRole.normalize(appState.userRole)
                        if normalizedUsername == AppConfiguration.UserRole.captain.rawValue {
                            navigateToCaptainProfile = true
                        } else if normalizedUsername == AppConfiguration.UserRole.business.rawValue {
                            selectedType = .business
                            navigateToBusinessProfile = true
                        } else {
                            selectedType = .voyager
                            navigateToVoyagerProfile = true
                        }
                        onDismiss()
                    }) {
                        Text("Edit Profile")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)

                Spacer()
            }
            .padding(.bottom, 40)
        }
        .ignoresSafeArea(.all, edges: .all)
    }
}

struct WheelMenuItem: View {
    var title: String
    var imageName: String
    var angle: Angle
    var isSelected: Bool
    var wheelRotation: Angle
    var isTop: Bool

    var body: some View {
        ZStack {
            // Invisible anchor for positioning and tap area
            Color.clear
                .frame(width: 80, height: 155)
                .offset(y: -155) // Position item outward from center
                .rotationEffect(angle + wheelRotation) // Move around wheel

            // Content (icon and text)
            VStack(spacing: 4) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
                    .padding(7)
                    .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
                    .clipShape(Circle())

                Text(title)
                    .font(.caption)
                    .bold()
                    .foregroundColor(isSelected ? .blue : .black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 80) // Ensure text fits without cropping
            }
            .frame(width: 80)
            .offset(y: -155) // Align with anchor
            .rotationEffect(-(angle + wheelRotation)) // Counter-rotate to stay upright
            .scaleEffect(isTop ? 1.2 : 1.0) // Zoom top item by 20%
            .animation(.easeInOut(duration: 0.3), value: isTop) // Smooth zoom animation
        }
    }
}

private final class SpinWheelPreviewSessionManager: SessionManaging {
    let eventPublisher = PassthroughSubject<SessionEvent, Never>()
    var accessToken: String? { "preview-access" }
    var refreshToken: String? { "preview-refresh" }
    func saveTokens(accessToken: String, refreshToken: String) {}
    func saveUserData(userID: String, username: String, email: String, role: String, missingStep: Int?) {}
    func clearTokens() {}
    func clearUserData() {}
    func refreshToken() async -> Bool { false }
    func hasValidSession() -> Bool { true }
    func logout() {}
}

struct SpinWheelMenu_Previews: PreviewProvider {
    static var previews: some View {
        let defaults = UserDefaults(suiteName: "SpinWheelMenuPreview")!
        defaults.removePersistentDomain(forName: "SpinWheelMenuPreview")
        let prefs = PreferenceStore(defaults: defaults)
        prefs.isLoggedIn = true
        prefs.userRole = "Voyager"
        prefs.missingStep = 0
        let appState = AppState(preferences: prefs, sessionManager: SpinWheelPreviewSessionManager())
        return SpinWheelMenu()
            .environmentObject(appState)
    }
}


