//
//  SponsorsInvitationVC.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 10/04/2025.
//

import SwiftUI

struct SponsorsInvitationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var NavToVoyager: Bool = false
    let VoyageID: String
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                // "Voyager Booked!" Text
                Image("BookingDone") // Assuming "sent_image" is added to your Assets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.top, -80)
                
                
                
                Text("Voyage Booked!\nInvitation Sent Successfully!")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                
                
                Text("You're invited Jhon to become a sponsor and enjoy the ride together!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                
                Button(action: {
                    // Handle Done action (e.g., dismiss view)
                    NavToVoyager = true
                }) {
                    Text("Done")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            
            NavigationLink(
                destination: SponsorPaymentInvitationView(VoyageID: VoyageID),
                isActive: $NavToVoyager
            ) {
                EmptyView()
                    .navigationBarBackButtonHidden(true)
            }
            
            
//            NavigationLink(destination: SponsorPaymentInvitationView(), isActive: $NavToVoyager) {
//                EmptyView()
//                    .navigationBarBackButtonHidden(true)
//            }
            .padding()
            .background(Color.white.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    SponsorsInvitationView(VoyageID: "sdfbgsdbfsdfbsvdfv")
}
