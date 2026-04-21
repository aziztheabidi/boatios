import SwiftUI

struct DeclineAlertView: View {
    @Binding var isPresented: Bool
    var message: String
    var onConfirm: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background (tappable)
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                        isPresented = false
                    
                }

            // Alert box
            VStack(spacing: 20) {
                Text("Alert")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)

                HStack(spacing: 12) {
                    Button {
                            isPresented = false
                        
                        onConfirm()
                    } label: {
                        Text("OK")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button {
                            isPresented = false
                        
                    } label: {
                        Text("Cancel")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                }
            }
            .padding()
            .frame(width: 300)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
}

struct NewRequestPopUpVC: View {
    @Binding var showSheet: Bool
    let voyage: VoyagerVoyage
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToTrack: Bool = false
    @State private var navigateToPayment: Bool = false
    @State private var Paymenttype: TypeOfController?

    @StateObject var viewModel: NewRequestPopUpViewModel

    init(showSheet: Binding<Bool>, voyage: VoyagerVoyage, dependencies: AppDependencies = .live) {
        _showSheet = showSheet
        self.voyage = voyage
        _viewModel = StateObject(wrappedValue: NewRequestPopUpViewModel(
            apiClient: dependencies.apiClient,
            sessionPreferences: dependencies.sessionPreferences
        ))
    }
    @State private var stripeSheet: PaymentSheet?
    @State private var showStripeSheet = false
    @State private var paymentResultMessage: String?
    @State private var paymentResult: PaymentSheetResult?

    @State private var isShowToast = false
    @State private var ToastMsg = ""
    @State private var VoyageID = ""
    @State private var paymentIntentID = ""
    @State private var intentID = ""

    @State private var displayDate: String = ""
    @State private var showDeclineAlert: Bool = false
    @State private var isLoadingPayment: Bool = false
    var body: some View {
        ZStack(alignment: .top) {
            popupContent

            if showDeclineAlert {
                DeclineAlertView(
                    isPresented: $showDeclineAlert,
                    message: "Are you sure you want to decline?",
                    onConfirm: {
                        withAnimation {
                            showDeclineAlert = false
                            showSheet = false
                        }
                    }
                )
                .zIndex(2)
                .transition(.scale)
            }

            if isShowToast {
                toastView
                    .zIndex(3)
            }
        }
    }

    // MARK: - Popup Content Split
    private var popupContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 50)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    headerSection
                    voyageDetailsSection
                    captainInfoSection
                    buttonsSection
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
        )
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            displayDate = "Today"
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                    Text(displayDate)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 25, height: 25)
                    Text("Accepted")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            Text(voyage.boatName)
                .font(.title)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
        }
    }

    // MARK: - Voyage Details Section
    private var voyageDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Voyagees detail")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    infoCard(image: "Vector-3", title: "Pickup", value: voyage.pickupDock)
                    infoCard(image: "Vector-4", title: "Drop-off", value: voyage.dropOffDock)
                }

                HStack(spacing: 10) {
                    infoCard(image: "Vector-2", title: "Passengers", value: "\(voyage.noOfVoyagers ?? 1) Passengers")
                    infoCard(image: "Dollar", title: "Price", value: String(format: "%.1f", voyage.amountToPay))
                }

                HStack(spacing: 10) {
                    infoCardSystem(icon: "clock", title: "Duration", value: voyage.duration ?? "")
                    infoCardSystem(icon: "water.waves", title: "Stay on water", value: voyage.waterStay ?? "")
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Captain Section
    private var captainInfoSection: some View {
        VStack {
            HStack(spacing: 15) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(Text("T").font(.title2).bold().foregroundColor(.black))

                VStack(alignment: .leading, spacing: 5) {
                    Text(voyage.captainName)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text("Top Rating Captain")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // ⭐️ Rating Section
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f", voyage.Rating))
                            .font(.subheadline)
                            .foregroundColor(.black)
                        
                        HStack(spacing: 2) {
                            ForEach(0..<1) { index in
                                Image(index < Int(voyage.Rating.rounded(.down)) ? "Docker" : "Docker")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                            }
                        }
                        
                        Text("| Rating")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                    VStack(alignment: .trailing) {
                        Image("Vector")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 5))

                        Text("Boat Name:\nSea Breeze")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.trailing, 8)
        
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(15)
        .padding(.horizontal)
        .padding(.top, 5)
    }

    // MARK: - Buttons
    private var buttonsSection: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation {
                    showDeclineAlert = true
                }
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .cornerRadius(10)
            }

            Button(action: handlePayNow) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue)
                        .frame(height: 55)

                    if isLoadingPayment {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(AppConfiguration.UserRole.normalize(AppSessionSnapshot.userRole) == AppConfiguration.UserRole.captain.rawValue ? "Accept" : "Pay Now")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }

    // MARK: - Pay Now Handler

    private func handlePayNow() {
        if AppConfiguration.UserRole.normalize(AppSessionSnapshot.userRole) == AppConfiguration.UserRole.captain.rawValue {
            navigateToTrack = true
        } else {
            isLoadingPayment = true
            VoyageID = voyage.id
            // Real flow: getPaymentIds → viewModel.PaymentData published → Stripe sheet opens
            viewModel.getPaymentIds(voyagerId: voyage.id)
        }
    }


    // MARK: - Toast
    private var toastView: some View {
        VStack {
            Spacer()
            Text(ToastMsg)
                .padding()
                .background(Color.AppColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.bottom, 40)
                .transition(.move(edge: .bottom))
                .onAppear {
                    viewModel.scheduleToastHide()
                }
        }
        .onChange(of: viewModel.toastMessage) { _, message in
            if let message {
                isLoadingPayment = false
                ToastMsg = message
                isShowToast = true
            }
        }
        .onChange(of: viewModel.shouldHideToast) { _, shouldHide in
            if shouldHide {
                withAnimation {
                    isShowToast = false
                }
            }
        }
    }

    // MARK: - Info Cards
    func infoCard(image: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
            }
            Text(value)
                .font(.subheadline)
                .foregroundColor(.black)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 85)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    func infoCardSystem(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
            }
            Text(value)
                .font(.subheadline)
                .foregroundColor(.black)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 85)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
