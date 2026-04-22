
import SwiftUI
struct OnboardingThirdVC: View {
    var body: some View {
        ZStack {
            Image("splash_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                Image("business")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(.top, 180)

                VStack(spacing: 20) {
                    Text("Business")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Revolutionize the boating industry, connect boat owners and passengers.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(spacing: 10) {
                    // Create Account Button
                    NavigationLink(destination: BasicInfoVC()) {
                        Text("Create an Account")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(12)
                            .frame(width: 300)
                            .background(Color.white)
                            .cornerRadius(20)
                    }
                    
                    // Login Button
                    NavigationLink(destination: LoginScreenView()) {
                        Text("Already have an account? Log in")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300)
                            .background(Color.clear)
                    }
                }
                .padding(.bottom, 80)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
    }
}

#Preview {
    PageControllerView()
}

