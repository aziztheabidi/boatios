import SwiftUI

struct BasicInfoVC: View {
    private let dependencies: AppDependencies
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var errors: [String: String] = [:]
    @State private var showErrors = false
    @State private var showToast = false
    @StateObject private var viewModel: BasicInfoViewModel
    @Environment(\.presentationMode) var presentationMode

    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: BasicInfoViewModel(networkRepository: dependencies.networkRepository))
    }

    var isFormValid: Bool {
        return !name.isEmpty && isValidEmail(email) && isValidPhone(phone)
    }

    var body: some View {
        NavigationStack {
            VStack {
                // **Back Button**
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // **Title & Page Indicator**
                VStack(spacing: 15) {
                    Text("Add your Info 1/3")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 6) {
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: 30, height: 8)
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 30, height: 6)
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 30, height: 6)
                    }
                }
                .padding(.top, -30)
                
                // **Input Fields with Validation and Placeholder Overlays**
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading, spacing: 0) {

                        Text("Name")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                        
                        CustomLabeledTextFields(
                            label: "Name",
                            placeholder: "Enter your name", // optional
                            text: $name,
                            error: Binding(
                                get: { errors["Name"] },
                                set: { errors["Name"] = $0 }
                            )
                        )
                        .onChange(of: name) { _, _ in errors["Name"] = nil }
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                        
                        CustomLabeledTextFields(
                            label: "",
                            placeholder: "example@abc.com",
                            text: $email,
                            error: Binding(
                                get: { errors["Email"] },
                                set: { errors["Email"] = $0 }
                            )
                        )
                        .onChange(of: email) { _, _ in errors["Email"] = nil }
                        
                        if email.isEmpty && errors["Email"] == nil {
                            Text("example@abc.com")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.horizontal, 16)
                                .padding(.top, 5)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Phone Number")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                        
                        CustomLabeledTextFields(
                            label: "",
                            placeholder: "(XXX) XXX-XXXX",
                            text: Binding(
                                get: { phone },
                                set: { newValue in
                                    let digits = newValue.filter { $0.isNumber }
                                    guard digits.count <= 10 else { return }
                                    phone = formatPhoneNumber(digits)
                                }
                            ),
                            error: Binding(
                                get: { errors["PhoneNumber"] },
                                set: { errors["PhoneNumber"] = $0 }
                            ),
                            isNumeric: true
                        )                        .keyboardType(.numberPad)
                        .onChange(of: phone) { _, _ in errors["PhoneNumber"] = nil }
                        
                        if phone.isEmpty && errors["PhoneNumber"] == nil {
                            Text("(XXX) XXX-XXXX")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.horizontal, 16)
                                .padding(.top, 5)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // **Register Button with API Call**
                Button(action: registerUser) {
                    HStack {
                        if viewModel.state.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("Register")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 33)
                .padding(.top, 30)
                .disabled(!isFormValid || viewModel.state.isLoading)
                
                Spacer()
                
                // **Navigation to Next Screen**
                NavigationLink(
                    destination: OTPVC(email: email, dependencies: dependencies),
                    isActive: Binding(
                        get: { viewModel.state.shouldNavigate },
                        set: { if !$0 { viewModel.send(.resetNavigation) } }
                    )
                ) {
                    EmptyView()
                        .navigationBarBackButtonHidden(true)
                }
            }
            .navigationBarBackButtonHidden(true)
            .overlay(
                ToastView(message: viewModel.state.message, isPresented: $showToast)
                    .padding(.bottom, 50),
                alignment: .bottom
            )
        }
        .onChange(of: viewModel.state.message) { _, newMessage in
            if !newMessage.isEmpty && !viewModel.state.isSuccess {
                showToast = true
            }
        }
    }
    
    // **Register User with API**
    private func registerUser() {
        // Dismiss keyboard
        UIApplication.shared.dismissKeyboard()
        
        validateFields()
        
        if isFormValid {
            // Send only the digits to the API
            let cleanPhone = phone.filter { $0.isNumber }
            viewModel.registerUser(name: name, email: email, phone: cleanPhone)
        } else {
            showErrors = true
        }
    }
    
    // **Validation Function**
    private func validateFields() {
        errors = [:]
        
        if name.isEmpty { errors["Name"] = "Name is required" }
        if email.isEmpty || !isValidEmail(email) { errors["Email"] = "Please enter a valid email" }
        if phone.isEmpty || !isValidPhone(phone) { errors["PhoneNumber"] = "Valid phone number required (10 digits)" }
    }
    
    // **Email Validation**
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    // **Phone Number Validation**
    private func isValidPhone(_ phone: String) -> Bool {
        let digits = phone.filter { $0.isNumber }
        return digits.count == 10
    }
    
    // **Phone Number Formatting**
    private func formatPhoneNumber(_ digits: String) -> String {
        let count = digits.count
        
        switch count {
        case 0:
            return ""
        case 1...3:
            return "(\(digits))"
        case 4...6:
            let area = digits.prefix(3)
            let prefix = digits.dropFirst(3)
            return "(\(area)) \(prefix)"
        case 7...10:
            let area = digits.prefix(3)
            let prefix = digits.dropFirst(3).prefix(3)
            let line = digits.dropFirst(6)
            return "(\(area)) \(prefix)-\(line)"
        default:
            return ""
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        BasicInfoVC()
    }
}



