import SwiftUI

struct SectionCard<Content: View>: View {
    let content: Content
    let borderColor: Color
    let showShadow: Bool

    init(
        borderColor: Color = AppTheme.Colors.primary,
        showShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.borderColor = borderColor
        self.showShadow = showShadow
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: AppTheme.Spacing.cardCornerRadius).fill(AppTheme.Colors.background))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Spacing.cardCornerRadius)
                    .stroke(borderColor, lineWidth: 2)
            )
            .if(showShadow) { view in
                view.shadow(color: AppTheme.Colors.shadow, radius: 4)
            }
    }
}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

