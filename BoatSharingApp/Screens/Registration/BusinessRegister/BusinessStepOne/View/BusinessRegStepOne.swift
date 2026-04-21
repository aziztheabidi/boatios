
import SwiftUI
import MapKit
import CoreLocation

enum RegistrationType {
    case voyager, business, captain
}

struct BusinessRegStepOne: View {
    let registrationType: RegistrationType
    var lastController: NSString

    @StateObject private var viewModel: BusinessStepOneViewModel
    @State private var firstName = ""

    init(registrationType: RegistrationType, lastController: NSString, dependencies: AppDependencies = .live) {
        self.registrationType = registrationType
        self.lastController = lastController
        _viewModel = StateObject(wrappedValue: BusinessStepOneViewModel(
            apiClient: dependencies.apiClient,
            preferences: dependencies.preferences
        ))
    }
    @State private var lastName = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var dob: Date? = nil
    @State private var policyEmail = ""
    @State private var showDatePicker = false
    @State private var showToast = false
    @State private var showLocationPopup = false
    @State private var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // Default for map
    @State private var latitude: String = ""
    @State private var longitude: String = ""

    @Environment(\.presentationMode) var presentationMode
    @State private var errors: [String: String] = [:]

    var isFormValid: Bool {
        return !firstName.isEmpty && !lastName.isEmpty && isValidPhone(phone) &&
               !address.isEmpty && dob != nil && isValidEmail(policyEmail)
    }

