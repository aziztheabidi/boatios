import SwiftUI

struct OTPVC: View {
    @State private var otp = ["", "", "", "", ""]
    @FocusState private var focusedField: Int?
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: OTPViewModel
    @State private var showToast = false
    let email: String

    init(email: String, dependencies: AppDependencies = .live) {
        self.email = email
        _viewModel = StateObject(wrappedValue: OTPViewModel(networkRepository: dependencies.networkRepository, tokenStore: dependencies.tokenStore))
    }

    var isVerifyButtonEnabled: Bool {
        !otp.contains("")
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
                    Text("Add your Info 2/3")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 6) {
                        Capsule().fill(Color.blue).frame(width: 30, height: 8)
                        Capsule().fill(Color.blue).frame(width: 30, height: 6)
                        Capsule().fill(Color.gray.opacity(0.3)).frame(width: 30, height: 6)
                    }
                    
                    Text("Please enter the 5-digit code sent to your Email Id \(email). Enter it below")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                        .padding(.horizontal, 60)
                }
                .padding(.top, -30)

                // **OTP Input Fields (Optimized)**
                VStack(alignment: .leading, spacing: 20) {
                    Text("Code")
                        .font(.headline)
                        .foregroundColor(.black)

                    HStack(spacing: 15) {
                        ForEach(0..<5, id: \.self) { index in
                            if #available(iOS 17.0, *) {
                                TextField("", text: $otp[index], onEditingChanged: { editing in
                                    if !editing && otp[index].isEmpty && index > 0 {
                                        focusedField = index - 1
                                    }
                                })
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .frame(width: 60, height: 60)
                                .multilineTextAlignment(.center)
                                .background(RoundedRectangle(cornerRadius: 8)
                                    .stroke(viewModel.isSuccess ? Color.red : Color.blue, lineWidth: 1))
                                .focused($focusedField, equals: index)
                                .onChange(of: otp[index]) { oldValue, newValue in
                                    let filtered = newValue.filter { $0.isNumber }.prefix(1)
                                    otp[index] = String(filtered)
                                    
                                    if !filtered.isEmpty {
                                        if index < 4 {
                                            focusedField = index + 1
                                        } else {
                                            focusedField = nil
                                        }
                                    }
                                }
                            } else {
                                // Fallback on earlier versions
                            }
                        }
                    }
                    .onAppear {
                        focusedField = 0
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .gesture(
                    TapGesture()
                        .onEnded { _ in
                            focusedField = nil
                        }
                )

                // **Verify Button**
                Button(action: validateOTP) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("Verify")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isVerifyButtonEnabled ? Color.blue : Color.gray.opacity(0.5))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .disabled(!isVerifyButtonEnabled || viewModel.isLoading)

                // **Resend Timer & Button**
                HStack {
                    if !viewModel.isResendAvailable {
                        Text("Resend code in \(viewModel.timerValue)s")
                            .foregroundColor(.gray)
                    } else {
                        Button(action: viewModel.resetTimer) {
                            Text("Resend Code")
                                .foregroundColor(.blue)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding(.top, 10)

                // **Wrong Email? Button**
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Wrong Email? Enter New Email")
                        .foregroundColor(.black)
                        .fontWeight(.medium)
                }
                .padding(.top, 15)

                Spacer()

                // **Terms & Conditions**
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
                .padding(.horizontal)

                // **Navigation to Next Screen**
                NavigationLink(destination: CreatePasswordVC(), isActive: $viewModel.shouldNavigate) {
                    EmptyView()
                        .navigationBarBackButtonHidden(true)
                }
            }
            .onAppear(perform: viewModel.startTimer)
            .onChange(of: viewModel.shouldShowToast) { _, show in
                showToast = show
            }
            .overlay(
                ToastView(message: "Successfully OTP Registered!", isPresented: $showToast)
                    .padding(.bottom, 100),
                alignment: .bottom
            )
            .navigationBarBackButtonHidden(true)
        }
    }

    private func validateOTP() {
        // Dismiss keyboard
        UIApplication.shared.dismissKeyboard()
        
        let enteredOTP = otp.joined()
        if let otpInt = Int(enteredOTP), enteredOTP.count == 5 {
            viewModel.EnterOTP(email: email, OTP: otpInt)
        } else {
            viewModel.handleInvalidOtpInput()
        }
    }
}

struct OTPScreenController_Previews: PreviewProvider {
    static var previews: some View {
        OTPVC(email: "test@example.com")
    }
}


