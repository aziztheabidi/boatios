import SwiftUI

struct BusinessRegStepTwo: View {
    @State private var businessName = ""
    @State private var businessType = ""
    @State private var businessAddress = ""
    @State private var businessPhoneNumber = ""
    @State private var businessYear = ""
    @State private var errors: [String: String] = [:]
    @State private var showYearPicker = false
    @State private var selectedYearValue = Calendar.current.component(.year, from: Date())
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: BusinessStepTwoViewModel
    @State private var showToast = false

    var lastController: NSString

    init(lastController: NSString, dependencies: AppDependencies = .live) {
        self.lastController = lastController
        _viewModel = StateObject(wrappedValue: BusinessStepTwoViewModel(apiClient: dependencies.apiClient))
    }

    var isFormValid: Bool {
        return errors.isEmpty && !businessName.isEmpty && !businessType.isEmpty && !businessAddress.isEmpty &&
               !businessPhoneNumber.isEmpty && !businessYear.isEmpty
    }

    var body: some View {
        NavigationView {
            VStack {
                // Back Button
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "arrow.backward")
                        .foregroundColor(.black)
                }
                .padding(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Please Add Business Info 2/4")
                    .padding(.top, -20)

                // Progress Indicators
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(index < 2 ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 35, height: 8)
                    }
                }
                .padding()

                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        CustomLabeledTextField(label: "Business Name", text: $businessName, error: $errors["BusinessName"])
                        CustomLabeledTextField(label: "Business Type", text: $businessType, error: $errors["BusinessType"])
                        CustomLabeledTextField(label: "Business Address", text: $businessAddress, error: $errors["BusinessAddress"])
                        CustomLabeledTextField(label: "Business Phone Number", text: $businessPhoneNumber, error: $errors["BusinessPhoneNumber"], isNumeric: true)

                        CustomLabeledTextField(label: "Year of Establishment", text: $businessYear, error: $errors["YearOfEstablishment"])
                            .disabled(true)
                            .onTapGesture {
                                showYearPicker = true
                            }
                            .onChange(of: businessYear) { _, _ in validateYear() }
                    }
                    .padding()
                }

                // Save and Next Button
                Button(action: submitForm) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Save and Next")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 30)
                .disabled(!isFormValid || viewModel.isLoading)

                NavigationLink(destination: BusinessRegStepThree(), isActive: $viewModel.shouldNavigate) {
                    EmptyView().navigationBarBackButtonHidden(true)
                }
            }
            .sheet(isPresented: $showYearPicker) {
                VStack {
                    Text("Select Year")
                        .font(.headline)
                        .padding()
                    Picker("Year", selection: $selectedYearValue) {
                        ForEach(1900...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .onChange(of: selectedYearValue) { _, _ in
                        businessYear = String(selectedYearValue)
                        validateYear()
                        showYearPicker = false
                    }
                    Button("Done") {
                        showYearPicker = false
                    }
                    .padding()
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if lastController == "BusinessSpinMenu" {
                let userId = AppSessionSnapshot.userID
                guard !userId.isEmpty else { return }
                viewModel.getBusinessInfo(userId: userId)
            }
        }
        .onChange(of: viewModel.businessInfo) { _, newInfo in
            if let info = newInfo {
                businessName = info.name
                businessType = info.type
                businessAddress = info.address
                businessPhoneNumber = info.phoneNumber
                businessYear = String(info.yearOfEstablishment)
                selectedYearValue = info.yearOfEstablishment
            }
        }
        .overlay(
            VStack {
                if !viewModel.message.isEmpty {
                    ToastView(message: viewModel.message, isPresented: $showToast)
                        .transition(.slide)
                        .animation(.easeInOut)
                }
            }
            .padding(.top, 20),
            alignment: .top
        )
    }

    func validateYear() {
        if let year = Int(businessYear), year >= 1900 && year <= Calendar.current.component(.year, from: Date()) {
            errors["YearOfEstablishment"] = nil
        } else {
            errors["YearOfEstablishment"] = "Please enter a valid year (e.g., 1990)."
        }
    }

    func submitForm() {
        UIApplication.shared.dismissKeyboard()
        
        validateFields()
        let userId = AppSessionSnapshot.userID

        if errors.isEmpty && !userId.isEmpty {
            viewModel.saveBusiness(
                userId: userId,
                name: businessName,
                type: businessType,
                address: businessAddress,
                phoneNumber: businessPhoneNumber,
                year: businessYear,
                time: ""
            )
        }
        showToast = true
    }

    func validateFields() {
        errors = [:]

        if businessName.isEmpty { errors["BusinessName"] = "Business Name is required" }
        if businessType.isEmpty { errors["BusinessType"] = "Business Type is required" }
        if businessAddress.isEmpty { errors["BusinessAddress"] = "Business Address is required" }
        if businessPhoneNumber.isEmpty { errors["BusinessPhoneNumber"] = "Business Phone Number is required" }
        if businessYear.isEmpty { errors["YearOfEstablishment"] = "Year of Establishment is required" } else { validateYear() }
    }
}

// MARK: - Preview
struct BusinessRegStepTwo_Previews: PreviewProvider {
    static var previews: some View {
        BusinessRegStepTwo(lastController: "BusinessSpinMenu")
    }
}
