import SwiftUI

// MARK: - PastVoyagesView
struct PastVoyagesView: View {
    @StateObject private var viewModel: PastVoyageViewModel

    init(lastController: NSString, dependencies: AppDependencies = .live) {
        _viewModel = StateObject(wrappedValue: PastVoyageViewModel(
            networkRepository: dependencies.networkRepository,
            identityProvider: dependencies.sessionPreferences,
            initialRole: lastController as String
        ))
    }

    @Environment(\.presentationMode) var presentationMode
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    topBar
                    
                    if viewModel.isPastVoyageLoading {
                        Spacer()
                        ProgressView("Loading past voyages...")
                        Spacer()
                    } else if let errorMessage = viewModel.errorMessage {
                        Spacer()
                        Text("Error to fetch data")
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
            }
            .onAppear {
                viewModel.send(.onAppear)
            }
            .toast(isPresented: isShowToast, message: toastMessage, isSuccess: true)
            .navigationBarBackButtonHidden(true)
        }
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
            Text("Past Voyages")
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

    private var voyageList: some View {
        LazyVStack(spacing: 20) {
            if viewModel.selectedController == "Voyager" {
                if viewModel.pastVoyageDetails.isEmpty {
                    Text("No Past Voyages")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(viewModel.pastVoyageDetails) { voyage in
                        CaptainPastVoyageCard(
                            title: voyage.name,
                            dateTime: voyage.bookingDateTime,
                            primaryName: viewModel.preferredVoyagerName.isEmpty ? voyage.name : viewModel.preferredVoyagerName,
                            passengers: voyage.noOfVoyagers,
                            pickup: voyage.pickupDock,
                            dropOff: voyage.dropOffDock,
                            amount: voyage.amountToPay,
                            duration: voyage.duration,
                            stay: voyage.waterStay,
                            rating: voyage.rating
                        )
                    }
                }
            } else if viewModel.selectedController == "Captain" {
                if viewModel.CaptainpastVoyageDetails.isEmpty {
                    Text("No Past Voyages")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(viewModel.CaptainpastVoyageDetails) { voyage in
                        UnifiedPastVoyageCard(
                            title: voyage.name,
                            dateTime: voyage.bookingDateTime,
                            primaryName: voyage.voyagerName,
                            passengers: voyage.noOfVoyager,
                            pickup: voyage.pickupDock,
                            dropOff: voyage.dropOffDock,
                            amount: voyage.amountToPay,
                            duration: voyage.duration,
                            stay: voyage.waterStay,
                            rating: voyage.rating
                        )
                    }
                }
            }
        }
    }
}

// MARK: - UnifiedPastVoyageCard
struct UnifiedPastVoyageCard: View {
    let title: String
    let dateTime: String
    let primaryName: String
    let passengers: Int
    let pickup: String
    let dropOff: String
    let amount: Double
    let duration: String?
    let stay: String?
    let rating: String?

