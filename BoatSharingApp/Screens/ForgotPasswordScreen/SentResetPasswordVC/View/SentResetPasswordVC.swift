//
//  EmailSendVC.swift
//  testing app
//
//  Created by Gamex Global on 07/02/2025.
//

import SwiftUI

struct SentResetPasswordVC: View {
    @Environment(\.presentationMode) var presentationMode // For back button
    @Environment(\.openURL) private var openURL
    @State private var navigateToLogin = false
    @State private var navigateToTerm = false
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                            .imageScale(.large)
                    }
                    Spacer()
                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.top, -20)
                .padding()
                Image(systemName: "envelope.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)

                Text("We have sent an email to a link to reset your password.\nFollow the instructions to proceed.")
                    
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)
                // Blue Button
                Button(action: {
                    navigateToLogin = true
                }) {
                    Text("Back To Login")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 30)

                Spacer()
                
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
                .padding(.horizontal)
                
                NavigationLink(destination: TermsAndConditionsView(), isActive: $navigateToTerm) {
                    EmptyView()
                }
                NavigationLink(destination: LoginScreenView(), isActive: $navigateToLogin) {
                    EmptyView()
                        
                }
                .navigationBarBackButtonHidden(true)
                
            }
            .padding(.top, 20)
            .navigationBarBackButtonHidden(true)

            
        }
    }
}

struct ResetPasswordSentView_Previews: PreviewProvider {
    static var previews: some View {
        SentResetPasswordVC()
    }
}
