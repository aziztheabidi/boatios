//
//  CustomLoaderView.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 29/04/2025.
//



import SwiftUI

struct OverlayLoaderView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
        }
    }
}


