//
//  CustomnumberTextField.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 03/09/2025.
//

import SwiftUI

struct CustomNumericTextField: View {
    let label: String
    @Binding var text: String
    @Binding var error: String?
    var placeholder: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !label.isEmpty {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            TextField(placeholder ?? "", text: Binding(
                get: { text },
                set: { newValue in
                    // Allow only digits
                    let filtered = newValue.filter { $0.isNumber }
                    text = filtered
                }
            ))
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .keyboardType(.numberPad)
            .textContentType(.telephoneNumber)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(error != nil ? Color.red : Color.gray.opacity(0.5), lineWidth: 1)
            )

            if let error = error, !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
    }
}
