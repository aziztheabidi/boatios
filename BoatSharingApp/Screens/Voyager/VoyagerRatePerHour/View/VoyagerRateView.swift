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
    @State private var totalFare: String = ""
    @State private var sharePerSponsor: Double = 0.0
    @State private var pickupid: String = ""
    @State private var dropOffid: String = ""
    @State private var FormatedDateforApi: String = ""
    
    // Book Voyage
    @State private var voyager_startTime: String = ""
    @State private var voyager_endTime: String = ""
    @State private var is_spend_on_water: Bool = false
    @State private var voyager_estimatedHours: Double = 0.0
   
    @State private var is_trave_now: Bool = false
    @StateObject private var viewModel: VoyagerRateViewModel
    var SponsorsSelecte: ([String]) -> Void // Closure to pass back selected sponsor IDs
    @State private var showAddSponsors: Bool = false
    @State private var selectedSponsors: [String] = []

    @State private var showValidationError = false
    @State private var SendRequestSplit: Bool = false
    @State private var SendRequest: Bool = false
    @State private var BookingButtonText: String = ""

    var selectedSponsorIDs: [String] = []

    // pre filled value s
    @State private var Eventdate: String = ""
    @State private var selectedVoyagerId: String = ""

    @State private var ShoowSponsors: Bool = false
    @State private var NavToDashboard: Bool = false

    let isSpendOnWater: Bool
    let BookNow: Bool

    init(
        dependencies: AppDependencies = .live,
        SponsorsSelecte: @escaping ([String]) -> Void,
        selectedSponsorIDs: [String] = [],
        isSpendOnWater: Bool,
        BookNow: Bool
    ) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: VoyagerRateViewModel(apiClient: dependencies.apiClient))
        self.SponsorsSelecte = SponsorsSelecte
        self.selectedSponsorIDs = selectedSponsorIDs
        self.isSpendOnWater = isSpendOnWater
        self.BookNow = BookNow
    }

    var body: some View {
        NavigationStack {
            ZStack { // Removed top alignment to allow centering
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
                            
                            Text(Eventdate)
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
                                
                                TextField("", text: .constant(String(format: "%.2f", viewModel.totalFair)))
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
                                    TextField("", text: .constant(String(format: "%.2f", viewModel.totalFair)))
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
                                if is_trave_now && !splitPayment {
                                    handleImmediateTravel()
                                } else {
                                    handleDelayTravel()
                                }
                            }) {
                                Text(BookingButtonText)
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
                is_trave_now = uiFlowState.voyageDraft.isTravelNow
                pickupid = uiFlowState.voyageDraft.pickupDockID
                dropOffid = uiFlowState.voyageDraft.dropOffDockID

                
                
                
                if !uiFlowState.voyageDraft.startDateISO8601.isEmpty,
                   let savedDate = ISO8601DateFormatter().date(from: uiFlowState.voyageDraft.startDateISO8601) {
                    // use savedDate here

                
                    Eventdate = formatDate(savedDate)
                    FormatedDateforApi = formattedDate(savedDate)
                } else {
                    Eventdate = "Not Set"
                }
                
                if is_trave_now && !splitPayment {
                    self.BookingButtonText = "Find Boat"
                    splitPayment = false // Default to off for Travel Now
                } else {
                    self.BookingButtonText = "Book Voyage"
                    splitPayment = true // Default to on for non-Travel Now
                    voyager_startTime = uiFlowState.voyageDraft.startTime
                    voyager_endTime = uiFlowState.voyageDraft.endTime
                    is_spend_on_water = uiFlowState.voyageDraft.isStayOnWater
                    voyager_estimatedHours = Double(uiFlowState.voyageDraft.estimatedHours) ?? 0.0

                    
                    
                    
                }
            }
            
            .onChange(of: viewModel.isFindBoat) { _, isFindBoat in
                if isFindBoat {
                    uiFlowState.isFindingBoat = true

                    NavToDashboard = true
                }
            }
            
            .onChange(of: viewModel.isVoyageBooked) { _, isVoyagebooked in
                if isVoyagebooked {
                    selectedVoyagerId = viewModel.BookedVoyageID
                    SendRequestSplit = true
                }
            }
            
            NavigationLink(destination: VoyagerHomeView(), isActive: $NavToDashboard) {
                EmptyView()
                    .navigationBarBackButtonHidden(true)
            }
            
            NavigationLink(
                destination: SponsorsInvitationView(VoyageID: selectedVoyagerId),
                isActive: $SendRequestSplit
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
        let userId = AppSessionSnapshot.userID
        guard !userId.isEmpty else {
            ToastMsg = "Missing user id."
            isShowToast = true
            return
        }

        viewModel.FindBoat_ApiCaAlling(
            VoyagerUserId: userId,
            PickupDockId: pickupid,
            DropOffDockId: dropOffid,
            EstimatedCost: String(viewModel.totalFair),
            NoOfVoyagers: numberOfVoyagers,
            IsImmediately: true,
            BookingDate: FormatedDateforApi,
            IsSplitPayment: splitPayment,
            voyageCategoryID: Int(uiFlowState.voyageDraft.voyageCategoryID) ?? 0
        )
    }
    
    func handleDelayTravel() {
        let userId = AppSessionSnapshot.userID
        guard !userId.isEmpty else {
            ToastMsg = "Missing user id."
            isShowToast = true
            return
        }

        viewModel.BookVoyage_ApiCalling(
            VoyagerUserId: userId,
            PickupDockId: pickupid,
            DropOffDockId: dropOffid,
            NoOfVoyagers: numberOfVoyagers,
            IsImmediately: is_trave_now,
            BookingDate: Eventdate,
            StartTime: voyager_startTime,
            EndTime: voyager_endTime,
            IsStayOnWater: is_spend_on_water,
            IsSplitPayment: splitPayment,
            PerHourRate: viewModel.perHourRate,
            DurationInHours: voyager_estimatedHours,
            numberOfSponsors: selectedSponsors.count,
            EstimatedCost: viewModel.totalFair,
            IndvidualAmount: Double(individuals) ?? 0.0,
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
            sharePerSponsor = viewModel.totalFair / Double(self.selectedSponsors.count)
            
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

struct SponsorModel: Codable {
    let VoyagerUserId: String
}
