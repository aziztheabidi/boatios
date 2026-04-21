import SwiftUI

struct RoleSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: RoleSelectionViewModel

    init(dependencies: AppDependencies = .live) {
        _viewModel = StateObject(wrappedValue: RoleSelectionViewModel(apiClient: dependencies.apiClient, sessionManager: dependencies.sessionManager))
    }

    @State private var selectedType: RegistrationType?
    @State private var navigateToNextView: Bool = false
    @State private var navigateToBusiness: Bool = false
    @State private var navigateToCaption: Bool = false
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var isLoading: Bool = false  // ✅ Added loading state
    

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
            
            // **Navigation Links**
            NavigationLink(
                destination: BusinessRegStepOne(registrationType: selectedType ?? .voyager, lastController: "Registration"),
                isActive: $navigateToNextView
            ) { EmptyView() }

            NavigationLink(
                destination: CaptainRegStepOne(lastController: ""),
                isActive: $navigateToCaption
            ) { EmptyView() }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.isAuthenticated) { _, isAuth in
            if isAuth {
                isLoading = false
                toastMessage = "Role updated successfully"
                showToast = true
                
                if let role = viewModel.selectedRole {
                    switch role {
                    case "Voyager":
                        selectedType = .voyager
                        navigateToNextView = true
                    case "Captain":
                        selectedType = .captain
                        navigateToCaption = true
                    case "Business":
                        selectedType = .business
                        navigateToNextView = true
                    default:
                        break
                    }
                }
            }
        }
        .onChange(of: viewModel.errorMessage) { _, errorMsg in
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
        let userId = AppSessionSnapshot.userID
        guard !userId.isEmpty else { return }
        
        isLoading = true // ✅ Show loader
        viewModel.updateRole(userId: userId, role: role)
        // Navigation will be triggered by onChange(of: viewModel.isAuthenticated)
    }
}

#Preview {
    RoleSelectionView()
}

