//
//  CustomToastVC.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 19/02/2025.
//

import SwiftUI
import Combine

// **Toast View**
struct ToastView: View {
    let message: String
    @Binding var isPresented: Bool
    @State private var dismissCancellable: AnyCancellable?

    var body: some View {
        if isPresented {
            Text(message)
                .bold()
                .padding()
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
                .transition(.opacity)
                .onAppear {
                    dismissCancellable?.cancel()
                    dismissCancellable = Just(())
                        .delay(for: .seconds(3), scheduler: RunLoop.main)
                        .sink { _ in
                            isPresented = false
                        }
                }
                .onDisappear {
                    dismissCancellable?.cancel()
                    dismissCancellable = nil
                }
                .padding(.top, -30)
            Spacer()
        } else {
            EmptyView()
        }
    }
}
