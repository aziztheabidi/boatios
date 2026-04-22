import SwiftUI

struct FutureVoyagesView: View {
    @StateObject private var viewModel: FutureVoyageViewModel
    @Environment(\.presentationMode) var presentationMode

    init(dependencies: AppDependencies = .live) {
        _viewModel = StateObject(wrappedValue: FutureVoyageViewModel(
            networkRepository: dependencies.networkRepository,
            identityProvider: dependencies.sessionPreferences
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                VStack(spacing: 0) {
                    topBar
                    voyageToggle

                    if viewModel.state.selectedSection == .unconfirmed {
                        pendingMessage
                    }

                    if viewModel.state.isFutureVoyageLoading {
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
                .blur(radius: viewModel.state.showPaymentPopup || viewModel.state.showCancelPopup ? 3 : 0)

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
                                viewModel.send(.payNow)
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

                if viewModel.state.showCancelPopup {
                    ConfirmAlertView(
                        message: "Are you sure, you want to cancel voyage?",
                        isPresented: $viewModel.showCancelPopup,
                        onConfirm: {
                            viewModel.send(.confirmCancel)
                        }
                    )
                }
            }
            .sheet(isPresented: $viewModel.showStripeSheet) {
                if let sheet = viewModel.makePaymentSheet() {
                    PaymentSheetWrapper(paymentSheet: sheet) { result in
                        viewModel.send(.handleStripeResult(result))
                    }
                }
            }
            .onAppear {
                viewModel.send(.onAppear)
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
                viewModel.send(.dismissForBackNavigation)
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
                viewModel.send(.selectSection(.unconfirmed))
            }) {
                Text("Unconfirmed")
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.state.selectedSection == .unconfirmed ? .white : Color.AppColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.state.selectedSection == .unconfirmed ? Color.AppColor : Color.white)
            }
            Button(action: {
                viewModel.send(.selectSection(.pending))
            }) {
                Text("Pending")
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.state.selectedSection == .pending ? .white : Color.AppColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.state.selectedSection == .pending ? Color.AppColor : Color.white)
            }
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 20)
    }

    private var pendingMessage: some View {
        let userName = viewModel.state.pendingInviteMessageUsername

        return Text("Hey \(userName), you're invited to sponsor the Voyage starting in a few minutes. Please pay now to confirm the voyage.")
            .foregroundColor(.black)
            .font(.subheadline)
            .padding()
            .transition(.opacity)
    }

    private var voyageList: some View {
        LazyVStack(spacing: 20) {
            if viewModel.state.selectedSection == .pending {
                let confirmedVoyages = viewModel.state.futureVoyageDetails?.confirmed ?? []
                if confirmedVoyages.isEmpty {
                    Text("No Pending Voyages")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(confirmedVoyages) { confirmedVoyage in
                        VStack(alignment: .leading, spacing: 8) {
                            FuturePaymentCard(
                                payment: confirmedVoyage,
                                isPending: false,
                                isLoading: viewModel.state.loadingVoyageId == confirmedVoyage.id && viewModel.state.isCancelling,
                                onPrimaryAction: {},
                                onIgnore: {
                                    viewModel.send(.presentCancelConfirmation(confirmedVoyage.id))
                                }
                            )
                            if let sponsors = confirmedVoyage.sponsors, !sponsors.isEmpty {
                                SponsorListView(sponsors: sponsors)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                            }
                        }
                    }
                }
            } else {
                if let pendingVoyage = viewModel.state.futureVoyageDetails?.unConfirmed, !pendingVoyage.id.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        FuturePaymentCard(
                            payment: pendingVoyage,
                            isPending: true,
                            isLoading: viewModel.state.loadingVoyageId == pendingVoyage.id && (viewModel.state.isConfirming || viewModel.state.isCancelling),
                            onPrimaryAction: {
                                viewModel.send(.pendingPrimaryConfirm(pendingVoyage.id))
                            },
                            onIgnore: {
                                viewModel.send(.presentCancelConfirmation(pendingVoyage.id))
                            }
                        )
                        if let sponsors = pendingVoyage.sponsors, !sponsors.isEmpty {
                            SponsorListView(sponsors: sponsors)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        }
                    }
                } else {
                    Text("No data found")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
        }
    }
}

struct FuturePaymentCard: View {
    let payment: Voyage
    let isPending: Bool
    let isLoading: Bool
    let onPrimaryAction: () -> Void
    let onIgnore: () -> Void

    var gridItems: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }

    var infoBoxes: some View {
        Group {
            FutureInfoBox(icon: "NewSponsors", label: "Passengers", value: String(payment.noOfvoyagers))
            FutureInfoBox(icon: "Vector-3", label: "Pickup location", value: payment.pickupDock)
            FutureInfoBox(icon: "FilledDollar", label: "Amount", value: "$\(String(format: "%.2f", payment.amountToPay))")
            FutureInfoBox(icon: "Vector-4", label: "Drop-off", value: payment.dropOffDock)
            FutureInfoBox(icon: "Clock", label: "Duration", value: payment.duration)
            FutureInfoBox(icon: "Flag", label: "Stay", value: payment.waterStay)
        }
    }

    private var formattedBookingDate: String {
        if let date = ISO8601DateFormatter().date(from: payment.BookingDateTime) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return payment.BookingDateTime
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.name)
                    .foregroundColor(.black)
                    .font(.system(size: 19, weight: .bold))
                Text(formattedBookingDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text("Voyager details")
                .font(.subheadline)
                .foregroundColor(.gray)

            LazyVGrid(columns: gridItems, spacing: 12) {
                infoBoxes
            }

            VStack(spacing: 12) {
                Button(action: {
                    if !isLoading {
                        onPrimaryAction()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text(isPending ? "Confirm Voyage" : String(payment.otp))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.AppColor, lineWidth: 1)
                )
                
                Button(action: {
                    if !isLoading { onIgnore() }
                }) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Cancel Voyage")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(Color.AppColor)
                    }
                }
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.AppColor, lineWidth: 1)
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
            .stroke(Color.AppColor, lineWidth: 2)
        )
        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct FutureInfoBox: View {
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
        .frame(height: 100)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SponsorListView: View {
    let sponsors: [Sponsor]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(sponsors.enumerated()), id: \.element.id) { index, sponsor in
                HStack {
                    Image("NewSponsors")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .scaledToFit()
                    Text(sponsor.VoyagerUserName)
                        .font(.subheadline)
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: sponsor.Status.lowercased() == "confirmed" ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(sponsor.Status.lowercased() == "confirmed" ? .green : .gray)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                
                if index < sponsors.count - 1 {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct ConfirmAlertView: View {
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


