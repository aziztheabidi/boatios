
import SwiftUI
import GoogleMaps

struct VoyagerHomeView: View {
    private let dependencies: AppDependencies
    @StateObject private var viewModel: VoyagerHomeViewModel
    @EnvironmentObject private var uiFlowState: UIFlowState
    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: VoyagerHomeViewModel(
            networkRepository: dependencies.networkRepository,
            identityProvider: dependencies.sessionPreferences
        ))
    }
    
    @State private var ShowToast: Bool = false
    @State private var ToastMsg: String = ""

    private func resetCaptainAndBusinessMenus() {
        uiFlowState.showCaptainMenu = false
        uiFlowState.showBusinessMenu = false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GoogleMapsView(docks: viewModel.state.docks)
                    .edgesIgnoringSafeArea(.all)
                
                // Existing main content
                VStack {
                    HStack {
                        Button(action: {
                            viewModel.send(.menuTapped(resetRoleMenus: resetCaptainAndBusinessMenus))
                        }) {
                            Image("Group1")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.black)
                                .padding(10)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding(.top, 5)
                        .padding(.leading, 20)
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.send(.findBoatTapped)
                    }) {
                        Image("Group1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.black)
                            .padding(10)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.bottom, 30)
                    
                    if viewModel.state.isVoyageLoading {
                        ProgressView("Loading...")
                    } else if viewModel.state.voyage != nil {
                        EmptyView()
                    } else if let error = viewModel.state.errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                    }
                }
            }
            
            .overlay {
                if viewModel.state.showFindBoatSheet {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    viewModel.send(.dismissFindBoat)
                                }
                            }

                        VStack(spacing: 0) {
                            Spacer()

                            ZStack(alignment: .top) {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.3), radius: 8)

                                FindBoatPopUpVC(
                                    showSheet: $viewModel.showFindBoatSheet,
                                    pickupLocation: $viewModel.pickupLocation,
                                    dropoffLocation: $viewModel.dropoffLocation,
                                    onNavigateToCreateVoyage: { viewModel.navigateToCreateVoyageAfterBooking() },
                                    dependencies: dependencies
                                )
                                .environmentObject(viewModel)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .transition(.move(edge: .bottom))
                                .animation(.easeInOut(duration: 0.3), value: viewModel.state.showFindBoatSheet)

                                Button(action: {
                                    withAnimation(.easeInOut) {
                                        viewModel.send(.dismissFindBoatToMenu(resetRoleMenus: resetCaptainAndBusinessMenus))
                                    }
                                }) {
                                    Image("Group1")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 70, height: 70)
                                        .background(Circle().fill(Color.white))
                                        .shadow(radius: 6)
                                }
                                .offset(y: -35)
                            }
                            .padding(.top, 100)
                        }
                        .background(Color.clear)
                        .ignoresSafeArea(edges: .bottom)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 0)
                    .zIndex(9999)
                    .animation(.easeInOut, value: viewModel.state.showFindBoatSheet)
                }
            }


            .overlay {
                if viewModel.state.isCaptainFind, let voyage = viewModel.state.voyage {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    viewModel.send(.dismissCaptainOverlay)
                                }
                            }

                        VStack(spacing: 0) {
                            Spacer()

                            ZStack(alignment: .top) {
                                NewRequestFinal_PopUpVC(showSheet: $viewModel.isCaptainFind, voyage: voyage)
                                    .ignoresSafeArea(.container, edges: .bottom)
                                    .shadow(color: .black.opacity(0.1), radius: 8, y: -3)
                                    .transition(.move(edge: .bottom))
                                    .animation(.easeInOut(duration: 0.3), value: viewModel.isCaptainFind)

                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        viewModel.send(.captainOverlayWheelTapped(resetRoleMenus: resetCaptainAndBusinessMenus))
                                    }
                                }) {
                                    Image("Group1")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 70, height: 70)
                                        .background(
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 60, height: 60)
                                        )
                                        .shadow(radius: 6)
                                }
                                .offset(y: -35)
                            }
                            .padding(.top, 50)
                        }
                        .ignoresSafeArea(edges: .bottom)
                    }
                }
            }
            .background(Color.clear)
            .navigationBarBackButtonHidden(true)
            .navigationDestination(item: $viewModel.stackDestination) { destination in
                switch destination {
                case .spinMenu:
                    SpinWheelMenu()
                case .createVoyage:
                    CreateVoyageView()
                case .login:
                    LoginScreenView()
                }
            }
            .alert(isPresented: $viewModel.isTokenExpired) {
                Alert(
                    title: Text("Session Expired"),
                    message: Text("Your session has expired. Please log in again."),
                    dismissButton: .default(Text("OK"), action: {
                        viewModel.send(.tokenExpiredAcknowledged)
                    })
                )
            }
            .overlay(
                ToastView(message: ToastMsg, isPresented: $ShowToast)
            )
            .onAppear {
                viewModel.send(.onAppear(uiFlowState))
            }

            .onDisappear {
                viewModel.send(.onDisappear)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

import SwiftUI
import GoogleMaps

struct GoogleMapsView: UIViewRepresentable {
    var docks: [DockLocation]
    
    func makeUIView(context: Context) -> GMSMapView {
        let defaultLatitude = 37.7749
        let defaultLongitude = -122.4194
        let defaultZoom: Float = 14.0
        
        let mapView = GMSMapView.map(
            withFrame: .zero,
            camera: GMSCameraPosition.camera(
                withLatitude: defaultLatitude,
                longitude: defaultLongitude,
                zoom: defaultZoom
            )
        )
        
        updateMarkers(on: mapView)
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        uiView.clear()
        updateMarkers(on: uiView)
    }
    
    // MARK: - Marker Logic
    private func updateMarkers(on mapView: GMSMapView) {
        let defaultLatitude = 37.7749
        let defaultLongitude = -122.4194
        let defaultZoom: Float = 14.0
        
        if let firstDock = docks.first,
           firstDock.latitude != 0,
           firstDock.longitude != 0 {
            // Move to first dock
            let camera = GMSCameraPosition.camera(
                withLatitude: firstDock.latitude,
                longitude: firstDock.longitude,
                zoom: defaultZoom
            )
            mapView.camera = camera
            
            // Add all docks markers
            for dock in docks {
                let marker = GMSMarker()
                marker.position = CLLocationCoordinate2D(latitude: dock.latitude, longitude: dock.longitude)
                marker.title = dock.name
                marker.icon = createMarkerIcon()
                marker.map = mapView
            }
        } else {
            // No valid dock, show default marker at default location.
            let camera = GMSCameraPosition.camera(
                withLatitude: defaultLatitude,
                longitude: defaultLongitude,
                zoom: defaultZoom
            )
            mapView.camera = camera
            
            let defaultMarker = GMSMarker()
            defaultMarker.position = CLLocationCoordinate2D(latitude: defaultLatitude, longitude: defaultLongitude)
            defaultMarker.title = "Default Dock"
            defaultMarker.icon = createMarkerIcon()
            defaultMarker.map = mapView
        }
    }
    
    // MARK: - Custom Marker Icon
    private func createMarkerIcon() -> UIImage? {
        if let image = UIImage(named: "Docker") {
            // Resize to make visible
            let size = CGSize(width: 45, height: 45)
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: size))
            let resized = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return resized
        }
        return UIImage(systemName: "mappin.circle.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
    }
}


