//
//  BusinessHomeVC.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 13/02/2025.
//

import SwiftUI

struct BusinessHomeVC: View {
    
    @State private var moveToMenu = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background Color
                Color.white.ignoresSafeArea()
                
                // Centered Content
                VStack(spacing: 10) {
                    Image("Coming") // Use any custom icon if needed
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400, height: 400)
                    
                }
                
                // Top Left Menu Button
                VStack {
                    HStack {
                        Button(action: {
                            moveToMenu = true
                           
                            
                            
                        }) {
                            Image("Group1")
                                .resizable()
                            .frame(width: 60, height: 60)                    }
                        .padding()
                        
                        Spacer()
                    }
                    Spacer()
                }
                NavigationLink(destination: SpinWheelMenu(username: "Business"), isActive: $moveToMenu) {
                    EmptyView()
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// Preview
struct ComingSoonView_Previews: PreviewProvider {
    static var previews: some View {
        BusinessHomeVC()
    }
}
