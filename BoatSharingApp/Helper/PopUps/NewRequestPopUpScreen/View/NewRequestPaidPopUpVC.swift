import SwiftUI

struct NewRequestPaidPopUpVC: View {
    @Binding var showSheet: Bool
    let voyage: VoyagerVoyage
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToTrack: Bool = false
    @State private var navigateToPayment: Bool = false
    @State private var Paymenttype: TypeOfController?

    // Payment
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

    private var trackRideChatPeerUserId: String {
        let role = AppConfiguration.UserRole.normalize(AppSessionSnapshot.userRole)
        if role == AppConfiguration.UserRole.captain.rawValue {
            return (voyage.voyagerUserId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return voyage.captainUserId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trackRideDetails: VoyageBookingDetails {
        let role = AppConfiguration.UserRole.normalize(AppSessionSnapshot.userRole)
        let displayName: String
        if role == AppConfiguration.UserRole.captain.rawValue {
            displayName = (voyage.voyagerName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            displayName = voyage.captainName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return VoyageBookingDetails(
            voyageID: voyage.id,
            voyagerName: displayName,
            voyagerCount: voyage.noOfVoyagers ?? 1,
            pickupDock: voyage.pickupDock,
            dropOffDock: voyage.dropOffDock,
            amountToPay: voyage.amountToPay,
            duration: (voyage.duration ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            waterStay: (voyage.waterStay ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            bookingDateTime: (voyage.bookingDateTime ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            voyagerPhone: (voyage.voyagerPhoneNumber ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            chatPeerUserId: trackRideChatPeerUserId
        )
    }

    var body: some View {
        ZStack {
            // 🔹 Bottom Sheet Content
            VStack(spacing: 10) {
                // Top Wheel Logo
                VStack {
                    Image("Group1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                }
                .padding(.top, 30)
                
                // Date and Accepted
                HStack {
                    Text(displayDate)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .frame(width: 20, height: 20)
                        Text("Accepted")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    .padding(.trailing, 20)
                }
                
                // Voyage Name and Voyagees Detail
                Text(voyage.boatName)
                    .font(.title)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                Text("Voyagees detail")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Cards: First row - Pickup and Drop-off
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        // Pickup Card
                        VStack(spacing: 10) {
                            HStack {
                                Image("Vector-3")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("Pickup")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.bottom, 5)
                            Text(voyage.pickupDock)
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }
                        .frame(width: UIScreen.main.bounds.width / 2 - 20, height: 80)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Drop-off Card
                        VStack(spacing: 10) {
                            HStack {
                                Image("Vector-4")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("Drop-off")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.bottom, 5)
                            Text(voyage.dropOffDock)
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }
                        .frame(width: UIScreen.main.bounds.width / 2 - 20, height: 80)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Second row - Passengers and Price
                    HStack(spacing: 10) {
                        // Passengers Card
                        VStack(spacing: 10) {
                            HStack {
                                Image("Vector-2")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 35)
                                    .foregroundColor(.blue)
                                Text("Passengers")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.bottom, 5)
                            Text("\(voyage.noOfVoyagers ?? 1) Passengers")
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }
                        .frame(width: UIScreen.main.bounds.width / 2 - 20, height: 80)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Price Card
                        VStack(spacing: 10) {
                            HStack {
                                Image("Dollar")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                                Text("Price")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.bottom, 5)
                            Text(String(format: "%.1f", voyage.amountToPay))
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }
                        .frame(width: UIScreen.main.bounds.width / 2 - 20, height: 80)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Third row - Duration and Stay on Water
                    HStack(spacing: 10) {
                        // Duration Card
                        VStack(spacing: 10) {
                            HStack {
                                Image(systemName: "clock")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.blue)
                                Text("Duration")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.bottom, 5)
                            Text(voyage.duration ?? "")
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }
                        .frame(width: UIScreen.main.bounds.width / 2 - 20, height: 80)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Stay on Water Card
                        VStack(spacing: 10) {
                            HStack {
                                Image(systemName: "water.waves")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.blue)
                                Text("Stay on water")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.bottom, 5)
                            Text(voyage.waterStay ?? "")
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }
                        .frame(width: UIScreen.main.bounds.width / 2 - 20, height: 80)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.top, 5)
                
                // Captain Detail Container (Moved after cards, simplified)
                VStack {
                    HStack(spacing: 15) {
                        // Circle with first letter of captain's name
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                           // Text(String(voyage.captainName.prefix(1)).uppercased())
                            Text("T")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                        }
                        
                        // Captain name and "Top Rating Captain" text
                        VStack(alignment: .leading, spacing: 5) {
                            Text(voyage.captainName)
                                .font(.headline)
                                .foregroundColor(.black)
                            Text("Top Rating Captain")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 5) {
                                Text(String(format: "%.1f", voyage.Rating))
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Image("Docker")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                    .clipped()
                                Text("Rating")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                            }
                            
                        }
                        
                        Spacer()
                        
                        // Rating with Docker image and "Rating" text
                        VStack(alignment: .trailing, spacing: 5) {
                           
                            // Boat image and name
                            HStack(spacing: 5) {
                                Image("Vector") // Replace with actual boat image asset name
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                    .clipped()
                                Text(voyage.boatName)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Buttons: Decline & Accept
                HStack(spacing: 10) {
                    // Decline Button
                    Button(action: {
                        showSheet = false
                    }) {
                        Text("Decline")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(width: UIScreen.main.bounds.width / 2 - 20, height: 55)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                    
                    // Accept Button
                    Button(action: {
                        if AppConfiguration.UserRole.normalize(AppSessionSnapshot.userRole) == AppConfiguration.UserRole.captain.rawValue {
                            let currentUserId = AppSessionSnapshot.userID
                            guard !currentUserId.isEmpty else {
                                ToastMsg = "Missing user context"
                                isShowToast = true
                                return
                            }
                            guard !trackRideChatPeerUserId.isEmpty else {
                                ToastMsg = "Missing voyager account for this voyage."
                                isShowToast = true
                                return
                            }
                            navigateToTrack = true
                            navigateToPayment = false
                        } else {
                            navigateToTrack = false
                            VoyageID = voyage.id
                            viewModel.getPaymentIds(voyagerId: voyage.id)
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                                .frame(width: UIScreen.main.bounds.width / 2 - 20, height: 55)
                            
                            if viewModel.isPaymentLoaded && AppConfiguration.UserRole.normalize(AppSessionSnapshot.userRole) != AppConfiguration.UserRole.captain.rawValue {
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
                .padding(.top, 5)
                
                .onChange(of: viewModel.PaymentConfirmed) { _, confirmed in
                    if confirmed {
                        navigateToPayment = true
                    }
                }
                
                .onChange(of: viewModel.PaymentData) { _, data in
                    guard let secret = data?.clientSecret else { return }
                    paymentIntentID = secret
                    intentID = data?.PaymentIntentId ?? ""
                    var config = PaymentSheet.Configuration()
                    config.merchantDisplayName = "Boat Sharing"
                    stripeSheet = PaymentSheet(paymentIntentClientSecret: secret, configuration: config)
                    showStripeSheet = true
                }
                
                .sheet(isPresented: $showStripeSheet) {
                    if let sheet = stripeSheet {
                        PaymentSheetWrapper(paymentSheet: sheet) { result in
                            paymentResult = result
                            showStripeSheet = false
                            
                            switch result {
                            case .completed:
                                ToastMsg = "Payment successful"
                                isShowToast = true
                                viewModel.completeVoyagerPaymentAfterDelay(voyageId: VoyageID, paymentIntentId: intentID) {
                                    showSheet = false
                                }
                            case .canceled:
                                ToastMsg = "Payment canceled"
                                isShowToast = true
                            case .failed(let error):
                                ToastMsg = "Payment failed: \(error.localizedDescription)"
                                isShowToast = true
                            }
                        }
                    }
                }
                NavigationLink(
                    destination: TrackRidePopupVC(
                        showSheet: .constant(true),
                        details: trackRideDetails,
                        currentUserId: AppSessionSnapshot.userID,
                        onPinEntered: { pin in
                        },
                        onDecline: { voyageId in
                        }
                    ),
                    isActive: $navigateToTrack
                ) {
                    EmptyView()
                }
                .navigationBarBackButtonHidden(true)
                
                NavigationLink(destination: PaymentPopUpVC(type: .VoyagerPayment), isActive: $navigateToPayment) {
                    EmptyView()
                }
                .navigationBarBackButtonHidden(true)
                
                ToastView(message: ToastMsg, isPresented: $isShowToast)
                
                Spacer()
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                let calendar = Calendar.current
                //if calendar.isDateInToday(voyage.startDate) {
                    displayDate = "Today"
//                } else {
//                    let formatter = DateFormatter()
//                    formatter.dateStyle = .medium
//                    displayDate = formatter.string(from: voyage.startDate)
//                }
            }
        }
    }
}

