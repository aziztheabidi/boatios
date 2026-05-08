import SwiftUI

struct FieldContainer<Content: View>: View {
    let label: String
    let error: String?
    let content: Content

    init(label: String, error: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.error = error
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)

            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Spacing.cornerRadius)
                    .stroke(error == nil ? AppTheme.Colors.fieldStroke : AppTheme.Colors.error, lineWidth: 1)
                content
                    .padding(AppTheme.Spacing.fieldPadding)
            }

            if let error, !error.isEmpty {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(AppTheme.Colors.error)
            }
        }
    }
}

