import SwiftUI

struct SponsorPaymentsView: View {
    @StateObject private var viewModel: SponsorsPaymentViewModel
    @Environment(\.dismiss) private var dismiss

    // Payment
    @StateObject var PaymentviewModel: NewRequestPopUpViewModel
    @State private var stripeSheet: PaymentSheet?
    @State private var paymentResult: PaymentSheetResult?

    init(dependencies: AppDependencies = .live) {
        _viewModel = StateObject(wrappedValue: SponsorsPaymentViewModel(
            apiClient: dependencies.apiClient,
            sessionPreferences: dependencies.sessionPreferences
        ))
        _PaymentviewModel = StateObject(wrappedValue: NewRequestPopUpViewModel(
            apiClient: dependencies.apiClient,
            sessionPreferences: dependencies.sessionPreferences
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        viewModel.send(.dismissScreen)
                    }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                            .padding(.leading)
                    }

                    Spacer()

                    Text("Sponsor Payment")
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
                .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField(
                        "Search by name",
                        text: Binding(
                            get: { viewModel.state.searchText },
                            set: { viewModel.send(.updateSearchText($0)) }
                        )
                    )
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)

                if viewModel.state.isLoading {
                    Spacer()
                    ProgressView("Loading sponsor payments...")
                    Spacer()
                } else if let error = viewModel.state.errorMessage {
                    Spacer()
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                    Button("Retry") {
                        viewModel.send(.retry)
                    }
                    Spacer()
                } else if viewModel.state.filteredPayments.isEmpty {
                    Spacer()
                    Text("No sponsor payments found.")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.state.filteredPayments) { payment in
                                SponsorPaymentCard(payment: payment, onPayNow: {
                                    viewModel.send(.requestPaymentIds(voyageId: payment.id, paymentViewModel: PaymentviewModel))
                                }, onIgnore: {
                                    viewModel.send(.dismissScreen)
                                })
                            }
                        }
                        .padding(.top)
                    }
                }
            }
            .onChange(of: PaymentviewModel.PaymentData) { _, data in
                guard let secret = data?.clientSecret else { return }
                let paymentIntentId = data?.PaymentIntentId ?? ""
                viewModel.send(.configureStripe(secret: secret, paymentIntentId: paymentIntentId))
                var config = PaymentSheet.Configuration()
                config.merchantDisplayName = "Boat Sharing"
                stripeSheet = PaymentSheet(paymentIntentClientSecret: secret, configuration: config)
            }
            .sheet(
                isPresented: Binding(
                    get: { viewModel.state.shouldPresentStripeSheet },
                    set: { if !$0 { viewModel.shouldPresentStripeSheet = false } }
                )
            ) {
                if let sheet = stripeSheet {
                    PaymentSheetWrapper(paymentSheet: sheet) { result in
                        paymentResult = result

                        switch result {
                        case .completed:
                            viewModel.send(.paymentCompleted)
                        case .canceled:
                            viewModel.send(.paymentCanceled)
                        case .failed(let error):
                            viewModel.send(.paymentFailed(error.localizedDescription))
                        }
                    }
                }
            }
            .onAppear {
                viewModel.send(.onAppear)
            }
            .onDisappear {
                viewModel.send(.onDisappear)
            }
            .onChange(of: viewModel.state.shouldDismissScreen) { _, shouldDismiss in
                guard shouldDismiss else { return }
                dismiss()
                viewModel.send(.clearDismissRequest)
            }
            NavigationLink(destination: PaymentPopUpVC(type: .SponsorPayment), isActive: $viewModel.shouldNavigateToSuccess) {
                EmptyView()
                    .navigationBarBackButtonHidden(true)
            }
            ToastView(message: viewModel.state.toastMessage, isPresented: $viewModel.isShowingToast)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct SponsorPaymentCard: View {
    let payment: SponsorPayment
    let onPayNow: () -> Void
    let onIgnore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(payment.name)
                    .foregroundColor(.black)
                    .font(.system(size: 19, weight: .bold))
                Spacer()
                HStack(spacing: 5) {
                    Image(payment.VoyageStatus == "Pending" ? "Pending" : "Success")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .scaledToFit()
                    Text(payment.VoyageStatus)
                        .foregroundColor(payment.VoyageStatus == "Pending" ? .blue : .green)
                        .font(.system(size: 14, weight: .semibold))
                }
            }

            Text("Voyager details")
                .font(.subheadline)
                .foregroundColor(.gray)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                InfoBox(icon: "NewSponsors", label: "Passengers", value: String(payment.noOfVoyagers))
                InfoBox(icon: "Vector-3", label: "Pickup location", value: payment.pickupDock)
                InfoBox(icon: "FilledDollar", label: "", value: "$\(String(format: "%.2f", payment.amountToPay))")
                InfoBox(icon: "Vector-4", label: "Drop-off", value: payment.dropOffDock)
                InfoBox(icon: "Clock", label: "", value: payment.duration)
                InfoBox(icon: "Flag", label: "", value: payment.waterStay)
            }

            HStack(spacing: 12) {
                Button(action: onIgnore) {
                    Text("Ignore")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.blue)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }

                Button(action: onPayNow) {
                    Text("Pay Now")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.blue, lineWidth: 2)
        )
        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct InfoBox: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(icon)
                .resizable()
                .frame(width: 25, height: 25)
                .scaledToFit()
                .padding(.top, 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, -10)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .frame(height: 100) // 👈 Set fixed height here
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

