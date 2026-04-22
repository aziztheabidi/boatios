
import SwiftUI

struct OnboardingFirstVC: View {
    @Binding var currentPage: Int

    var body: some View {
        ZStack {
            // Background Image
            Image("splash_bg")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Top Image (Logo)
                Image("voyager_obboarding")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(.top, 180)
                
                // Labels
                VStack(spacing: 20) {
                    Text("Voyager")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Share the ride, make money - discover new horizons with our boat riding service")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Buttons and Indicators
                HStack {
                    // Skip Button
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
                    
                    // Next Button
                    Button(action: {
                        currentPage = 1
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

