import SwiftUI

struct YearPicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedYear: Int?
    
    let years: [Int] = Array(1950...Calendar.current.component(.year, from: Date())).reversed()
    @State private var tempSelectedYear: Int?

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

