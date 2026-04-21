import SwiftUI

struct CaptainActiveVoyageView: View {
    @StateObject private var viewModel: CaptainActiveVoyageViewModel

    init(dependencies: AppDependencies = .live) {
        _viewModel = StateObject(wrappedValue: CaptainActiveVoyageViewModel(
            apiClient: dependencies.apiClient,
            identityProvider: dependencies.sessionPreferences
        ))
    }
    @Environment(\.presentationMode) var presentationMode
    @State private var isShowToast: Bool = false
    @State private var ToastMsg: String = ""
    
    @State private var receivedPin: String?
    
    @State private var captainType: String = ""
    @State private var boatname: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                VStack(spacing: 0) {
                    topBar
                    voyageToggle
                    
                    if viewModel.state.isLoading {
                        Spacer()
                        ProgressView("Loading voyages...")
                        Spacer()
                    } else if let errorMessage = viewModel.state.voyageErrorMessage {
                        Spacer()
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                        Button("Retry") {
                            viewModel.send(.retry)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            voyageList
                                .padding(.top)
                        }
                    }
                }
                .blur(radius: isShowToast || viewModel.showCompletePopup || viewModel.showDeclineAlert ? 3 : 0) // Blur when any popup is shown
                
                // Toast Overlay
                if isShowToast {
                    ToastView(message: ToastMsg, isPresented: $isShowToast)
                        .transition(.scale)
                        .zIndex(1)
                }
                
                // Complete Voyage Popup
                if viewModel.showCompletePopup {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        VStack {
                            Text("Alert")
                                .font(.headline)
                                .padding(.top, 20)
                            Text("Are you sure, you want to complete voyage?")
                                .font(.subheadline)
                                .padding(.vertical, 10)
                            HStack(spacing: 10) {
                                Button(action: {
                                    viewModel.send(.cancelCompletePrompt)
                                }) {
                                    Text("Cancel")
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.blue, lineWidth: 1)
                                        )
                                }
                                Button(action: {
                                    viewModel.send(.confirmCompleteVoyage)
                                }) {
                                    Text("OK")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                        .frame(width: 300)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                    }
                    .zIndex(2)
                    .transition(.scale)
                }
                