    // Extracted: Loading state for SpinMenu
    private var loadingStateView: some View {
        Group {
            if lastController == "BusinessSpinMenu" {
                if viewModel.isBusniesProfileLoading {
                    ProgressView("Loading Business Profile...")
                        .padding()
                } else if let errorMessage = viewModel.ErrorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                } else if let profile = viewModel.BusinessProfile {
                    Text("Business Profile Loaded")
                        .foregroundColor(.gray)
                        .font(.caption)
                        .padding()
                }
            } else if lastController == "VoyagerSpinMenu" {
                if viewModel.isBusniesProfileLoading {
                    ProgressView("Loading Voyager Profile...")
                        .padding()
                } else if let errorMessage = viewModel.ErrorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                } else if let profile = viewModel.BusinessProfile {
                    // Empty for now
                }
            }
        }
    }

    // Extracted: Header section with back button and title
    private var headerView: some View {
        VStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "arrow.backward")
                    .foregroundColor(.black)
            }
            .padding(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(getTitleText())
                .padding(.top, -20)
        }
    }

    // Extracted: Progress bar for non-voyager types
    private var progressBarView: some View {
        Group {
            if registrationType != .voyager {
                HStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(index == 0 ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 35, height: 8)
                    }
                }
                .padding()
            }
        }
    }

    // Extracted: Form fields inside ScrollView
    private var formView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CustomLabeledTextField(label: "First Name", text: $firstName, error: $errors["firstName"])
                CustomLabeledTextField(label: "Last Name", text: $lastName, error: $errors["lastName"])
                CustomLabeledTextField(label: "Phone", text: $phone, error: $errors["phone"], isNumeric: true)

                // Address Field with Map Picker
                VStack(alignment: .leading, spacing: 5) {
                    Text("Address")
                        .foregroundColor(.gray)
                        .font(.caption)

                    HStack {
                        Text(address.isEmpty ? "Select Address" : address)
                            .foregroundColor(address.isEmpty ? .gray : .black)

                        Spacer()
                        Image(systemName: "mappin.circle")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8)
                        .stroke(errors["address"] == nil ? Color.gray.opacity(0.5) : Color.red, lineWidth: 1))
                    .onTapGesture {
                        showLocationPopup = true
                    }
                }
                .padding(.horizontal)

                if let addressError = errors["address"] {
                    Text(addressError).foregroundColor(.red).font(.caption)
                }

                // DOB Field with Calendar Icon
                VStack(alignment: .leading, spacing: 5) {
                    Text("Date of Birth")
                        .foregroundColor(.gray)
                        .font(.caption)

                    HStack {
                        Text(dob != nil ? formatDate(dob!) : "Select Date")
                            .foregroundColor(dob != nil ? .black : .gray)

                        Spacer()
                        Button(action: { showDatePicker.toggle() }) {
                            Image(systemName: "calendar")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8)
                        .stroke(errors["dob"] == nil ? Color.gray.opacity(0.5) : Color.red, lineWidth: 1))
                }
                .padding(.horizontal)

                if let dobError = errors["dob"] {
                    Text(dobError).foregroundColor(.red).font(.caption)
                }

                CustomLabeledTextField(label: "Policy Email", text: $policyEmail, error: $errors["policyEmail"], isEmail: true)
            }
            .padding()
        }
    }

    // Extracted: Register button
    private var registerButtonView: some View {
        Button(action: {
            validateFields()
            if errors.isEmpty {
                registerUser()
            }
        }) {
            Text(registrationType == .voyager ? "Save and Proceed" : "Save and Proceed")
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.horizontal, 30)
        .disabled(!isFormValid)
    }

    // Extracted: Navigation links
    private var navigationLinksView: some View {
        Group {
            if lastController == "BusinessSpinMenu" {
                NavigationLink(destination: BusinessRegStepTwo(lastController: "BusinessSpinMenu"), isActive: $viewModel.shouldNavigateBusiness) {
                    EmptyView().navigationBarBackButtonHidden(true)
                }
            } else {
                NavigationLink(destination: BusinessRegStepTwo(lastController: ""), isActive: $viewModel.shouldNavigateBusiness) {
                    EmptyView().navigationBarBackButtonHidden(true)
                }
            }
            
            NavigationLink(destination: VoyagerHomeView(), isActive: $viewModel.shouldNavigateVoyager) {
                EmptyView().navigationBarBackButtonHidden(true)
            }
        }
    }

    // Extracted: Loading overlay
    private var loadingOverlayView: some View {
        Group {
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                ProgressView("Processing...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            }
        }
    }

    // Extracted: Toast overlay
    private var toastOverlayView: some View {
        Group {
            if showToast {
                ToastView(message: viewModel.message, isPresented: $showToast)
                    .transition(.opacity)
                    .onAppear {
                        viewModel.scheduleToastHide()
                    }
            }
        }
        .animation(.easeInOut, value: showToast)
        .onChange(of: viewModel.shouldHideToast) { _, shouldHide in
            if shouldHide {
                withAnimation {
                    showToast = false
                }
                viewModel.shouldHideToast = false
            }
        }
    }

    // Extracted: Date picker sheet
    private var datePickerSheetView: some View {
        VStack {
            DatePicker("Select Date", selection: Binding(
                get: { dob ?? Date() },
                set: { dob = $0 }
            ), displayedComponents: .date)
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()

            Button("Done") {
                showDatePicker = false
            }
            .padding()
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                loadingStateView
                headerView
                progressBarView
                formView
                registerButtonView
                navigationLinksView
            }
            .overlay(loadingOverlayView)
            .overlay(toastOverlayView, alignment: .top)
            .sheet(isPresented: $showDatePicker) {
                datePickerSheetView
            }
            .sheet(isPresented: $showLocationPopup) {
                LocationPickerView(
                    coordinate: $coordinate,
                    address: $address,
                    latitude: $latitude,
                    longitude: $longitude
                )
                .presentationDetents([.medium, .large])
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if lastController == "BusinessSpinMenu" {
                let userId = AppSessionSnapshot.userID
                guard !userId.isEmpty else { return }
                viewModel.getBusinessProfile(userid: userId)
            } else if lastController == "VoyagerSpinMenu" {
                let userId = AppSessionSnapshot.userID
                guard !userId.isEmpty else { return }

                viewModel.GetVoyagerProfile(userid: userId)
            }
        }
        .onChange(of: viewModel.BusinessProfile) { _, newProfile in
            if let profile = newProfile {
                firstName = profile.firstName
                lastName = profile.lastName
                phone = profile.phoneNumber
                address = profile.address
                if profile.dateOfBirth != "0001-01-01" {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    if let date = formatter.date(from: profile.dateOfBirth) {
                        dob = date
                    }
                }
                policyEmail = profile.stripeEmail
            }
        }
    }

    // API Call
    func registerUser() {
        // Dismiss keyboard
        UIApplication.shared.dismissKeyboard()
        
        let userId = AppSessionSnapshot.userID
        guard !userId.isEmpty else { return }

        let userType: BusinessStepOneViewModel.UserType
        switch registrationType {
        case .voyager: userType = .voyager
        case .business: userType = .business
        case .captain: userType = .business
        }
        
        viewModel.registerUser(
            userType: userType,
            UserID: userId,
            Phone: phone,
            FirstName: firstName,
            LastName: lastName,
            Address: address,
            DOB: formatDate(dob ?? Date()),
            Email: policyEmail
        )
        showToast = true
    }

    func validateFields() {
        errors = [:]

        if firstName.isEmpty { errors["firstName"] = "First Name is required" }
        if lastName.isEmpty { errors["lastName"] = "Last Name is required" }
        if phone.isEmpty || !isValidPhone(phone) { errors["phone"] = "Enter a valid phone number" }
        if address.isEmpty { errors["address"] = "Address is required" }
        if dob == nil { errors["dob"] = "Date of Birth is required" }
        if policyEmail.isEmpty || !isValidEmail(policyEmail) { errors["policyEmail"] = "Enter a valid email" }
    }

    func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = "^[0-9]{10,15}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phone)
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func getTitleText() -> String {
        switch registrationType {
        case .voyager: return "Please Add Your Info"
        case .business: return "Please Add Business Info 1/4"
        case .captain: return "Captain Registration"
        }
    }
}



struct BusinessRegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        BusinessRegStepOne(registrationType: .voyager, lastController: "Business")
    }
}

