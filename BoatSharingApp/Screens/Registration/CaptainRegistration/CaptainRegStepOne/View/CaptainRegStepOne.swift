
import SwiftUI
import MapKit
import CoreLocation

struct CaptainRegStepOne: View {
    var lastController: NSString

    @StateObject private var viewModel: CaptainRegStepOneViewModel
    @State private var firstName = ""

    init(lastController: NSString, dependencies: AppDependencies = .live) {
        self.lastController = lastController
        _viewModel = StateObject(wrappedValue: CaptainRegStepOneViewModel(
            apiClient: dependencies.apiClient,
            sessionPreferences: dependencies.sessionPreferences
        ))
    }
    @State private var lastName = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var dob: Date? = nil
    @State private var paypalEmail = ""
    @State private var errors: [String: String] = [:]
    @State private var showDatePicker = false
    @State private var showToast = false
    @State private var showLocationPopup = false
    @State private var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // Default for map
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    
    @Environment(\.presentationMode) var presentationMode

    var isFormValid: Bool {
        return !firstName.isEmpty &&
               !lastName.isEmpty &&
               !phone.isEmpty &&
               !address.isEmpty &&
               dob != nil &&
               !paypalEmail.isEmpty &&
               isValidEmail(paypalEmail)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Top Bar with Back Button and Title
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                    Spacer()
                    Text("Add Account info 1/3")
                        .font(.headline)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "arrow.backward")
                            .opacity(0)
                    }
                }
                .padding()
                
                // Progress Indicator
                HStack(spacing: 8) {
                    Capsule().fill(Color.blue).frame(width: 40, height: 8)
                    Capsule().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 8)
                    Capsule().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 8)
                }
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 16) {
                        CustomLabeledTextField(label: "First Name", text: $firstName, error: $errors["firstName"])
                        CustomLabeledTextField(label: "Last Name", text: $lastName, error: $errors["lastName"])
                        CustomLabeledTextField(label: "Phone", text: $phone, error: $errors["phone"])
                        
                        // Address Field with Map Picker
                        VStack(alignment: .leading) {
                            Text("Address")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                            
                            HStack {
                                Text(address.isEmpty ? "Select Address" : address)
                                    .foregroundColor(address.isEmpty ? .gray : .black)
                                Spacer()
                                Image(systemName: "mappin.circle")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(errors["address"] != nil ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .onTapGesture {
                                showLocationPopup = true
                            }
                            
                            if let error = errors["address"] {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 16)
                            }
                        }
                        
                        // D.O.B Button (Opens DatePicker)
                        VStack(alignment: .leading) {
                            Text("D.O.B")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                            
                            Button(action: { showDatePicker = true }) {
                                HStack {
                                    Text(dobText()).foregroundColor(dob == nil ? .gray : .black)
                                    Spacer()
                                    Image(systemName: "calendar").foregroundColor(.blue)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(errors["dob"] != nil ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.horizontal)
                            }
                            
                            if let error = errors["dob"] {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 16)
                            }
                        }
                        
                        CustomLabeledTextField(label: "Paypal Email", text: $paypalEmail, error: $errors["paypalEmail"])
                    }
                    .padding()
                }
                
                Spacer()
                
                // Save and Proceed Button (Disabled if Form is Invalid)
                Button(action: {
                    validateForm()
                    let userId = AppSessionSnapshot.userID
                    if isFormValid {
                        guard !userId.isEmpty else { return }
                        viewModel.CaptainRegister(
                            UserID: userId,
                            Phone: phone,
                            FirstName: firstName,
                            LastName: lastName,
                            Address: address,
                            DOB: formatDate(dob ?? Date()),
                            Email: paypalEmail
                        )
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save and Proceed")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray)
                .cornerRadius(10)
                .shadow(radius: 5)
                .disabled(!isFormValid || viewModel.isLoading)
                .padding(.horizontal, 27)
            }
            .navigationDestination(isPresented: $viewModel.shouldNavigate) {
                if lastController == "CaptainProfileOne" {
                    CaptainRegStepTwo(lastController: "CaptainProfileTwo").navigationBarBackButtonHidden(true)
                } else {
                    CaptainRegStepTwo(lastController: "").navigationBarBackButtonHidden(true)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerView(selectedDate: $dob)
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
            .overlay(
                ToastView(message: viewModel.message, isPresented: $showToast)
                    .animation(.easeInOut, value: showToast)
            )
            .onChange(of: viewModel.message) { _, _ in
                showToast = true
                viewModel.scheduleToastHide()
            }
            .onChange(of: viewModel.errorMessage) { _, error in
                if let error = error {
                    showToast = true
                    viewModel.message = error
                    viewModel.scheduleToastHide()
                }
            }
            .onChange(of: viewModel.shouldHideToast) { _, shouldHide in
                if shouldHide {
                    showToast = false
                    viewModel.shouldHideToast = false
                }
            }
            .onAppear {
                if lastController == "CaptainProfileOne" {
                    viewModel.getCaptainProfileOne()
                }
            }
            .onChange(of: viewModel.captainProfile) { _, profile in
                if let profile = profile {
                    firstName = profile.firstName
                    lastName = profile.lastName
                    phone = profile.phoneNumber
                    address = profile.address.isEmpty ? "" : profile.address // Ensure API address is used
                    paypalEmail = profile.stripeEmail
                    if let date = parseDate(profile.dateOfBirth) {
                        dob = date
                    }
                    // Optionally set coordinate if profile contains lat/long
                    // if profile.latitude != 0, profile.longitude != 0 {
                    //     coordinate = CLLocationCoordinate2D(latitude: profile.latitude, longitude: profile.longitude)
                    //     latitude = String(profile.latitude)
                    //     longitude = String(profile.longitude)
                    // }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // Helper function to format the date for display
    private func dobText() -> String {
        if let dob = dob {
            return formatDate(dob)
        }
        return "Select Date of Birth"
    }

    // Function to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // Function to parse date from API string
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    // Form Validation Function
    func validateForm() {
        errors.removeAll()
        
        if firstName.isEmpty { errors["firstName"] = "First Name is required." }
        if lastName.isEmpty { errors["lastName"] = "Last Name is required." }
        if phone.isEmpty { errors["phone"] = "Phone number is required." }
        if address.isEmpty { errors["address"] = "Address is required." }
        if dob == nil { errors["dob"] = "Date of Birth is required." }
        
        if paypalEmail.isEmpty {
            errors["paypalEmail"] = "Paypal Email is required."
        } else if !isValidEmail(paypalEmail) {
            errors["paypalEmail"] = "Enter a valid email address."
        }
    }
    
    // Email Validation Function
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES[c] %@", emailRegex).evaluate(with: email)
    }
}

// Date Picker Sheet View
struct DatePickerView: View {
    @Binding var selectedDate: Date?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            DatePicker(
                "Select Date",
                selection: Binding(
                    get: { selectedDate ?? Date() },
                    set: { selectedDate = $0 }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            
            Button("Done") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding()
        }
    }
}



#Preview {
    CaptainRegStepOne(lastController: "CaptainProfileOne")
}
