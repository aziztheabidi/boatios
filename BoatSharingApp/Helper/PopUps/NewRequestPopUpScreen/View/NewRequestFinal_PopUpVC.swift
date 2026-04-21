import SwiftUI

struct NewRequestFinal_PopUpVC: View {

    // MARK: - Injected

    @Binding var showSheet: Bool
    let voyage: VoyagerVoyage
    @StateObject var viewModel: NewRequestPopUpViewModel

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) private var openURL

    init(showSheet: Binding<Bool>, voyage: VoyagerVoyage, dependencies: AppDependencies = .live) {
        _showSheet = showSheet
        self.voyage = voyage
        _viewModel = StateObject(wrappedValue: NewRequestPopUpViewModel(
            apiClient: dependencies.apiClient,
            sessionPreferences: dependencies.sessionPreferences
        ))
    }

    // MARK: - Pure view state

    @State private var navigateToFeedback = false
    @State private var showDeclineAlert   = false

    // MARK: - Body

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

            // Toast driven entirely by ViewModel state
            if let message = viewModel.toastMessage, !message.isEmpty {
                toastView(message: message)
                    .zIndex(3)
            }

            NavigationLink(
                destination: VoyagerFeedbackView(voyageId: voyage.id, From: "Voyager"),
                isActive: $navigateToFeedback
            ) { EmptyView() }
        }
    }

    // MARK: - Popup content

    private var popupContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 50)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    headerSection
                    captainInfoSection
                    voyageDetailsSection
                    buttonsSection
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 25).fill(Color.white))
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            // Forward lifecycle event to ViewModel — view does not decide what happens next
            viewModel.send(.onAppear(voyageStatus: voyage.status))
        }
        .onChange(of: viewModel.shouldDismissPopupForCompletedVoyage) { _, newValue in if newValue { showSheet = false } }
        .onChange(of: viewModel.shouldNavigateToFeedbackForCompletedVoyage) { _, newValue in if newValue { navigateToFeedback = true } }
        .onChange(of: viewModel.shouldHideToast) { _, newValue in if newValue { /* nothing — toast visibility driven by toastMessage */ } }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Today").font(.subheadline).foregroundColor(.gray)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.blue).frame(width: 25, height: 25)
                    Text(voyage.status).font(.subheadline).foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            Text(voyage.boatName).font(.title).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
        }
    }

    // MARK: - Captain info

    private var captainInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Captain details").font(.headline).padding(.horizontal)

            HStack(spacing: 15) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(Text("C").font(.title2).bold().foregroundColor(.black))

                VStack(alignment: .leading, spacing: 5) {
                    Text(voyage.captainName).font(.headline).foregroundColor(.black)
                    Text("Top Rating Captain").font(.subheadline).foregroundColor(.gray)
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f", voyage.Rating))
                            .font(.subheadline).foregroundColor(.black)
                        HStack(spacing: 2) {
                            ForEach(0..<1) { index in
                                Image(index < Int(voyage.Rating.rounded(.down)) ? "Docker" : "Docker")
                                    .resizable().scaledToFit().frame(width: 18, height: 18)
                            }
                        }
                        Text("| Rating").font(.subheadline).foregroundColor(.gray)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Image("Vector").resizable().scaledToFit().frame(width: 50, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    Text(voyage.boatName).font(.footnote).fixedSize(horizontal: false, vertical: true)
                    Text(voyage.boatModel).font(.footnote).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.trailing, 8)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .padding(.horizontal)
            .padding(.top, 5)
        }
    }

    // MARK: - Voyage details

    private var voyageDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Voyagees detail").font(.headline).padding(.horizontal)
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    infoCard(image: "Vector-3", title: "Pickup",   value: voyage.pickupDock)
                    infoCard(image: "Vector-4", title: "Drop-off", value: voyage.dropOffDock)
                }
                HStack(spacing: 10) {
                    infoCard(image: "Vector-2", title: "Passengers", value: "\(voyage.noOfVoyagers ?? 1) Passengers")
                    infoCard(image: "Dollar",   title: "Price",      value: String(format: "%.1f", voyage.amountToPay))
                }
                HStack(spacing: 10) {
                    infoCardSystem(icon: "clock",        title: "Duration",      value: voyage.duration ?? "")
                    infoCardSystem(icon: "water.waves",  title: "Stay on water", value: voyage.waterStay ?? "")
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Buttons

    private var buttonsSection: some View {
        VStack {
            Button(action: openTermsAndConditions) {
                Text("Terms & Conditions")
                    .font(.footnote).foregroundColor(.gray).underline()
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }
        .padding(.bottom, 30)
    }

    private func openTermsAndConditions() {
        if let url = URL(string: AppConfiguration.Web.privacyPolicy) { openURL(url) }
    }

    // MARK: - Toast (driven purely by ViewModel)

    private func toastView(message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .padding()
                .background(Color.AppColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.bottom, 40)
                .transition(.move(edge: .bottom))
                .onAppear {
                    // Ask the ViewModel to schedule auto-hide
                    viewModel.send(.scheduleToastHide)
                }
        }
    }

    // MARK: - Info cards

    func infoCard(image: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(image).resizable().scaledToFit().frame(width: 20, height: 20)
                Text(title).font(.subheadline).foregroundColor(.gray)
                Spacer()
            }
            Text(value).font(.subheadline).foregroundColor(.black)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 85)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
    }

    func infoCardSystem(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icon).foregroundColor(.blue)
                Text(title).font(.subheadline).foregroundColor(.gray)
                Spacer()
            }
            Text(value).font(.subheadline).foregroundColor(.black)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 85)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
    }
}
