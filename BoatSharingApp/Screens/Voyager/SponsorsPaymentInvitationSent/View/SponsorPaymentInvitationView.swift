import SwiftUI

struct SponsorPaymentInvitationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToVoyagerHome: Bool = false
    let voyageId: String
    private let receiptEmail: String

    @StateObject var viewModel: NewRequestPopUpViewModel

    init(voyageId: String, dependencies: AppDependencies = .live) {
        self.voyageId = voyageId
        self.receiptEmail = dependencies.sessionPreferences.userEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        _viewModel = StateObject(wrappedValue: NewRequestPopUpViewModel(
            networkRepository: dependencies.networkRepository,
            sessionPreferences: dependencies.sessionPreferences
        ))
    }

    @State private var stripeSheet: PaymentSheet?
    @State private var showStripeSheet = false
    @State private var isToastPresented = false
    @State private var toastMessage = ""
    @State private var paymentIntentId = ""

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
                        navigateToVoyagerHome = true
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
                        let userId = viewModel.sessionUserId
                        guard !userId.isEmpty else { return }
                        viewModel.getSponsorPaymentIds(
                            voyagerId: voyageId,
                            sponsorId: userId,
                            user: BackendContractCoding.SponsorPaymentInitiateKey.sponsorUserIdCanonical
                        )
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

            .onChange(of: viewModel.state.paymentConfirmed) { _, confirmed in
                if confirmed {
                    navigateToPayment = true
                }
            }

            .onChange(of: viewModel.state.paymentData) { _, data in
                guard let secret = data?.clientSecret else { return }
                paymentIntentId = data?.paymentIntentId ?? ""
                var config = PaymentSheet.Configuration()
                config.merchantDisplayName = "Boat Sharing"
                stripeSheet = PaymentSheet(paymentIntentClientSecret: secret, configuration: config)
                showStripeSheet = true
            }

            .sheet(isPresented: $showStripeSheet) {
                if let sheet = stripeSheet {
                    PaymentSheetWrapper(paymentSheet: sheet) { result in
                        showStripeSheet = false

                        switch result {
                        case .completed:
                            toastMessage = "Payment successful"
                            isToastPresented = true
                            Task {
                                await viewModel.completeSponsorPaymentAfterDelay(
                                    voyageId: voyageId,
                                    paymentIntentId: paymentIntentId
                                )
                            }
                        case .canceled:
                            toastMessage = "Payment canceled"
                            isToastPresented = true
                        case .failed(let error):
                            toastMessage = "Payment failed: \(error.localizedDescription)"
                            isToastPresented = true
                        }
                    }
                }
            }

            NavigationLink(destination: PaymentPopUpVC(type: .SponsorPayment, receiptEmail: receiptEmail), isActive: $navigateToPayment) {
                EmptyView()
                    .navigationBarBackButtonHidden(true)
            }

            NavigationLink(destination: VoyagerHomeView(), isActive: $navigateToVoyagerHome) {
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
    SponsorPaymentInvitationView(voyageId: "sdfgsdghsdgbsdhnad")
}


