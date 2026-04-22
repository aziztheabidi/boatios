import SwiftUI

struct RoleSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    private let dependencies: AppDependencies
    @StateObject private var viewModel: RoleSelectionViewModel

    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: RoleSelectionViewModel(
            networkRepository: dependencies.networkRepository,
            sessionManager: dependencies.sessionManager,
            sessionPreferences: dependencies.sessionPreferences
        ))
    }

    @State private var selectedType: RegistrationType?

    private enum RegistrationStack: Hashable {
        case voyagerOrBusinessOnboarding
        case captainOnboarding
    }

    @State private var registrationStack: RegistrationStack?
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var isLoading: Bool = false


    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // **Back Button**
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.backward")
                        .font(.title2)
                        .foregroundColor(.black)
                }
                .padding(.top, 80)
                
                // **Title**
                Text("Please Select Your Experience")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                // **Subtitle**
                Text("Begin by creating a free account. This helps keep your journey easier.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                // **Experience Selection**
                experienceSelectionView(title: "Voyager", subtitle: "Book your first ride today!", imageName: "voyager")
                
                HStack(spacing: 20) {
                    experienceSelectionView(title: "Captain", subtitle: "Start your new first voyager onboard!", imageName: "captain")
                experienceSelectionView(title: "Business", subtitle: "Start serving voyages today!", imageName: "business")
                }
                
                Spacer()
                
                // **Continue as Guest Button**
                PrimaryButton(
                    title: "Continue as Guest",
                    isLoading: false,
                    isDisabled: false
                ) {
                }
                .padding(.horizontal, 0)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .background(AppTheme.Colors.background)
            .edgesIgnoringSafeArea(.all)
            .navigationDestination(item: $registrationStack) { stack in
                switch stack {
                case .voyagerOrBusinessOnboarding:
                    BusinessRegStepOne(registrationType: selectedType ?? .voyager, lastController: "Registration", dependencies: dependencies)
                case .captainOnboarding:
                    CaptainRegStepOne(lastController: "", dependencies: dependencies)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.state.isAuthenticated) { _, isAuth in
            if isAuth {
                isLoading = false
                toastMessage = "Role updated successfully"
                showToast = true
                
                if let role = viewModel.state.selectedRole {
                    switch role {
                    case "Voyager":
                        selectedType = .voyager
                        registrationStack = .voyagerOrBusinessOnboarding
                    case "Captain":
                        selectedType = .captain
                        registrationStack = .captainOnboarding
                    case "Business":
                        selectedType = .business
                        registrationStack = .voyagerOrBusinessOnboarding
                    default:
                        break
                    }
                }
            }
        }
        .onChange(of: viewModel.state.errorMessage) { _, errorMsg in
            if let error = errorMsg {
                isLoading = false
                toastMessage = error
                showToast = true
            }
        }
        .overlay(
            ToastView(message: toastMessage, isPresented: $showToast)
                .animation(.easeInOut, value: showToast)
        )
        .overlay(
            LoadingOverlay(message: "Loading...", isPresented: isLoading)
        )
    }
    
    // **Reusable Experience Selection View**
    private func experienceSelectionView(title: String, subtitle: String, imageName: String) -> some View {
        Button(action: {
            handleRoleSelection(role: title)
        }) {
            SectionCard(borderColor: AppTheme.Colors.primary) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 100)
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // **Handle Role Selection & Show Loader**
    private func handleRoleSelection(role: String) {
        let userId = viewModel.roleSelectionUserId
        guard !userId.isEmpty else { return }
        
        isLoading = true
        viewModel.updateRole(userId: userId, role: role)
    }
}

#Preview {
    RoleSelectionView()
}



