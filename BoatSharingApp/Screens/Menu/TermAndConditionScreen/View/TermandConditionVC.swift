//
//  TermandConditionVC.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 12/02/2025.
//

import SwiftUI

struct TermsAndConditionsView: View {
    @Environment(\.presentationMode) var presentationMode // For Back Button
    @State private var agreed = false // Track if user agrees

    var body: some View {
        NavigationStack {
            VStack {
                // Header with Back Button and Title
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss() // Go Back
                    }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("Terms and Conditions")
                        .font(.title2)
                        .foregroundColor(.black)
                    
                    Spacer() // Keep title centered
                    
                    // Invisible Spacer to balance layout
                    Image(systemName: "arrow.backward")
                        .opacity(0)
                }
                .padding()
                
                // Scrollable Terms & Conditions Text
                ScrollView {
                    Text("""
                Welcome to our Boat Sharing App. By using this application, you agree to comply with and be bound by the following terms and conditions. Please review these terms carefully.
                
                1. **Acceptance of Terms**  
                   By accessing or using our services, you accept and agree to be bound by these terms. If you do not agree, please do not use the app.
                
                2. **User Responsibilities**  
                   You must provide accurate information and ensure the safety of boat rides.
                
                3. **Payments and Refunds**  
                   All payments are processed securely. Refunds are subject to our refund policy.
                
                4. **Privacy Policy**  
                   Your personal data will be used according to our privacy policy.
                
                5. **Termination**  
                   We reserve the right to terminate accounts violating our terms.
                
                6. **Modifications**  
                   Terms can be updated at any time.
                
                Please read carefully before proceeding.
                """)
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding()
                }
                
                Spacer() // Push Agree button to bottom
                
                // Agree Button
                Button(action: {
                    agreed = true
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Agree")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    TermsAndConditionsView()
}
