//
//  IntroductionVC2.swift
//  BoatSharingApp
//
//  Created by Mac User on 29/01/2025.
//

import SwiftUI

struct OnboardingSecondVC: View {
    @Binding var currentPage: Int

    var body: some View {
        ZStack {
            Image("splash_bg")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Image("captain")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(.top, 180)
                
                VStack(spacing: 20) {
                    Text("Captain")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Join our boat riding sharing community and turn your boat into an adventure")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                HStack {
                    Button(action: {
                        currentPage = 2 // Skip to last page
                    }) {
                        Text("Skip")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 30)
                    
                    // Custom Page Indicators
                    HStack(spacing: 6) {
                        Capsule()
                            .fill(currentPage == 0 ? Color.white : Color.gray.opacity(0.8))
                            .frame(width: currentPage == 0 ? 25 : 15, height: 8)
                        Capsule()
                            .fill(currentPage == 1 ? Color.white : Color.gray.opacity(0.8))
                            .frame(width: currentPage == 1 ? 25 : 15, height: 8)
                        Capsule()
                            .fill(currentPage == 2 ? Color.white : Color.gray.opacity(0.8))
                            .frame(width: currentPage == 2 ? 25 : 15, height: 8)
                    }
                    
                    Button(action: {
                        currentPage = 2 // Move to next screen
                    }) {
                        Image("Next")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 30)
                }
                .padding(.bottom, 60)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
    }
}

