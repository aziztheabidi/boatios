import SwiftUI

struct CaptainRegStepThree: View {
    var lastController: NSString

    @StateObject private var viewModel: CaptainRegStepThreeViewModel

    init(lastController: NSString, dependencies: AppDependencies = .live) {
        self.lastController = lastController
        _viewModel = StateObject(wrappedValue: CaptainRegStepThreeViewModel(
            apiClient: dependencies.apiClient,
            preferences: dependencies.preferences
        ))
    }

    @State private var boatName = ""
    @State private var boatMake = ""
    @State private var boatModel = ""
    @State private var boatYear: Int? = nil
    @State private var boatSize = ""
    @State private var boatCapacity = ""
    
    @State private var showYearPicker = false
    @State private var errors: [String: String] = [:]

    var isFormValid: Bool {
        return !boatName.isEmpty &&
               !boatMake.isEmpty &&
               !boatModel.isEmpty &&
               boatYear != nil &&
               !boatSize.isEmpty &&
               !boatCapacity.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Top Bar
                HStack {
                    Button(action: { /* Add back navigation */ }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                    Spacer()
                    Text("Add Your Boat Info 3/3")
                        .font(.headline)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "arrow.backward")
                            .opacity(0)
                    }
                }
                .padding()
                
                // Progress Indicator
                HStack(spacing: 8) {
                    Capsule().fill(Color.blue).frame(width: 40, height: 8)
                    Capsule().fill(Color.blue).frame(width: 40, height: 8)
                    Capsule().fill(Color.blue).frame(width: 40, height: 8)
                }
                .padding(.bottom, 20)
                
                // Scrollable Form
                ScrollView {
                    VStack(spacing: 16) {
                        CustomLabeledTextField(label: "Boat Name", text: $boatName, error: $errors["boatName"])
                        CustomLabeledTextField(label: "Boat Make", text: $boatMake, error: $errors["boatMake"])
                        CustomLabeledTextField(label: "Boat Model", text: $boatModel, error: $errors["boatModel"])
                        
                        // Year Picker Field
                        yearPickerField(label: "Boat Year", selectedYear: $boatYear, showPicker: $showYearPicker, error: $errors["boatYear"])
                        
                        // Numeric Inputs
                        CustomLabeledTextField(label: "Boat Size", text: $boatSize, error: $errors["boatSize"])
                            .keyboardType(.numberPad)
                        CustomLabeledTextField(label: "Boat Capacity", text: $boatCapacity, error: $errors["boatCapacity"])
                            .keyboardType(.numberPad)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Save and Proceed Button
                Button(action: saveBoat) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Save and Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(isFormValid ? Color.blue : Color.gray)
                .cornerRadius(10)
                .shadow(radius: 5)
                .disabled(!isFormValid || viewModel.isLoading)
                .padding(.horizontal, 27)
            }
            .toast(isPresented: !viewModel.message.isEmpty, message: viewModel.message, isSuccess: viewModel.isSuccess)
            .navigationDestination(isPresented: $viewModel.shouldNavigate) {
                CaptainHomeVC()
                    .navigationBarBackButtonHidden(true)
            }
            .onAppear {
                if lastController == "CaptainProfileThree" {
                    let userId = AppSessionSnapshot.userID
                    guard !userId.isEmpty else { return }
                    viewModel.getCaptainBoat(userId: userId)
                }
            }
            .onChange(of: viewModel.fetchedBoat) { _, boat in
                guard let boat = boat else { return }
                boatName = boat.name
                boatMake = boat.make
                boatModel = boat.model
                boatYear = boat.year // ✅ Set Int directly
                boatSize = String(boat.size)
                boatCapacity = String(boat.capacity)
            }
            
        }
    }

    // MARK: - Save Boat Data
    private func saveBoat() {
        validateForm()
        let userId = AppSessionSnapshot.userID
        guard !userId.isEmpty else { return }
        guard isFormValid else { return }
        
        viewModel.CaptainSavedBoat(
            UserId: userId,  // Replace with actual user ID
            BoatName: boatName,
            Make: boatMake,
            Model: boatModel,
            BoatYear: boatYear ?? 0,
            BoatSize: Int(boatSize) ?? 0,
            Capacity: Int(boatCapacity) ?? 0
        )
    }

    // MARK: - Year Picker Field

    @ViewBuilder
    private func yearPickerField(label: String, selectedYear: Binding<Int?>, showPicker: Binding<Bool>, error: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)

            HStack {
                Text(selectedYear.wrappedValue != nil ? "\(selectedYear.wrappedValue!)" : "Select Year")
                    .foregroundColor(selectedYear.wrappedValue != nil ? .black : .gray)
                
                Spacer()
                
                Button(action: { showPicker.wrappedValue.toggle() }) {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(UIColor.white))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .frame(height: 50)
            .frame(maxWidth: .infinity)

            if let errorMessage = error.wrappedValue {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .onTapGesture {
            showPicker.wrappedValue.toggle()
        }
        .sheet(isPresented: showPicker, onDismiss: {
            showPicker.wrappedValue = false  // Ensure picker closes after selection
        }) {
            YearPicker(selectedYear: selectedYear)
        }
    }

    // MARK: - Form Validation
    private func validateForm() {
        errors.removeAll()
        if boatName.isEmpty { errors["boatName"] = "Boat Name is required." }
        if boatMake.isEmpty { errors["boatMake"] = "Boat Make is required." }
        if boatModel.isEmpty { errors["boatModel"] = "Boat Model is required." }
        if boatYear == nil { errors["boatYear"] = "Boat Year is required." }
        if boatSize.isEmpty { errors["boatSize"] = "Boat Size is required." }
        if boatCapacity.isEmpty { errors["boatCapacity"] = "Boat Capacity is required." }
    }
}

// MARK: - Toast Extension
extension View {
    func toast(isPresented: Bool, message: String, isSuccess: Bool) -> some View {
        ZStack {
            self
            if isPresented {
                VStack {
                    Spacer()
                    Text(message)
                        .foregroundColor(.white)
                        .padding()
                        .background(isSuccess ? Color.green : Color.red)
                        .cornerRadius(10)
                        .padding(.bottom, 20)
                }
                .transition(.slide)
                .animation(.easeInOut, value: isPresented)
            }
        }
    }
}


// MARK: - Preview
#Preview {
    CaptainRegStepThree(lastController: "CaptainProfileThree")
}

