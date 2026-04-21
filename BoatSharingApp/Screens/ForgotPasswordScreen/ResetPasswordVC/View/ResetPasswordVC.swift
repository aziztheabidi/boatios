import SwiftUI

struct ResetPasswordVC: View {
    @StateObject private var viewModel: ResetPasswordViewModel
    @State private var email = ""

    init(dependencies: AppDependencies = .live) {
        _viewModel = StateObject(wrappedValue: ResetPasswordViewModel(apiClient: dependencies.apiClient))
    }
    @State private var errorMessage: String? = nil
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) private var openURL
    @State private var MovetoTNC = false

    private var isSendButtonEnabled: Bool {
        return !email.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Back Button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                            .imageScale(.large)
                    }
                    Spacer()
                }
                .padding()

                // Title
                Text("Reset Password")
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(.top, -45)

                // Centered text
                Text("We will email you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 250)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, -20)

                // Email Field
                VStack(alignment: .leading, spacing: 5) {
                    Text("Email")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top, 20)

                    TextField("Enter your email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10)
                            .stroke(errorMessage != nil ? Color.red : Color.gray, lineWidth: 1))

                    // Validation Error Message (Under TextField)
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)

                // Reset Button with Activity Indicator
                Button(action: {
                    validateEmail()
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("Send")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSendButtonEnabled ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                .disabled(!isSendButtonEnabled || viewModel.isLoading)

                Spacer()

                // Terms & Conditions Button
                Button(action: {
                    if let url = URL(string: AppConfiguration.Web.privacyPolicy) {
                        openURL(url)
                    }
                }) {
                    Text("By using Boatit, you agree to\n")
                        .foregroundColor(.gray) +
                    Text("Privacy Policy")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                .padding(.bottom, 20)
            }
            .padding()
            .overlay(
                Group {
                    // Success Toast
                    ToastView(message: viewModel.Message, isPresented: $viewModel.isEmailSent)
                        .offset(y: -50) // Position above bottom
                    // Failure Toast
                    if let errorMessage = viewModel.errorMessage {
                        ToastView(message: errorMessage, isPresented: .constant(true))
                            .offset(y: -50)
                            .onAppear {
                                viewModel.clearErrorAfterDelay()
                            }
                    }
                }
            )
            .onChange(of: viewModel.shouldClearErrorAfterDelay) { _, shouldClear in
                if shouldClear {
                    viewModel.errorMessage = nil
                    viewModel.shouldClearErrorAfterDelay = false
                }
            }
            // Move to Next Screen when API is successful
            .navigationDestination(isPresented: $viewModel.isEmailSent) {
                SentResetPasswordVC()
                    .navigationBarBackButtonHidden(true)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // Validation function
    func validateEmail() {
        errorMessage = nil // Reset validation error

        if email.isEmpty {
            errorMessage = "Email is required"
        } else if !isValidEmail(email) {
            errorMessage = "Please enter a valid email"
        } else {
            // Call API
            viewModel.forgotPassword(email: email)
        }
    }

    // Email format validation
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}

#Preview {
    ResetPasswordVC()
}
