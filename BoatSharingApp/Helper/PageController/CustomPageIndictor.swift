import SwiftUI

struct CustomPageIndicator: View {
    var currentPage: Int // Accept current page index
    var totalPages: Int = 2 // Default total pages
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(index == currentPage ? Color.white : Color.gray.opacity(0.7))
            }
        }
        .padding(10) // Add padding to give space for shadow
       // .background() // Background color for the shadow
        .cornerRadius(20) // Rounded corners for the background
        .shadow(color: .gray, radius: 5, x: 0, y: 2) // Add shadow
    }
}

#Preview {
    CustomPageIndicator(currentPage: 0)
}

