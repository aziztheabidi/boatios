import SwiftUI

struct BusinessRegStepThree: View {
    @State private var businessDescription = ""
    @State private var dockStatus = "Select an option"
    @State private var showDockPopup = false
    @State private var errors: [String: String] = [:]
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: BusinessStepThreeViewModel
    @State private var showToast = false

    init(dependencies: AppDependencies = .live) {
        _viewModel = ObservedObject(wrappedValue: BusinessStepThreeViewModel(
            networkRepository: dependencies.networkRepository,
            sessionPreferences: dependencies.sessionPreferences
        ))
    }

    var isFormValid: Bool {
        return !businessDescription.isEmpty && (dockStatus == "Yes" || dockStatus == "No")
    }

    var body: some View {
        NavigationView {
            VStack {
                // Back Button
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "arrow.backward")
                        .foregroundColor(.black)
                }
                .padding(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Progress Bar
                Text("Please Add Business Info 3/4")
                    .padding(.top, -20)

                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(index < 3 ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 35, height: 8)
                    }
                }
                .padding()

                // Business Description
                HStack {
                    Text("Business Description")
                        .font(.headline)
                        .padding(.top, 10)
                    Spacer()
                }
                .padding(.horizontal)

                TextEditor(text: $businessDescription)
                    .frame(height: 150)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).stroke(errors["businessDescription"] == nil ? Color.gray : Color.red, lineWidth: 1))
                    .padding(.horizontal)

                if let errorMessage = errors["businessDescription"] {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                        .padding(.top, 5)
                }

                // Dock Question
                HStack {
                    Text("Does this business have a dock?")
                        .font(.headline)
                        .padding(.top, 10)
                    Spacer()
                }
                .padding(.horizontal)

                TextField("", text: $dockStatus)
                    .disabled(true)
                    .padding()
                    .frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 10).stroke(errors["dockStatus"] == nil ? Color.gray : Color.red, lineWidth: 1))
                    .onTapGesture { showDockPopup = true }
                    .padding(.horizontal)

                if let dockError = errors["dockStatus"] {
                    Text(dockError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                        .padding(.top, 5)
                }

                Spacer()

                Button(action: submitForm) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Save and Next")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .disabled(!isFormValid || viewModel.isLoading)

                NavigationLink(destination: BusinessStepRegFour(), isActive: $viewModel.shouldNavigate) {
                    EmptyView().navigationBarBackButtonHidden(true)
                }
            }
            .onTapGesture {
                UIApplication.shared.dismissKeyboard()
            }
            .overlay(
                VStack {
                    if !viewModel.message.isEmpty {
                        ToastView(message: viewModel.message, isPresented: $showToast)
                            .transition(.slide)
                            .animation(.easeInOut)
                    }
                }
                .padding(.top, 20),
                alignment: .top
            )
            .confirmationDialog("Does this business have a dock?", isPresented: $showDockPopup, titleVisibility: .visible) {
                Button("Yes") { dockStatus = "Yes" }
                Button("No") { dockStatus = "No" }
                Button("Cancel", role: .cancel) {}
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    func submitForm() {
        // Dismiss keyboard
        UIApplication.shared.dismissKeyboard()

        validateFields()
        let userId = viewModel.sessionUserId

        if errors.isEmpty && !userId.isEmpty {
            viewModel.send(.saveBusiness(description: businessDescription, isDock: dockStatus == "Yes", userId: userId))
        }
        showToast = true
    }

    func validateFields() {
        errors = [:]
        if businessDescription.isEmpty { errors["businessDescription"] = "Business description is required" }
        if dockStatus == "Select an option" { errors["dockStatus"] = "Please select Yes or No" }
    }
}

struct BusinessRegThree_Previews: PreviewProvider {
    static var previews: some View {
        BusinessRegStepThree()
    }
}