    var gridItems: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }

    private var formattedBookingDate: String {
        if let date = ISO8601DateFormatter().date(from: dateTime) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return dateTime
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Title + Date
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.black)
                    .font(.system(size: 19, weight: .bold))
                Text(formattedBookingDate)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundColor(.gray)
            }

            Text("Voyage details")
                .font(.subheadline)
                .foregroundColor(.black)

            LazyVGrid(columns: gridItems, spacing: 12) {
                PastInfoBox(icon: "NewSponsors", label: "Passengers", value: String(passengers))
                PastInfoBox(icon: "Vector-3", label: "Pickup location", value: pickup)
                PastInfoBox(icon: "FilledDollar", label: "Amount", value: "$\(String(format: "%.2f", amount))")
                PastInfoBox(icon: "Vector-4", label: "Drop-off", value: dropOff)

                // Duration always shown
                PastInfoBox(icon: "Clock", label: "Duration", value: (duration?.isEmpty == false ? duration! : "—"))
                
                // Stay on water only if present
                if let stay = stay, !stay.isEmpty {
                    PastInfoBox(icon: "Flag", label: "Water Stay", value: stay)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Voyager Name: \(primaryName)")
                    .font(.headline)
                    .foregroundColor(.black)
                
                
                if let ratingStr = rating,
                   let ratingInt = Int(ratingStr) {

                    HStack(spacing: 4) {
                        Image("Docker")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)

                        Text("Rating you gave:")

                        ForEach(0..<5) { index in
                            Image(systemName: index < ratingInt ? "star.fill" : "star")
                                .foregroundColor(index < ratingInt ? .yellow : .gray)
                                .font(.caption)
                        }
                    }

                } else {
                    HStack(spacing: 4) {
                        Image("Docker")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)

                        Text("No Rating Yet")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                
                
                
                
                
//                if let rating = rating {
//                    HStack(spacing: 4) {
//                        
//                        Image("Docker") // Replace with your asset's name
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 20, height: 20)
//                        
//                        Text("Rating you gave:")
//                        ForEach(0..<5) { index in
//                            Image(systemName: index < rating ? "star.fill" : "star")
//                                .foregroundColor(index < rating ? .yellow : .gray)
//                                .font(.caption)
//                        }
//                    }
//                }
//                else {
//                    HStack(spacing: 4) {
//                        Image("Docker") // Replace with your asset's name
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 20, height: 20)
//                        Text("No Rating Yet")
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                        
//                    }
//                }
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
// PastVoyage for voyager
struct CaptainPastVoyageCard: View{
    let title: String
    let dateTime: String
    let primaryName: String
    let passengers: Int
    let pickup: String
    let dropOff: String
    let amount: Double
    let duration: String?
    let stay: String?
    let rating: Int?

    var gridItems: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }

    private var formattedBookingDate: String {
        if let date = ISO8601DateFormatter().date(from: dateTime) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return dateTime
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Title + Date
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.black)
                    .font(.system(size: 19, weight: .bold))
                Text(formattedBookingDate)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundColor(.gray)
            }

            Text("Voyage details")
                .font(.subheadline)
                .foregroundColor(.black)

            LazyVGrid(columns: gridItems, spacing: 12) {
                PastInfoBox(icon: "NewSponsors", label: "Passengers", value: String(passengers))
                PastInfoBox(icon: "Vector-3", label: "Pickup location", value: pickup)
                PastInfoBox(icon: "FilledDollar", label: "Amount", value: "$\(String(format: "%.2f", amount))")
                PastInfoBox(icon: "Vector-4", label: "Drop-off", value: dropOff)

                // Duration always shown
                PastInfoBox(icon: "Clock", label: "Duration", value: (duration?.isEmpty == false ? duration! : "—"))
                
                // Stay on water only if present
                if let stay = stay, !stay.isEmpty {
                    PastInfoBox(icon: "Flag", label: "Water Stay", value: stay)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Voyager Name: \(primaryName)")
                    .font(.headline)
                    .foregroundColor(.black)
                
                
                if let ratingStr = rating {

                    HStack(spacing: 4) {
                        Image("Docker")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)

                        Text("Rating you gave:")

                        ForEach(0..<5) { index in
                            Image(systemName: index < ratingStr ? "star.fill" : "star")
                                .foregroundColor(index < ratingStr ? .yellow : .gray)
                                .font(.caption)
                        }
                    }

                } else {
                    HStack(spacing: 4) {
                        Image("Docker")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)

                        Text("No Rating Yet")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                
                
                
                
                
//                if let rating = rating {
//                    HStack(spacing: 4) {
//
//                        Image("Docker") // Replace with your asset's name
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 20, height: 20)
//
//                        Text("Rating you gave:")
//                        ForEach(0..<5) { index in
//                            Image(systemName: index < rating ? "star.fill" : "star")
//                                .foregroundColor(index < rating ? .yellow : .gray)
//                                .font(.caption)
//                        }
//                    }
//                }
//                else {
//                    HStack(spacing: 4) {
//                        Image("Docker") // Replace with your asset's name
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 20, height: 20)
//                        Text("No Rating Yet")
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//
//                    }
//                }
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










// MARK: - PastInfoBox
struct PastInfoBox: View {
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

// MARK: - Preview
struct PastVoyagesView_Previews: PreviewProvider {
    static var previews: some View {
        PastVoyagesView(lastController: "Voyager" as NSString)
    }
}



