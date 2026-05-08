import SwiftUI

enum AppTheme {
    enum Spacing {
        static let horizontal: CGFloat = 20
        static let vertical: CGFloat = 16
        static let sectionTop: CGFloat = 70
        static let fieldPadding: CGFloat = 12
        static let cornerRadius: CGFloat = 10
        static let cardCornerRadius: CGFloat = 16
        static let overlayCornerRadius: CGFloat = 12
    }

    enum Colors {
        static let primary = Color.AppColor
        static let background = Color(.systemBackground)
        static let fieldStroke = Color.gray.opacity(0.6)
        static let error = Color.red
        static let shadow = Color.black.opacity(0.08)
    }
}

