import SwiftUI

enum TypeOfController {
    case SponsorPayment, VoyagerPayment
}

struct PaymentPopUpView: View {
    @StateObject private var viewModel: PaymentPopUpViewModel
    let type: TypeOfController
    let receiptEmail: String

    init(type: TypeOfController, receiptEmail: String = "") {
        self.type = type
        self.receiptEmail = receiptEmail
        _viewModel = StateObject(wrappedValue: PaymentPopUpViewModel(type: type))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Payment Successful Text
                Text("Payment Successful")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                // Image with Blue Background
                Image("payment_done")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding()
                
                // Confirmation Message
                Text("We have sent an email to \(receiptEmail.isEmpty ? "your email" : receiptEmail) with the receipt of this voyage")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Track Boat Button
                Button(action: {
                    viewModel.send(.primaryTapped)
                }) {
                    Text(viewModel.primaryButtonTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            
            NavigationLink(destination: VoyagerHomeView(), isActive: Binding(
                get: { viewModel.state.navigateToHome },
                set: { _ in }
            )) {
                EmptyView()
                    .navigationBarBackButtonHidden(true)
            }
            
            .navigationBarBackButtonHidden(true)
        }
    }
}
struct PaymentPopUpView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentPopUpView(type: .SponsorPayment, receiptEmail: "preview@example.com")
    }
}
