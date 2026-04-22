import SwiftUI

struct VoyagerRateView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var uiFlowState: UIFlowState
    private let dependencies: AppDependencies
    var currentDate = Date()
    @State private var eventName: String = ""
    @State private var numberOfVoyagers: String = ""
    @State private var perHourRate: String = ""
    @State private var estimatedCost: String = ""
    @State private var pickUpLocation: String = ""
    @State private var dropOffLocation: String = ""
    @State private var splitPayment: Bool = false
    @State private var showPopup: Bool = false
    @State private var sponsors: String = ""
    @State private var numberOfSponsors: String = ""
    @State private var individuals: String = ""
    @State private var pickup: String = ""
    @State private var dropOff: String = ""
    @State private var sharePerSponsor: Double = 0.0
    @State private var pickupDockId: String = ""
    @State private var dropOffDockId: String = ""
    @State private var formattedDateForAPI: String = ""

    @State private var voyagerStartTime: String = ""
    @State private var voyagerEndTime: String = ""
    @State private var isStayOnWater: Bool = false
    @State private var voyagerEstimatedHours: Double = 0.0

    @State private var isTravelNow: Bool = false
    @StateObject private var viewModel: VoyagerRateViewModel
    var onSponsorsSelected: ([String]) -> Void
    @State private var showAddSponsors: Bool = false
    @State private var selectedSponsors: [String] = []

    @State private var showValidationError = false
    @State private var navigateToSponsorsInvitation: Bool = false
    @State private var bookingButtonTitle: String = ""

    var selectedSponsorIDs: [String] = []

    @State private var eventDisplayDate: String = ""
    @State private var selectedVoyagerId: String = ""

    @State private var navigateToDashboard: Bool = false

    let isSpendOnWater: Bool

    init(
        dependencies: AppDependencies = .live,
        onSponsorsSelected: @escaping ([String]) -> Void,
        selectedSponsorIDs: [String] = [],
        isSpendOnWater: Bool
    ) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: VoyagerRateViewModel(
            networkRepository: dependencies.networkRepository,
            sessionPreferences: dependencies.sessionPreferences
        ))
        self.onSponsorsSelected = onSponsorsSelected
        self.selectedSponsorIDs = selectedSponsorIDs
        self.isSpendOnWater = isSpendOnWater
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        // Top Bar
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "arrow.backward")
                                    .foregroundColor(.black)
                                    .font(.system(size: 20, weight: .medium))
                            }
                            
                            Spacer()
                            
                            Text("Create Voyager")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            // Empty to center the title
                            Spacer().frame(width: 20)
                        }
                        .padding()
                        
                        Spacer().frame(height: 20)
                        
                        HStack(alignment: .top) {
                            Text("Kindly fill in the relevant details for the voyage.")
                                .foregroundColor(.black)
                                .font(.headline)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            Text(eventDisplayDate)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(width: 80)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)
                        
                        // Name of the Event
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Name of the Event")
                                .foregroundColor(.black)
                                .font(.subheadline)
                            
                            HStack {
                                Image("BookingTime")
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                    .scaledToFit()
                                    .foregroundColor(.blue)
                                
                                TextField("Enter Event Name", text: $eventName)
                                    .padding(.leading, 8)
                                    .frame(height: 40)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 10)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // No. of Voyagers
                        VStack(alignment: .leading, spacing: 10) {
                            Text("No. of Voyagers")
                                .foregroundColor(.black)
                                .font(.subheadline)
                            
                            HStack {
                                Image("Person")
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(.blue)
                                    .scaledToFit()
                                
                                TextField("", text: $numberOfVoyagers)
                                    .padding(.leading, 8)
                                    .frame(height: 40)
                                    .disabled(true)
                                    .foregroundColor(.black)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 10)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Per Hour Rate
                        if isSpendOnWater {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Per Hour Rate")
                                    .foregroundColor(.black)
                                    .font(.subheadline)
                                
                                HStack {
                                    Image("Dollar")
                                        .resizable()
                                        .frame(width: 18, height: 18)
                                        .foregroundColor(.blue)
                                        .scaledToFit()
                                    
                                    TextField("", text: .constant(String(format: "%.2f", viewModel.perHourRate)))
                                        .padding(.leading, 8)
                                        .frame(height: 40)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 10)
                                .background(Color.white)
                                .cornerRadius(10)
                                .disabled(true)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        }
                        // Estimated Cost
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Estimated Cost")
                                .foregroundColor(.black)
                                .font(.subheadline)
                            
                            HStack {
                                Image("Dollar")
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(.blue)
                                
                                TextField("", text: .constant(String(format: "%.2f", viewModel.totalFare)))
                                    .padding(.leading, 8)
                                    .frame(height: 40)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 10)
                            .background(Color.white)
                            .disabled(true)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Pick Up Location
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Pick Up Location")
                                .foregroundColor(.black)
                                .font(.subheadline)
                            
                            HStack {
                                Image("Current")
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(.blue)
                                
                                TextField("Enter pick up location", text: $pickUpLocation)
                                    .padding(.leading, 8)
                                    .disabled(true)
                                    .frame(height: 40)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 10)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Drop Off Location
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Drop Off Location")
                                .foregroundColor(.black)
                                .font(.subheadline)
                            
                            HStack {
                                Image("Dropoff")
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(.blue)
                                
                                TextField("Enter drop off location", text: $dropOffLocation)
                                    .padding(.leading, 8)
                                    .frame(height: 40)
                                    .disabled(true)
                                
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 10)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Split Payment Toggle
                        HStack {
                            Text("Do you want to split payment?")
                                .foregroundColor(.black)
                                .font(.headline)
                            
                            Spacer()
                            
                            Toggle("", isOn: $splitPayment)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 10)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        Spacer()
                        
                        // Proceed Button
                        Button(action: {
                            showPopup = true
                        }) {
                            Text("Proceed")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        .alert(isPresented: $showValidationError) {
                            Alert(
                                title: Text("Missing Information"),
                                message: Text("Please fill in all required fields before proceeding."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                    }
                }
                
                // Popup with background blur
                if showPopup {
                    Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation {
                                showPopup = false
                            }
                        }
                    
                    VStack(spacing: 20) {
                        // Cancel / Remove Button at the top
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    showPopup = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                            .padding(.trailing, 20)
                            .padding(.top, 40)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 15) {
                            // Total Fare Field
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Total Fare")
                                    .foregroundColor(.black)
                                    .font(.subheadline)
                                
                                HStack {
                                    Image("Dollar")
                                        .resizable()
                                        .frame(width: 18, height: 18)
                                        .scaledToFit()
                                    TextField("", text: .constant(String(format: "%.2f", viewModel.totalFare)))
                                        .padding(.leading, 8)
                                        .frame(height: 40)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 10)
                                .background(Color.white)
                                .cornerRadius(10)
                                .disabled(true)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            
                            // Conditionally show only when splitPayment is ON
                            if splitPayment {
                                // Add Sponsors
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Add Sponsors")
                                        .foregroundColor(.black)
                                        .font(.subheadline)
                                    
                                    Button(action: {
                                        showAddSponsors = true
                                    }) {
                                        ZStack {
                                            // Center the icon in the frame
                                            Image(systemName: "plus.circle")
                                                .foregroundColor(.blue)
                                                .font(.title)
                                        }
                                        .frame(width: 50, height: 50)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Number of Sponsors
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Number of Sponsors")
                                        .foregroundColor(.black)
                                        .font(.subheadline)
                                    
                                    HStack {
                                        Image("Voya")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 18, height: 18)
                                        TextField("Enter number", text: $numberOfSponsors)
                                            .padding(.leading, 8)
                                            .frame(height: 40)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 10)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                    .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                                
                                // Individuals
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Individuals")
                                        .foregroundColor(.black)
                                        .font(.subheadline)
                                    
                                    HStack {
                                        Image("Voya")
                                            .resizable()
                                            .frame(width: 18, height: 18)
                                            .scaledToFit()
                                        
                                        TextField("Enter individual count", text: $individuals)
                                            .padding(.leading, 8)
                                            .frame(height: 40)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 10)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                    .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                            }
                            
                            // Pickup
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Pickup")
                                    .foregroundColor(.black)
                                    .font(.subheadline)
                                
                                HStack {
                                    Image("Current")
                                        .resizable()
                                        .frame(width: 18, height: 18)
                                        .scaledToFit()
                                    
                                    TextField("Enter pick up location", text: $pickUpLocation)
                                        .padding(.leading, 8)
                                        .frame(height: 40)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 10)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            
                            // Drop Off
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Drop Off")
                                    .foregroundColor(.black)
                                    .font(.subheadline)
                                
                                HStack {
                                    Image("Dropoff")
                                        .resizable()
                                        .frame(width: 18, height: 18)
                                        .scaledToFit()
                                    
                                    TextField("Enter drop off location", text: $dropOffLocation)
                                        .padding(.leading, 8)
                                        .frame(height: 40)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 10)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            
                            // Book Button
                            Button(action: {
                                if isTravelNow && !splitPayment {
                                    handleImmediateTravel()
                                } else {
                                    handleDelayTravel()
                                }
                            }) {
                                Text(bookingButtonTitle)
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .padding(.top, 20)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .frame(maxWidth: 400)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5).ignoresSafeArea())
                    .onTapGesture {
                        withAnimation {
                            showPopup = false
                        }
                    }
                }
                
                // Toast View for 400 error, centered on screen
                ToastView(message: viewModel.toastMessage, isPresented: $viewModel.showToast)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
                    .zIndex(2) // Ensure toast is above popup and other content
            }
            
            .onAppear {
                viewModel.getVoyagerRate(using: uiFlowState.voyageDraft)
                numberOfVoyagers = uiFlowState.voyageDraft.numberOfVoyagers
                pickUpLocation = uiFlowState.voyageDraft.pickupLocationName
                dropOffLocation = uiFlowState.voyageDraft.dropOffLocationName
                numberOfSponsors = String(self.selectedSponsors.count)
                isTravelNow = uiFlowState.voyageDraft.isTravelNow
                pickupDockId = uiFlowState.voyageDraft.pickupDockID
                dropOffDockId = uiFlowState.voyageDraft.dropOffDockID

                
                
                
                if !uiFlowState.voyageDraft.startDateISO8601.isEmpty,
                   let savedDate = ISO8601DateFormatter().date(from: uiFlowState.voyageDraft.startDateISO8601) {
                    // use savedDate here

                
                    eventDisplayDate = formatDate(savedDate)
                    formattedDateForAPI = formattedDate(savedDate)
                } else {
                    eventDisplayDate = "Not Set"
                }
                
                if isTravelNow && !splitPayment {
                    self.bookingButtonTitle = "Find Boat"
                    splitPayment = false // Default to off for Travel Now
                } else {
                    self.bookingButtonTitle = "Book Voyage"
                    splitPayment = true // Default to on for non-Travel Now
                    voyagerStartTime = uiFlowState.voyageDraft.startTime
                    voyagerEndTime = uiFlowState.voyageDraft.endTime
                    isStayOnWater = uiFlowState.voyageDraft.isStayOnWater
                    voyagerEstimatedHours = Double(uiFlowState.voyageDraft.estimatedHours) ?? 0.0

                    
                    
                    
                }
            }
            
            .onChange(of: viewModel.isFindBoat) { _, isFindBoat in
                if isFindBoat {
                    uiFlowState.isFindingBoat = true

                    navigateToDashboard = true
                }
            }
            
            .onChange(of: viewModel.isVoyageBooked) { _, isVoyagebooked in
                if isVoyagebooked {
                    selectedVoyagerId = viewModel.bookedVoyageId
                    navigateToSponsorsInvitation = true
                }
            }
            
            NavigationLink(destination: VoyagerHomeView(), isActive: $navigateToDashboard) {
                EmptyView()
                    .navigationBarBackButtonHidden(true)
            }
            
            NavigationLink(
                destination: SponsorsInvitationView(voyageId: selectedVoyagerId),
                isActive: $navigateToSponsorsInvitation
            ) {
                EmptyView()
                    .navigationBarBackButtonHidden(true)
            }
            
            NavigationLink(
                destination: AddSponsorsView(
                    dependencies: dependencies,
                    showAddSponsors: $showAddSponsors,
                    onSponsorsSelected: { sponsors in
                        self.selectedSponsors = sponsors
                        calculateShare()
                    }
                ),
                isActive: $showAddSponsors
            ) {
                EmptyView()
            }
        }
        .navigationBarHidden(true)
    }
    
    func handleImmediateTravel() {
        let userId = viewModel.sessionUserId
        guard !userId.isEmpty else {
            viewModel.toastMessage = "Missing user id."
            viewModel.showToast = true
            return
        }

        viewModel.findBoat(
            voyagerUserId: userId,
            pickupDockId: pickupDockId,
            dropOffDockId: dropOffDockId,
            estimatedCost: String(viewModel.totalFare),
            numberOfVoyagers: numberOfVoyagers,
            isImmediately: true,
            bookingDate: formattedDateForAPI,
            isSplitPayment: splitPayment,
            voyageCategoryID: Int(uiFlowState.voyageDraft.voyageCategoryID) ?? 0
        )
    }
    
    func handleDelayTravel() {
        let userId = viewModel.sessionUserId
        guard !userId.isEmpty else {
            viewModel.toastMessage = "Missing user id."
            viewModel.showToast = true
            return
        }

        viewModel.bookVoyage(
            voyagerUserId: userId,
            pickupDockId: pickupDockId,
            dropOffDockId: dropOffDockId,
            numberOfVoyagers: numberOfVoyagers,
            isImmediately: isTravelNow,
            bookingDate: eventDisplayDate,
            startTime: voyagerStartTime,
            endTime: voyagerEndTime,
            isStayOnWater: isStayOnWater,
            isSplitPayment: splitPayment,
            perHourRate: viewModel.perHourRate,
            durationInHours: voyagerEstimatedHours,
            numberOfSponsors: selectedSponsors.count,
            estimatedCost: viewModel.totalFare,
            individualAmount: Double(individuals) ?? 0.0,
            sponsors: selectedSponsors,
            voyageCategoryID: Int(uiFlowState.voyageDraft.voyageCategoryID) ?? 0
        )
    }
    
    func formatDate(_ date: Date?, format: String = "yyyy-MM-dd") -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    func calculateShare() {
        if self.selectedSponsors.count > 0 {
            sharePerSponsor = viewModel.totalFare / Double(self.selectedSponsors.count)
            
            individuals = String(format: "%.2f", sharePerSponsor) // "0.00"
            
        } else {
            sharePerSponsor = 0.0
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}


