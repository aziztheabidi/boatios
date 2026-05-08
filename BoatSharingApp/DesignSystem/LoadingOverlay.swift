import SwiftUI

struct LoadingOverlay: View {
    let message: String?
    let isPresented: Bool

    init(message: String? = nil, isPresented: Bool) {
        self.message = message
        self.isPresented = isPresented
    }

    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(.white)

                    if let message, !message.isEmpty {
                        Text(message)
                            .foregroundColor(.white)
                            .font(.footnote)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.15))
                .cornerRadius(AppTheme.Spacing.overlayCornerRadius)
            }
        }
    }
}

