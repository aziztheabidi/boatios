import SwiftUI

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(title: String, isLoading: Bool = false, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .disabled(isDisabled || isLoading)
        .background((isDisabled || isLoading) ? Color.gray : AppTheme.Colors.primary)
        .cornerRadius(AppTheme.Spacing.cornerRadius)
    }
}

