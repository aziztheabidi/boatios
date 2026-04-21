import SwiftUI

struct CustomLabeledTextField: View {
    var label: String
    @Binding var text: String
    @Binding var error: String?
    var isNumeric: Bool = false
    var isEmail: Bool = false
    
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 16)

            TextField(label, text: $text, onEditingChanged: { editing in
                if editing {
                    error = nil  // Remove error when user starts typing
                }
            })
            .autocapitalization(.none)
            .keyboardType(isNumeric ? .numberPad : (isEmail ? .emailAddress : .default))
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(error == nil ? Color.gray.opacity(0.3) : Color.red, lineWidth: 1)
            )
            .padding(.horizontal)

            if let errorMessage = error {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .opacity(isFocused ? 0 : 1) // Hide error text while typing
            }
        }
        .focused($isFocused)
    }
}


// for basic first step
struct CustomLabeledTextFields: View {
    var label: String
    var placeholder: String = ""
    @Binding var text: String
    @Binding var error: String?
    var isNumeric: Bool = false
    var isEmail: Bool = false
    
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading) {
            // ❌ Removed top label entirely to avoid duplicates
            TextField(placeholder, text: $text, onEditingChanged: { editing in
                if editing {
                    error = nil  // Remove error when user starts typing
                }
            })
            .autocapitalization(.none)
            .keyboardType(isNumeric ? .numberPad : (isEmail ? .emailAddress : .default))
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(error == nil ? Color.gray.opacity(0.3) : Color.red, lineWidth: 1)
            )
            .padding(.horizontal)

            if let errorMessage = error {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .opacity(isFocused ? 0 : 1)
            }
        }
        .focused($isFocused)
    }
}


