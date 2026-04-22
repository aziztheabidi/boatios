import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showLogoutAlert = false
    @State private var navigateToLogin = false
    @State private var navigateToResetPassword = false
    @State private var MoveToCaptainProfileOne = false
    @State private var navigateToBusinessProfile: Bool = false
    @State private var navigateToVoyagerProfile: Bool = false
    @State private var selectedType: RegistrationType?
    @Environment(\.presentationMode) var presentationMode

    var username: NSString

    var body: some View {
            VStack {
                // Top bar with back button and centered Settings text
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("Settings")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Buttons
                VStack(spacing: 20) {
                    // Forgot Password Button
                    Button(action: {
                        navigateToResetPassword = true
                    }) {
                        Text("Forgot Password")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.AppColor, lineWidth: 1)
                            )
                    }
                    
                    // Edit Profile Button
                    Button(action: {
                        let normalizedUsername = AppConfiguration.UserRole.normalize(username as String)
                        if normalizedUsername == AppConfiguration.UserRole.captain.rawValue {
                            MoveToCaptainProfileOne = true
                        } else if normalizedUsername == AppConfiguration.UserRole.business.rawValue {

                            selectedType = .business
                            navigateToBusinessProfile = true
                        } else {
                            selectedType = .voyager
                            navigateToVoyagerProfile = true
                        }
                    }) {
                        Text("Edit Profile")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.AppColor, lineWidth: 1)
                            )
                    }
                    .alert(isPresented: $showLogoutAlert) {
                        Alert(
                            title: Text("Logout"),
                            message: Text("Do you want to logout from the app?"),
                            primaryButton: .default(Text("OK")) {
                                navigateToLogin = true
                            },
                            secondaryButton: .cancel(Text("Not Now"))
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Navigation Links
                Group {
                    NavigationLink(
                        destination: ResetPasswordVC(),
                        isActive: $navigateToResetPassword
                    ) {
                        EmptyView()
                    }
                    
                    NavigationLink(
                        destination: LoginScreenView(),
                        isActive: $navigateToLogin
                    ) {
                        EmptyView()
                    }
                    
                    NavigationLink(
                        destination: CaptainRegStepOne(lastController: "CaptainProfileOne"),
                        isActive: $MoveToCaptainProfileOne
                    ) {
                        EmptyView()
                    }

                    NavigationLink(
                        destination: BusinessRegStepOne(registrationType: selectedType ?? .business, lastController: "BusinessSpinMenu"),
                        isActive: $navigateToBusinessProfile
                    ) {
                        EmptyView()
                    }
                    
                    NavigationLink(
                        destination: BusinessRegStepOne(registrationType: selectedType ?? .voyager, lastController: "VoyagerSpinMenu"),
                        isActive: $navigateToVoyagerProfile
                    ) {
                        EmptyView()
                    }
                }
            }
            .padding()
            .navigationBarHidden(true)
        
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(username: "")
    }
}
