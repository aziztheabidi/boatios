import SwiftUI

struct SplashScreenView: View {
    @StateObject private var viewModel: SplashViewModel

    init(dependencies: AppDependencies = .live) {
        _viewModel = StateObject(
            wrappedValue: SplashViewModel(deviceIdentifierStore: dependencies.deviceIdentifierStore)
        )
    }

    var body: some View {
        if viewModel.state.isActive {
            PageControllerView()
        } else {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                Image("boatit_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
//                Text(fcmToken)
//                    .font(.caption)
//                    .foregroundColor(.white)
//                    .padding()
//                    .background(Color.black.opacity(0.7))
//                    .cornerRadius(10)
//                    .offset(y: 150)
            }
            .onAppear {
                viewModel.send(.onAppear)
            }
            .onReceive(NotificationCenter.default.publisher(for: .didReceiveFCMToken)) { notification in
                if let token = notification.object as? String {
                    viewModel.send(.didReceiveFcmToken(token))
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .didReceivePushNotification)) { notification in
                viewModel.send(.didReceivePushNotification(notification.object))
            }
        }
    }
}

#Preview {
    SplashScreenView()
}