                // Decline Confirmation Alert
                if viewModel.showDeclineAlert {
                    AppConfirmationAlert(
                        message: "Are you sure, want to decline current voyage?",
                        isPresented: $viewModel.showDeclineAlert,
                        onConfirm: {
                            viewModel.send(.confirmDeclineVoyage)
                        }
                    )
                    .zIndex(2)
                    .transition(.scale)
                }
            }
            .fullScreenCover(item: $viewModel.trackRideSession) { session in
                TrackRidePopupVC(
                    showSheet: Binding(
                        get: { viewModel.trackRideSession != nil },
                        set: { if !$0 { viewModel.send(.clearTrackRideSelection) } }
                    ),
                    details: session.details,
                    currentUserId: session.currentUserId,
                    onPinEntered: { pin in
                        receivedPin = pin
                        viewModel.send(.handleTrackRidePin(pin))
                    },
                    onDecline: { voyageId in
                        viewModel.send(.requestDeclineVoyage(voyageId))
                        viewModel.send(.clearTrackRideSelection)
                    }
                )
            }
            .alert(isPresented: $viewModel.isTokenExpired) {
                Alert(
                    title: Text("Session Expired"),
                    message: Text("Your session has expired. Please log in again."),
                    dismissButton: .default(Text("OK"), action: {
                        viewModel.send(.handleSessionExpiredAcknowledged)
                    })
                )
            }
            NavigationLink(destination: VoyagerFeedbackView(voyageId: viewModel.feedbackVoyageId,From: "Captain"), isActive: $viewModel.shouldNavigateToFeedback) {
                EmptyView()
                    .navigationBarBackButtonHidden(true)
            }
            NavigationLink(destination: LoginScreenView(), isActive: $viewModel.shouldNavigateToLogin) {
                EmptyView()
                    .navigationBarBackButtonHidden(true)
            }
            .onAppear {
                viewModel.send(.onAppear)
            }
            .onDisappear {
                viewModel.send(.onDisappear)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button(action: {
                viewModel.send(.onDisappear)
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "arrow.backward")
                    .foregroundColor(.black)
                    .padding(.leading)
            }
            Spacer()
            Text("Upcoming Voyages")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.black)
            Spacer()
            Image(systemName: "arrow.backward")
                .opacity(0)
                .padding(.trailing)
        }
        .padding(.vertical, 12)
        .background(Color.white)
    }

    private var voyageToggle: some View {
        HStack(spacing: 0) {
            Button(action: {
                viewModel.send(.selectSection(.pending))
            }) {
                Text("Pending")
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.state.selectedSection == .pending ? .white : .AppColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.state.selectedSection == .pending ? Color.AppColor : Color.white)
            }
            Button(action: {
                viewModel.send(.selectSection(.accepted))
            }) {
                Text("Accepted")
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.state.selectedSection == .accepted ? .white : .AppColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.state.selectedSection == .accepted ? Color.AppColor : Color.white)
            }
            Button(action: {
                viewModel.send(.selectSection(.started))
            }) {
                Text("Started")
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.state.selectedSection == .started ? .white : .AppColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.state.selectedSection == .started ? Color.AppColor : Color.white)
            }
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }
    
    private var voyageList: some View {
        LazyVStack(spacing: 12) {
            if viewModel.state.selectedSection == .pending {
                if viewModel.pendingVoyages.isEmpty {
                    Text("No Pending Voyages")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(viewModel.pendingVoyages, id: \.id) { pendingVoyage in
                        FutureVoyageCard(
                            voyage: pendingVoyage,
                            actionButtonText: "Accept",
                            onAction: {
                                viewModel.send(.accept(pendingVoyage))
                            },
                            secondButtonText: "Decline",
                            onSecondAction: {
                                viewModel.send(.requestDeclineVoyage(pendingVoyage.id))
                            }
                        )
                    }
                }
            } else if viewModel.state.selectedSection == .accepted {
                if viewModel.acceptedVoyages.isEmpty {
                    Text("No Accepted Voyages")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(viewModel.acceptedVoyages, id: \.id) { acceptedVoyage in
                        FutureVoyageCard(
                            voyage: acceptedVoyage,
                            actionButtonText: "Start Now",
                            onAction: {
                                viewModel.send(.prepareStartFlow(acceptedVoyage))
                            }
                        )
                    }
                }
            }
            
            else if viewModel.state.selectedSection == .started {
                if viewModel.startedVoyages.isEmpty {
                    Text("No Started Voyages")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(viewModel.startedVoyages, id: \.id) { startedVoyage in
                        FutureVoyageCard(
                            voyage: startedVoyage,
                            actionButtonText: "Complete Voyage",
                            onAction: {
                                viewModel.send(.requestCompleteVoyage(startedVoyage.id))
                            }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 10) // Add 10-point padding on leading and trailing edges
    }
}

struct FutureVoyageCard: View {
    var voyage: CaptainVoyage
    var actionButtonText: String
    var onAction: () -> Void
    var secondButtonText: String? = nil
    var onSecondAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date at top left
            Text(voyage.bookingDateTime)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Voyage name (bold, black)
            Text(voyage.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.top, -7)
            
            // "Voyage details" text (small, black, regular weight)
            Text("Voyage details")
                .font(.subheadline)
                .foregroundColor(.black)
                .padding(.top, -8)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                FutureInfoBox(icon: "NewSponsors", label: "Passengers", value: String(voyage.noOfVoyager))
                FutureInfoBox(icon: "Vector-3", label: "Pickup location", value: voyage.pickupDock)
                FutureInfoBox(icon: "FilledDollar", label: "Amount", value: "$\(String(format: "%.2f", voyage.amountToPay))")
                FutureInfoBox(icon: "Vector-4", label: "Drop-off", value: voyage.dropOffDock)
                FutureInfoBox(icon: "Clock", label: "Duration", value: voyage.duration ?? "2.0")
                FutureInfoBox(icon: "Flag", label: "Stay", value: voyage.waterStay)
            }

            HStack(spacing: secondButtonText != nil ? 10 : 0) {
                // Render Decline button first (on the left) if it exists
                if let secondText = secondButtonText, let onSecondAction = onSecondAction {
                    Button(action: onSecondAction) {
                        Text(secondText)
                            .fontWeight(.bold)
                            .foregroundColor(.AppColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.AppColor, lineWidth: 1)
                    )
                }
                
                // Render Accept button second (on the right)
                Button(action: onAction) {
                    Text(actionButtonText)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.AppColor)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.AppColor, lineWidth: 1)
        )
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct CaptainConfirmAlertView: View {
    let message: String
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            VisualEffectView(effect: UIBlurEffect(style: .dark))
                .ignoresSafeArea()
                .background(Color.black.opacity(0.4))
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 20) {
                Text("Alert")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.top, 15)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 15)
                
                HStack(spacing: 10) {
                    Button(action: {
                        isPresented = false
                        onConfirm()
                    }) {
                        Text("OK")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.leading, 10)
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                    .padding(.trailing, 10)
                }
                .padding(.bottom, 10)
            }
            .frame(width: 310, height: 280)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 5)
        }
    }
}
