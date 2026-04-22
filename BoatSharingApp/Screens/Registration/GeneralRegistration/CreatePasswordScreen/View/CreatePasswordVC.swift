import SwiftUI

struct CreatePasswordVC: View {
    private let dependencies: AppDependencies
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var navigateToNextView: Bool = false
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""

    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: CreatePasswordViewModel

    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: CreatePasswordViewModel(
                tokenStore: dependencies.tokenStore,
                networkRepository: dependencies.networkRepository,
                sessionPreferences: dependencies.sessionPreferences
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    // Back Button
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

                    // Title & Steps
                    VStack(spacing: 15) {
                        Text("Create Your Password 3/3")
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 6) {
                            Capsule().fill(Color.blue).frame(width: 30, height: 8)
                            Capsule().fill(Color.blue).frame(width: 30, height: 6)
                            Capsule().fill(Color.blue).frame(width: 30, height: 6)
                        }
                    }
                    .padding(.top, -27)

                    // Password Field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Password")
                            .font(.headline)
                            .foregroundColor(.black)

                        HStack {
                            if isPasswordVisible {
                                TextField("Enter your password", text: $password)
                                    .textContentType(.password)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("Enter your password", text: $password)
                                    .textContentType(.password)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }

                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 1))

                        // Password Strength Bar
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .frame(height: 8)
                                .foregroundColor(Color.gray.opacity(0.2))

                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: passwordStrengthBarWidth(), height: 8)
                                .foregroundColor(passwordStrengthColor())
                                .animation(.easeInOut, value: passwordStrength())
                        }

                        // Strength Label
                        Text(passwordStrengthText())
                            .foregroundColor(passwordStrengthColor())
                            .font(.caption)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Requirements
                    VStack(alignment: .leading, spacing: 8) {
                        PasswordRequirementRow(
                            text: "At least 8 characters",
                            isMet: password.count >= 8
                        )
                        PasswordRequirementRow(
                            text: "Contains at least one number",
                            isMet: password.rangeOfCharacter(from: .decimalDigits) != nil
                        )
                        PasswordRequirementRow(
                            text: "Contains at least one special symbol",
                            isMet: password.rangeOfCharacter(from: .symbols) != nil || password.rangeOfCharacter(from: .punctuationCharacters) != nil
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // Confirm Button
                    Button(action: {
                        // Dismiss keyboard
                        UIApplication.shared.dismissKeyboard()
                        
                        if isPasswordValid() {
                            viewModel.createUser(password: password)
                        }
                    }) {
                        Text("Confirm")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isPasswordValid() ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    .disabled(!isPasswordValid())

                    Spacer()
                }

                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.4)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: viewModel.isLoading)
                }
            }

            // Toast & Navigation Handling
            .onReceive(viewModel.$isAuthenticated) { success in
                if success {
                    toastMessage = "Account Created Successfully!"
                    showToast = true
                    navigateToNextView = true
                }
            }
            .onReceive(viewModel.$errorMessage) { message in
                if let message = message {
                    toastMessage = message
                    showToast = true
                }
            }
            .navigationDestination(isPresented: $navigateToNextView) {
                RoleSelectionView(dependencies: dependencies)
            }
            
            ToastView(message: toastMessage, isPresented: $showToast)
        }
        .navigationBarBackButtonHidden(true)
    }

    struct PasswordRequirementRow: View {
        var text: String
        var isMet: Bool
        
        var body: some View {
            HStack {
                Image(systemName: isMet ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(isMet ? .green : .red)
                Text(text)
                    .foregroundColor(.black)
            }
        }
    }

    // MARK: - Password Strength Logic
    enum PasswordStrength {
        case weak, normal, strong
    }

    private func passwordStrength() -> PasswordStrength {
        let length = password.count
        let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSymbols = password.rangeOfCharacter(from: .symbols) != nil || password.rangeOfCharacter(from: .punctuationCharacters) != nil

        if length >= 8 && hasNumbers && hasSymbols {
            return .strong
        } else if length >= 6 && (hasNumbers || hasSymbols) {
            return .normal
        } else {
            return .weak
        }
    }

    private func passwordStrengthBarWidth() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 40
        switch passwordStrength() {
        case .weak: return screenWidth * 0.33
        case .normal: return screenWidth * 0.66
        case .strong: return screenWidth
        }
    }

    private func passwordStrengthColor() -> Color {
        switch passwordStrength() {
        case .weak: return .red
        case .normal: return .yellow
        case .strong: return .green
        }
    }

    private func passwordStrengthText() -> String {
        switch passwordStrength() {
        case .weak: return "Weak"
        case .normal: return "Normal"
        case .strong: return "Strong"
        }
    }

    private func isPasswordValid() -> Bool {
        return password.count >= 8 &&
               password.rangeOfCharacter(from: .decimalDigits) != nil &&
               (password.rangeOfCharacter(from: .symbols) != nil || password.rangeOfCharacter(from: .punctuationCharacters) != nil)
    }
}

struct CreatePasswordVC_Previews: PreviewProvider {
    static var previews: some View {
        CreatePasswordVC()
    }
}



