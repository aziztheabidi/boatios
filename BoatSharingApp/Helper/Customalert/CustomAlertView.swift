import SwiftUI

struct CustomAlertView: View {
    let message: String
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            VisualEffectView(effect: UIBlurEffect(style: .dark))
                .ignoresSafeArea()
                .background(Color.black.opacity(0.4))
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 10) {
                Text("Alert")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.top, 10)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("OK")
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
            .frame(width: 310, height: 260) // Increased height to accommodate title
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 5)
        }
    }
}

struct CustomAlertView_Previews: PreviewProvider {
    static var previews: some View {
        CustomAlertView(
            message: "Please select 29 or less than 29 passengers as per selected category.",
            isPresented: .constant(true)
        )
    }
}
