import SwiftUI

struct SponsorPaymentInvitationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var NavToVoyager: Bool = false
    let VoyageID: String

    @StateObject var viewModel: NewRequestPopUpViewModel

    init(VoyageID: String, dependencies: AppDependencies = .live) {
        self.VoyageID = VoyageID
        _viewModel = StateObject(wrappedValue: NewRequestPopUpViewModel(
            apiClient: dependencies.apiClient,
            sessionPreferences: dependencies.sessionPreferences
        ))
    }
    @State private var Paymenttype: TypeOfController?
    @State private var stripeSheet: PaymentSheet?
      @State private var showStripeSheet = false
       @State private var paymentResultMessage: String?
    @State private var paymentResult: PaymentSheetResult?
    @State private var isShowToast = false
    @State private var ToastMsg = ""
    @State private var paymentIntentID = ""
    @State private var intentID = ""

    
    @State private var navigateToPayment = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Custom NavBar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                            .font(.title3)
                            .padding()
                    }

                    Spacer()

                    Text("Payment")
                        .font(.headline)
                        .foregroundColor(.black)

                    Spacer()

                    // Empty space to balance layout
                    Spacer().frame(width: 44)
                }

                Spacer()

                // Centered Image
                Image("BookingDone")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.top, 20)

                // Bold Title
                Text("Voyage Booked!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                // Subtext
                Text("Do you want to pay now?")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                // Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        NavToVoyager = true
                    }) {
                        Text("Later")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                            .cornerRadius(10)
                    }

                    Button(action: {
                        let userId = AppSessionSnapshot.userID
                        guard !userId.isEmpty else { return }
                        viewModel.getSponsorPaymentIds(voyagerId: VoyageID, sponsorId: userId, user: "SponsorUserId")

                    }) {
                        Text("Pay Now")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            
            .onChange(of: viewModel.PaymentConfirmed) { _, confirmed in
                            if confirmed {
                                navigateToPayment = true
                            }
                        }
            
            .onChange(of: viewModel.PaymentData) { _, data in
                        guard let secret = data?.clientSecret else { return }
                paymentIntentID = data?.PaymentIntentId ?? "ID"
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
                            
                            viewModel.sponsorPaymentSuccess(voyageId: VoyageID, PaymentIntentId: intentID)
                            viewModel.handleSponsorPaymentSuccessDelay(debugPaymentIntentId: paymentIntentID)
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
            
            
            
            
            
            NavigationLink(destination: PaymentPopUpVC(type: .SponsorPayment), isActive: $navigateToPayment) {
                EmptyView()
                    .navigationBarBackButtonHidden(true)
            }
            
            
            NavigationLink(destination: VoyagerHomeView(), isActive: $NavToVoyager) {
                EmptyView()
                    .navigationBarBackButtonHidden(true)
            }
            
            
            .padding()
            .background(Color.white.ignoresSafeArea())
        }
        .navigationBarHidden(true)

    }
}

#Preview {
    SponsorPaymentInvitationView(VoyageID: "sdfgsdghsdgbsdhnad")
}

