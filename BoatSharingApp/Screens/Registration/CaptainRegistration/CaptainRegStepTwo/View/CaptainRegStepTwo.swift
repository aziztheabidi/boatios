import SwiftUI

struct CaptainRegStepTwo: View {
    var lastController: NSString

    @StateObject private var viewModel: CaptainRegStepTwoViewModel

    init(lastController: NSString, dependencies: AppDependencies = .live) {
        self.lastController = lastController
        _viewModel = StateObject(wrappedValue: CaptainRegStepTwoViewModel(
            networkRepository: dependencies.networkRepository,
            sessionPreferences: dependencies.sessionPreferences
        ))
    }

    @State private var licenceNumber = ""
    @State private var licenceExpiration: Date?
    @State private var licenceType = ""
    @State private var insuranceCompany = ""
    @State private var policyNumber = ""
    @State private var policyExpiration: Date?

    @State private var errors: [String: String] = [:]
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var navigate = false
    @State private var showLicenceDatePicker = false
    @State private var showPolicyDatePicker = false

    var isFormValid: Bool {
        return !licenceNumber.isEmpty &&
               licenceExpiration != nil &&
               !licenceType.isEmpty &&
               !insuranceCompany.isEmpty &&
               !policyNumber.isEmpty &&
               policyExpiration != nil
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Top Bar with Back Button and Title
                HStack {
                    Button(action: {}) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                    Spacer()
                    Text("Add Company info 2/3")
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
                    Capsule().fill(Color.blue).frame(width: 40, height: 8)
                    Capsule().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 8)
                }
                .padding(.bottom, 20)
                
                // Scrollable Form Fields
                ScrollView {
                    VStack(spacing: 16) {
                        CustomLabeledTextField(label: "Licence Number", text: $licenceNumber, error: $errors["licenceNumber"])
                        
                        // Licence Expiration Date Field
                        datePickerField(label: "Licence Expiration", date: $licenceExpiration, showPicker: $showLicenceDatePicker, error: $errors["licenceExpiration"])

                        CustomLabeledTextField(label: "Licence Type", text: $licenceType, error: $errors["licenceType"])
                        CustomLabeledTextField(label: "Insurance Company", text: $insuranceCompany, error: $errors["insuranceCompany"])
                        CustomLabeledTextField(label: "Policy Number", text: $policyNumber, error: $errors["policyNumber"])
                        
                        // Policy Expiration Date Field
                        datePickerField(label: "Policy Expiration", date: $policyExpiration, showPicker: $showPolicyDatePicker, error: $errors["policyExpiration"])
                    }
                    .padding()
                }
                
                Spacer()
                
                // Save and Proceed Button
                Button(action: {
                    validateForm()
                    if isFormValid {
                        let userId = viewModel.sessionUserId
                        guard !userId.isEmpty else { return }
                        viewModel.CaptainDocument(
                            UserId: userId,
                            LicenseNumber: licenceNumber,
                            LicenseExpiration: formatDate(licenceExpiration),
                            TypeOfLicense: licenceType,
                            InsuranceCompany: insuranceCompany,
                            PolicyNumber: policyNumber,
                            PolicyExpiration: formatDate(policyExpiration)
                        )
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    } else {
                        Text("Save and Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
                .disabled(!isFormValid || viewModel.isLoading)
                .padding(.horizontal, 27)
            }
            .navigationDestination(isPresented: $viewModel.shouldNavigate) {
                
                if lastController == "CaptainProfileTwo" {
                    CaptainRegStepThree(lastController: "CaptainProfileThree")
                        .navigationBarBackButtonHidden(true)
                }
                else
                {
                    CaptainRegStepThree(lastController: "")
                        .navigationBarBackButtonHidden(true)
                }
                
                
            }
            
            .onAppear {
                if lastController == "CaptainProfileTwo" {
                    viewModel.getCaptainDocument()
                }
            }
            
            .onChange(of: viewModel.captainDocument) { _, profile in
                guard let profile = profile else { return }
                
                licenceNumber = profile.licenseNumber
                licenceExpiration = convertStringToDate(profile.licenseExpiration)
                licenceType = profile.typeOfLicense
                insuranceCompany = profile.insuranceCompany
                policyNumber = profile.policyNumber
                policyExpiration = convertStringToDate(profile.policyExpiration)
            }
            
            
            .overlay(toastView(), alignment: .bottom)
            .onChange(of: viewModel.message) { _, newMessage in
                if !newMessage.isEmpty {
                    toastMessage = newMessage
                    showToast = true
                    viewModel.scheduleToastHide()
                }
            }
            .onChange(of: viewModel.shouldHideToast) { _, shouldHide in
                if shouldHide {
                    showToast = false
                    viewModel.shouldHideToast = false
                }
            }
        }
    }
    
    // Date Picker Field (Same Look as Text Fields)
    @ViewBuilder
    private func datePickerField(label: String, date: Binding<Date?>, showPicker: Binding<Bool>, error: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: 010) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Text(date.wrappedValue != nil ? formatDate(date.wrappedValue) : "Select Date")
                    .foregroundColor(date.wrappedValue != nil ? .black : .gray)
                
                Spacer()
                
                Button(action: { showPicker.wrappedValue.toggle() }) {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(UIColor.white))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            if let errorMessage = error.wrappedValue {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .onTapGesture {
            showPicker.wrappedValue.toggle()
        }
        .sheet(isPresented: showPicker) {
            DatePicker("Select Date", selection: Binding(
                get: { date.wrappedValue ?? Date() },  // Default to today if nil
                set: { date.wrappedValue = $0 }
            ), displayedComponents: .date)
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .padding()
        }
    }
    private func convertStringToDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    // Format Date to String
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // Toast View
    @ViewBuilder
    private func toastView() -> some View {
        if showToast {
            Text(toastMessage)
                .padding()
                .background(viewModel.isSuccess ? Color.green.opacity(0.8) : Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.bottom, 50)
                .transition(.opacity)
        }
    }

    // Form Validation Function
    func validateForm() {
        errors.removeAll()
        
        if licenceNumber.isEmpty { errors["licenceNumber"] = "Licence Number is required." }
        if licenceExpiration == nil { errors["licenceExpiration"] = "Licence Expiration is required." }
        if licenceType.isEmpty { errors["licenceType"] = "Licence Type is required." }
        if insuranceCompany.isEmpty { errors["insuranceCompany"] = "Insurance Company is required." }
        if policyNumber.isEmpty { errors["policyNumber"] = "Policy Number is required." }
        if policyExpiration == nil { errors["policyExpiration"] = "Expiration of Policy is required." }
    }
}

#Preview {
    CaptainRegStepTwo(lastController: "CaptainProfileTwo")
}



