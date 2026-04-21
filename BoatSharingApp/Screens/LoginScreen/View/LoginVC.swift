import SwiftUI

struct LoginScreenView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) private var openURL
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var navigateToForgot: Bool = false
    @State private var navigateToCreateAccount: Bool = false
    @StateObject private var viewModel: LoginAuthViewModel
    @State private var ShowToast: Bool = false
    @State private var ToastMsg: String = ""
    @State private var NavTointro: Bool = false

    init(dependencies: AppDependencies = .live) {
        _viewModel = StateObject(
            wrappedValue: LoginAuthViewModel(
                apiClient: dependencies.apiClient,
                sessionManager: dependencies.sessionManager,
                preferences: dependencies.preferences,
                tokenStore: dependencies.tokenStore,
                routingNotifier: dependencies.routingNotifier
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack {

                HStack {
                    Button(action: {
                        NavTointro = true
                    }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                            .imageScale(.large)
                            .padding(.leading, 15)
                    }
                    Spacer()
                                    Text("Log Into Account")
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                        .padding(.leading, -40)

                                   
                    Spacer()
                                }
                .padding(.top, 70)
                            
                // **Email Field**
                FieldContainer(
                    label: "Email",
                    error: viewModel.state.showValidationErrors ? viewModel.state.emailError : nil
                ) {
                    TextField("Enter your email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
                .padding(.horizontal, 20)
                .padding(.top, 15)
                
                // **Password Field**
                VStack(alignment: .leading, spacing: 5) {
                    FieldContainer(
                        label: "Password",
                        error: viewModel.state.showValidationErrors ? viewModel.state.passwordError : nil
                    ) {
                        HStack {
                            if isPasswordVisible {
                                TextField("Enter your password", text: $password)
                            } else {
                                SecureField("Enter your password", text: $password)
                            }
                            
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.primary)
                            }
                            .padding(.trailing, 10)
                        }
                    }
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            navigateToForgot = true
                        }) {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 10)
                        .padding(.trailing, 10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // **Login & Create Account Buttons**
                VStack(spacing: 10) {
                    PrimaryButton(
                        title: "Log In",
                        isLoading: viewModel.state.isLoading,
                        isDisabled: email.isEmpty || password.isEmpty
                    ) {
                        UIApplication.shared.dismissKeyboard()
                        viewModel.send(.submitLogin(email: email, password: password))
                    }
                    
                    Button(action: {
                        navigateToCreateAccount = true
                    }) {
                        Text("Create New Account?")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // **Terms & Conditions Button**
                Button(action: {
                    if let url = URL(string: AppConfiguration.Web.privacyPolicy) {
                        openURL(url)
                    }
                }) {
                    Text("By using Boatit, you agree to\n")
                        .foregroundColor(.gray) +
                    Text("Privicy Policy")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                .padding(.bottom, 20)
                .padding(20)
                
                // **Navigation Links**
                NavigationLink(destination: ResetPasswordVC(), isActive: $navigateToForgot) {
                    EmptyView()
                }
                
                NavigationLink(destination: BasicInfoVC(), isActive: $navigateToCreateAccount) {
                    EmptyView()
                        .navigationBarBackButtonHidden(true)
                }
                NavigationLink(destination: PageControllerView(), isActive: $NavTointro) {
                    EmptyView()
                        .navigationBarBackButtonHidden(true)
                }
                
                
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.Colors.background)
            .edgesIgnoringSafeArea(.all)
            .navigationBarHidden(false)
            .navigationBarBackButtonHidden(true)
            .onChange(of: viewModel.state.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    ToastMsg = "Login Successful!"
                    ShowToast = true

                    viewModel.send(.updateFcmForAuthenticatedUser)
                }
            }
            .onChange(of: viewModel.state.errorMessage) { _, errorMessage in
                if let errorMessage = errorMessage {
                    ToastMsg = errorMessage
                    ShowToast = true
                }
            }
            .overlay(
                ToastView(message: ToastMsg, isPresented: $ShowToast)
            )
            
            
            .navigationBarBackButtonHidden(true)

        }
    }
}

#Preview {
    LoginScreenView()
}
