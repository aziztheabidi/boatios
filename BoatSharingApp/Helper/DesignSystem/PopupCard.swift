import SwiftUI

/// Shared wrapper for popup-style cards (rounded corners + subtle shadow).
struct PopupCard<Content: View>: View {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowOpacity: Double
    let content: Content

    init(
        cornerRadius: CGFloat = 20,
        shadowRadius: CGFloat = 10,
        shadowOpacity: Double = 0.12,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
        self.content = content()
    }

    var body: some View {
        content
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, y: 4)
    }
}

