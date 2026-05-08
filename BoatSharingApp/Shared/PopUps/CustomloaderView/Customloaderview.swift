//
//  Customloaderview.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 17/04/2025.
//

import SwiftUI

struct CustomLoaderView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
                
                Text("We're confirming your booking...")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)


                Text("Please do not close the app")
                    .foregroundColor(.white)
                    .font(.title3)
                    .padding(.top, -10)
            }
            .padding()
        }
    }
}
