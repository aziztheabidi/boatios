import SwiftUI
import GoogleMaps

struct CaptainHomeVC: View {
    @StateObject private var viewModel: CaptainHomeViewModel
    @EnvironmentObject private var uiFlowState: UIFlowState
    @State private var showSheet = false
    @StateObject private var locationManager = LocationManager()

    init(dependencies: AppDependencies = .live) {
        _viewModel = StateObject(
            wrappedValue: CaptainHomeViewModel(
                preferences: dependencies.preferences,
                apiClient: dependencies.apiClient
            )
        )
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            MapsView()
                .edgesIgnoringSafeArea(.all)

            // Top icons HStack pinned to the top
            HStack {
                Button(action: {
                    viewModel.handleMenuTapped()
                    uiFlowState.showCaptainMenu = true
                    uiFlowState.showBusinessMenu = false
                }) {
                    Image("Group1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .padding(10)
                }
                .padding(.leading, 20)
                .padding(.top, 10) // Adjusted top padding to ensure it stays at the top

                Spacer()

                Button(action: {
                    viewModel.handleOfflinePromptShown()
                }) {
                    Image("wheel_active")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .padding(10)
                }
                .padding(.trailing, 20)
                .padding(.top, 10) // Adjusted top padding
            }
            .padding(.top, 50)
            .background(Color.clear) // Ensure it stays on top
            .zIndex(1) // Ensure it overlays the map

            // Offline Confirmation Popup
            if viewModel.showOfflinePopup {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(2)

                VStack(spacing: 20) {
                    Text("Are you going offline?")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding()

                    if viewModel.isUpdatingStatus {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                            .scaleEffect(1.5)
                            .padding()
                    } else {
                        HStack(spacing: 30) {
                            Button(action: {
                                viewModel.confirmGoOffline()
                            }) {
                                Text("OK")
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(width: 100)
                                    .background(Color.AppColor)
                                    .cornerRadius(10)
                            }

                            Button(action: {
                                viewModel.handleOfflinePromptDismissed()
                            }) {
                                Text("Not Now")
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(width: 100)
                                    .background(Color.gray)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                .frame(maxWidth: 300)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .zIndex(3) // Ensure it stays above other layers
            }

            // Welcome Screen
            if viewModel.showWelcomeScreen {
                ZStack {
                    Color.white.opacity(0.85)
                        .edgesIgnoringSafeArea(.all)
                        .blur(radius: 10)

                    VStack {
                        Spacer()

                        Text("Welcome Back")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)

                        Text("We are glad to see you again!\nPress on wheel to go online..")
                            .font(.body)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 10)

                        Button(action: {
                            viewModel.handleWelcomeWheelTapped()
                        }) {
                            ZStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                        .scaleEffect(1.5)
                                } else {
                                    Image(viewModel.isButtonBlue ? "wheel_active" : "wheel_inactive")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                }
                            }
                            .frame(width: 100, height: 100)
                            .shadow(radius: 5)
                        }
                        .padding(.top, 30)

                        Spacer()
                    }
                }
                .transition(.opacity)
                .zIndex(4) // Ensure it stays above other layers
            }

            // Navigation
            NavigationLink(destination: SpinWheelMenu(username: "Captain"), isActive: $viewModel.moveToMenu) {
                EmptyView()
            }
            .hidden() // Hide the link itself to avoid navigation bar interference
        }
        .ignoresSafeArea(.all, edges: [.top]) // Ignore top safe area to allow icons at the very top
        .navigationBarBackButtonHidden(true) // Explicitly hide back button
        .navigationBarHidden(true) // Hide the entire navigation bar
        .animation(.easeInOut, value: viewModel.showWelcomeScreen)
    }
}

// MARK: - Google Maps Wrapper View
struct MapsView: UIViewRepresentable {
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: 37.7749, longitude: -122.4194, zoom: 15.0)
        return GMSMapView.map(withFrame: .zero, camera: camera)
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {}
}

// MARK: - Preview
struct MapScreenView_Previews: PreviewProvider {
    static var previews: some View {
        CaptainHomeVC()
    }
}
