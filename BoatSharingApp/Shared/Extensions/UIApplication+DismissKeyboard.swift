import UIKit
import SwiftUI

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil,
                   from: nil,
                   for: nil)
    }
}

extension View {
    func dismissKeyboard() {
        UIApplication.shared.dismissKeyboard()
    }
}
