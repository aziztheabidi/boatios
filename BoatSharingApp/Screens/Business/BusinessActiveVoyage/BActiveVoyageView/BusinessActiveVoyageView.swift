import SwiftUI

struct BusinessActiveVoyageView: View {
    @StateObject private var viewModel: BusinessActiveVoyageViewModel

    init(dependencies: AppDependencies = .live) {
        _viewModel = StateObject(wrappedValue: BusinessActiveVoyageViewModel(
            networkRepository: dependencies.networkRepository,
            sessionPreferences: dependencies.sessionPreferences
        ))
    }
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topBar
                pendingMessage

                if viewModel.state.isLoading {
                    Spacer()
                    ProgressView("Loading voyages...")
                    Spacer()
                } else if let errorMessage = viewModel.state.errorMessage {
                    Spacer()
                    Text("Error: No Data Found")
                        .foregroundColor(.red)
                        .padding()
                    Button("Retry") {
                        viewModel.send(.retry)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        voyageView
                            .padding(.top)
                    }
                }
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
            Text("Active Voyages")
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
        Text(viewModel.state.bannerMessage)
            .foregroundColor(.black)
            .font(.subheadline)
            .padding()
            .transition(.opacity)
    }

    private var voyageView: some View {
        LazyVStack(spacing: 12) {
            if viewModel.state.voyages.isEmpty {
                Text("No Active Voyages Available")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(viewModel.state.voyages) { voyage in
                    VoyageCard(voyage: voyage)
                }
            }
        }
    }
}


import SwiftUI

struct VoyageCard: View {
    let voyage: VoyageDetail

    var gridItems: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12), // Use flexible to adapt to available width
            GridItem(.flexible(), spacing: 12)
        ]
    }

    var infoBoxes: some View {
        Group {
            FutureInfoBoxactive(icon: "person.2", label: "Passengers", value: String(voyage.noOfVoyagers))
            FutureInfoBoxactive(icon: "mappin.and.ellipse", label: "Pickup location", value: voyage.pickupDock)
            FutureInfoBoxactive(icon: "mappin.circle", label: "Drop-off", value: voyage.dropOffDock)
            FutureInfoBoxactive(icon: "ferry", label: "Boat Name", value: voyage.boatName.isEmpty ? "N/A" : voyage.boatName)
            FutureInfoBoxactive(icon: "sailboat", label: "Boat Model", value: voyage.boatModel.isEmpty ? "N/A" : voyage.boatModel)
            FutureInfoBoxactive(icon: "phone", label: "Phone", value: voyage.voyagerPhoneNumber)
        }
    }

    private var formattedBookingDate: String {
        if voyage.bookingDateTime.lowercased() == "today" {
            return "Today"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM dd, yyyy h:mm a"
        if let date = formatter.date(from: voyage.bookingDateTime) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            outputFormatter.timeStyle = .short
            return outputFormatter.string(from: date)
        }
        return voyage.bookingDateTime
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(voyage.voyagerName)
                    .foregroundColor(.black)
                    .font(.system(size: 19, weight: .bold))
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formattedBookingDate)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    HStack(spacing: 5) {
                        Image(systemName: "circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.blue)
                        Text("Active")
                            .foregroundColor(.blue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }

            Text("Voyage details")
                .font(.subheadline)
                .foregroundColor(.gray)

            LazyVGrid(columns: gridItems, alignment: .center, spacing: 12) {
                infoBoxes
            }
            .frame(maxWidth: .infinity) // Ensure grid takes full width
        }
        .padding(12) // Reduced padding for tighter layout
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.blue, lineWidth: 2)
        )
        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 8) // Reduced horizontal padding
    }
}

struct FutureInfoBoxactive: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.gray)
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: true, vertical: true)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: true, vertical: true)
            }
            Spacer()
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 70) // Ensure full width of grid column
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ActiveVoyagesView_Previews: PreviewProvider {
    static var previews: some View {
        BusinessActiveVoyageView()
    }
}



