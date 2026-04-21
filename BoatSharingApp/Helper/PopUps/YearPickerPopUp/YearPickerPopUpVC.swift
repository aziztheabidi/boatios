import SwiftUI

struct YearPicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedYear: Int?
    
    let years: [Int] = Array(1950...Calendar.current.component(.year, from: Date())).reversed() // Years from 1950 to current year
    @State private var tempSelectedYear: Int? // Temporary selection

    var body: some View {
        NavigationView {
            VStack {
                List(years, id: \.self) { year in
                    Button(action: {
                        tempSelectedYear = year
                    }) {
                        HStack {
                            Text("\(year)")
                                .foregroundColor(.primary)
                            Spacer()
                            if tempSelectedYear == year {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Button(action: {
                    if let tempYear = tempSelectedYear {
                        selectedYear = tempYear
                    }
                    dismiss() // Closes the picker
                }) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
            }
            .navigationTitle("Select Year")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

