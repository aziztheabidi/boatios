import SwiftUI

struct TravelNowView: View {
    @StateObject private var viewModel: TravelNowViewModel
    @Environment(\.dismiss) private var dismiss

    init(dependencies: AppDependencies = .live) {
        _viewModel = StateObject(wrappedValue: TravelNowViewModel(
            networkRepository: dependencies.networkRepository,
            identityProvider: dependencies.sessionPreferences
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    topBar
                    pendingMessage

                    switch viewModel.state.mainPhase {
                    case .idle, .loading:
                        Spacer()
                        ProgressView("Loading voyage...")
                        Spacer()
                    case .noVoyageFound:
                        Spacer()
                        Text("No voyage found")
                            .foregroundColor(.red)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    case .voyageContent:
                        ScrollView {
                            voyageView
                                .padding(.top)
                        }
                    case .retryableError:
                        Spacer()
                        Text(viewModel.state.retryBannerMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            viewModel.send(.retry)
                        }
                        Spacer()
                    }
                }
                .blur(radius: viewModel.state.showPaymentPopup ? 3 : 0)

                if viewModel.state.showPaymentPopup {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("There is a missing payment from \"\(viewModel.state.displayUsername)\". Do you want to pay on their behalf?")
                            .font(.headline)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        HStack(spacing: 20) {
                            Button("Cancel") {
                                viewModel.send(.dismissPaymentPopup)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                            
                            Button("Pay Now") {
                                guard let travelNowVoyage = viewModel.state.travelNowData else { return }
                                viewModel.send(.payNow(travelNowVoyage.id))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.AppColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                    .frame(width: 300)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                    .transition(.scale)
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel.state.showStripeSheet },
                set: { if !$0 { } }
            )) {
                if let sheet = viewModel.makePaymentSheet() {
                    PaymentSheetWrapper(paymentSheet: sheet) { result in
                        viewModel.send(.handleStripeResult(result))
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
            ToastView(
                message: viewModel.state.toastMessage,
                isPresented: Binding(
                    get: { viewModel.state.isShowToast },
                    set: { if !$0 { viewModel.send(.dismissToast) } }
                )
            )
        }
        .navigationBarBackButtonHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button(action: {
                viewModel.send(.dismissScreen)
            }) {
                Image(systemName: "arrow.backward")
                    .font(.title3)
                    .foregroundColor(.black)
                    .padding(.leading)
            }
            Spacer()
            Text("Travel Now")
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

    private var pendingMessage: some View {
        return Group {
            if viewModel.state.showPendingSponsorInvite {
                Text("Hey \(viewModel.state.displayUsername), you're invited to sponsor this Voyage starting soon. Please pay now to confirm.")
                    .foregroundColor(.black)
                    .font(.subheadline)
                    .padding()
                    .transition(.opacity)
            }
        }
    }

    private var voyageView: some View {
        LazyVStack(spacing: 12) {
            if let travelNowVoyage = viewModel.state.travelNowData {
                TravelNowPaymentCard(
                    payment: travelNowVoyage,
                    isLoading: viewModel.state.loadingVoyageId == travelNowVoyage.id && (viewModel.state.isConfirming || viewModel.state.isCancelling),
                    onConfirm: {
                        viewModel.send(.confirmVoyage(travelNowVoyage.id))
                    },
                    onCancel: {
                        viewModel.send(.cancelVoyage(travelNowVoyage.id))
                    }
                )
            } else {
                Text("No Travel Now Voyage Available")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
}

struct TravelNowPaymentCard: View {
    let payment: TravelNowVoyage
    let isLoading: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var gridItems: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }

    var infoBoxes: some View {
        Group {
            FutureInfoBox(icon: "NewSponsors", label: "Passengers", value: String(payment.noOfVoyagers))
            FutureInfoBox(icon: "Vector-3", label: "Pickup location", value: payment.pickupDock)
            FutureInfoBox(icon: "FilledDollar", label: "Amount", value: "$\(String(format: "%.2f", payment.amountToPay))")
            FutureInfoBox(icon: "Vector-4", label: "Drop-off", value: payment.dropOffDock)
            FutureInfoBox(icon: "Clock", label: "Duration", value: payment.duration)
            FutureInfoBox(icon: "Flag", label: "Stay", value: payment.waterStay)
        }
    }

    private var formattedBookingDate: String {
        if let date = ISO8601DateFormatter().date(from: payment.bookingDateTime) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return payment.bookingDateTime
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(payment.name)
                    .foregroundColor(.black)
                    .font(.system(size: 19, weight: .bold))
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formattedBookingDate)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    HStack(spacing: 5) {
                        Image("Pending")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .scaledToFit()
                        Text("Pending")
                            .foregroundColor(.blue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }

            Text("Voyage details")
                .font(.subheadline)
                .foregroundColor(.gray)

            LazyVGrid(columns: gridItems, spacing: 12) {
                infoBoxes
            }

            VStack(spacing: 12) {
                Button(action: {
                    if !isLoading { onCancel() }
                }) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Cancel Voyage")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.blue)
                    }
                }
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 1)
                )

                Button(action: {
                    if !isLoading { onConfirm() }
                }) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Confirm Voyage")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.blue)
                .cornerRadius(10)
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



