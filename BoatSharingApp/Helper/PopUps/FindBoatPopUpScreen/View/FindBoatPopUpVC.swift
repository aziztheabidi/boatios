import SwiftUI

// MARK: - Blur helper (UIKit bridge)

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) { uiView.effect = effect }
}

// MARK: - Main view

struct FindBoatPopUpVC: View {

    // MARK: - Bindings / injected data

    @Binding var showSheet: Bool
    @Binding var pickupLocation: Dock?
    @Binding var dropoffLocation: Dock?
    @Binding var moveToNext: Bool
    @Binding var moveToMenu: Bool

    @EnvironmentObject var homeViewModel: VoyagerHomeViewModel
    @EnvironmentObject var uiFlowState: UIFlowState

    @StateObject private var viewModel: FindBoatPopUpViewModel

    init(
        showSheet: Binding<Bool>,
        pickupLocation: Binding<Dock?>,
        dropoffLocation: Binding<Dock?>,
        moveToNext: Binding<Bool>,
        moveToMenu: Binding<Bool>,
        dependencies: AppDependencies
    ) {
        _showSheet         = showSheet
        _pickupLocation    = pickupLocation
        _dropoffLocation   = dropoffLocation
        _moveToNext        = moveToNext
        _moveToMenu        = moveToMenu
        _viewModel = StateObject(wrappedValue: FindBoatPopUpViewModel(apiClient: dependencies.apiClient))
    }

    // MARK: - Pure presentation state (belongs in the view)

    @State private var numberOfVoyagers: String = ""
    @State private var selectedVoyageCategory: VoyageCategory? = nil
    @State private var showVoyageCategoryDropdown = false
    @State private var showDockSheet = false
    @State private var selectedField: DockFieldType? = nil
    @State private var keyboardHeight: CGFloat = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            GeometryReader { geometry in
                NavigationStack {
                    ZStack {
                        formContent
                        if showDockSheet {
                            // Handled via .sheet below — this block kept intentionally empty
                            EmptyView()
                        }
                    }
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                    .clipped()
                    .padding(.top, 10)
                    .sheet(isPresented: $showDockSheet) { dockSelectionSheet }
                    .onAppear { handleOnAppear() }
                    .offset(y: -keyboardHeight)
                    .animation(.easeOut(duration: 0.25), value: keyboardHeight)
                    .onTapGesture { hideKeyboard() }
                    .ignoresSafeArea(.keyboard)
                    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { note in
                        if let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                            keyboardHeight = frame.height
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                        keyboardHeight = 0
                    }
                    // Validation toast (non-modal)
                    .overlay(
                        Group {
                            if let error = viewModel.validationError, error != .none, !error.requiresCustomAlert {
                                ToastView(message: error.message, isPresented: .constant(true))
                            }
                        }
                    )
                    // Validation custom alert (modal)
                    .overlay(
                        Group {
                            if let error = viewModel.validationError, error.requiresCustomAlert {
                                CustomAlertView(
                                    message: error.message,
                                    isPresented: Binding(
                                        get: { error.requiresCustomAlert },
                                        set: { if !$0 { viewModel.send(.clearValidationError) } }
                                    )
                                )
                            }
                        }
                    )
                    // Navigation: ready to proceed
                    .onChange(of: viewModel.isReadyToBook) { _, ready in
                        if ready {
                            uiFlowState.clearBusinessSelection()
                            showSheet = false
                            moveToNext = true
                            viewModel.send(.clearValidationError)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Form body

    private var formContent: some View {
        VStack(spacing: 16) {
            headerView
            voyageCategorySection
            locationFields
            voyagerCountField
            createVoyageButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack {
            Text("Please Confirm your details before booking")
                .font(.headline)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.top, 15)
            Text("Current Date: \(formattedCurrentDate)")
                .font(.footnote)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        }
        .padding(.top, 10)
    }

    private var formattedCurrentDate: String {
        let f = DateFormatter()
        f.dateFormat = "dd, MMMM, yyyy"
        f.timeZone = TimeZone(identifier: "Asia/Karachi")
        return f.string(from: Date())
    }

    // MARK: - Voyage category

    private var voyageCategorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Voyage Category")
                .font(.subheadline)
                .foregroundColor(.gray)

            categorySelectorButton

            if showVoyageCategoryDropdown {
                categoryDropdown
            }
        }
        .padding(.horizontal)
    }

    private var categorySelectorButton: some View {
        HStack {
            Image(systemName: "sailboat.fill").foregroundColor(.blue).frame(width: 24)
            Text(selectedVoyageCategory?.name ?? "Select Voyage Category")
                .foregroundColor(selectedVoyageCategory == nil ? .gray : .black)
            Spacer()
            Image(systemName: "chevron.down").foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 0.5))
        .cornerRadius(10)
        .contentShape(Rectangle())
        .onTapGesture { showVoyageCategoryDropdown.toggle(); hideKeyboard() }
    }

    private var categoryDropdown: some View {
        VStack(spacing: 0) {
            if viewModel.voyageCategories.isEmpty {
                Text("No categories available")
                    .foregroundColor(.gray).padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
            } else {
                ForEach(viewModel.voyageCategories) { category in
                    categoryRow(category)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
        .zIndex(2)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: showVoyageCategoryDropdown)
    }

    private func categoryRow(_ category: VoyageCategory) -> some View {
        Text(category.name)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 0).stroke(Color.gray.opacity(0.5), lineWidth: 0.5))
            .contentShape(Rectangle())
            .onTapGesture {
                // Pure presentation: update local selection + forward category ID to draft
                selectedVoyageCategory = category
                showVoyageCategoryDropdown = false
                viewModel.send(.selectCategory(category, updateDraft: { id in
                    uiFlowState.voyageDraft.voyageCategoryID = id
                }))
                hideKeyboard()
            }
    }

    // MARK: - Location fields

    private var locationFields: some View {
        Group {
            locationField(
                label: "Pickup Location",
                icon: "mappin.and.ellipse", iconColor: .blue,
                selectedName: pickupLocation?.name,
                placeholder: "Select pickup location",
                chevronColor: .blue
            ) {
                selectedField = .current
                showDockSheet = true
                hideKeyboard()
            }

            locationField(
                label: "Dropoff Location",
                icon: "mappin", iconColor: .red,
                selectedName: dropoffLocation?.name,
                placeholder: "Select dropoff location",
                chevronColor: .red
            ) {
                selectedField = .dropoff
                showDockSheet = true
                hideKeyboard()
            }
        }
    }

    private func locationField(
        label: String,
        icon: String,
        iconColor: Color,
        selectedName: String?,
        placeholder: String,
        chevronColor: Color,
        onTap: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label).font(.subheadline).foregroundColor(.gray)
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundColor(iconColor).frame(width: 24)
                Text(selectedName ?? placeholder)
                    .foregroundColor(selectedName == nil ? .gray : .black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .foregroundColor(chevronColor)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding()
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
            .cornerRadius(10)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
        }
        .padding(.horizontal)
    }

    // MARK: - Voyager count

    private var voyagerCountField: some View {
        CustomTextField(
            title: "Number of Voyagers",
            text: $numberOfVoyagers,
            iconName: "person.3.fill",
            iconColor: .blue,
            keyboardType: .numberPad
        )
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { hideKeyboard() }
            }
        }
    }

    // MARK: - Book button

    private var createVoyageButton: some View {
        Button {
            viewModel.send(.attemptBook(
                pickup: pickupLocation,
                dropoff: dropoffLocation,
                voyagerCount: numberOfVoyagers,
                category: selectedVoyageCategory,
                commitDraft: { count, pickupName, dropoffName in
                    uiFlowState.voyageDraft.numberOfVoyagers  = count
                    uiFlowState.voyageDraft.pickupLocationName  = pickupName
                    uiFlowState.voyageDraft.dropOffLocationName = dropoffName
                }
            ))
        } label: {
            Text("Create Voyage")
                .font(.headline).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding()
                .background(Color.blue).cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.bottom, 70)
    }

    // MARK: - Dock selection sheet

    private var dockSelectionSheet: some View {
        DockSelectionSheetView(
            selectedField: selectedField ?? .current,
            pickupLocation: $pickupLocation,
            dropoffLocation: $dropoffLocation,
            docks: homeViewModel.docks,
            onDockSelected: { dock in
                // Forward dock selection to ViewModel (which updates the draft)
                viewModel.send(.selectDockForField(
                    selectedField ?? .current,
                    dock: dock,
                    updateDraft: { dockId, dockName, field in
                        if field == .current {
                            uiFlowState.voyageDraft.pickupDockID        = dockId
                            uiFlowState.voyageDraft.pickupLocationName  = dockName
                        } else {
                            uiFlowState.voyageDraft.dropOffDockID       = dockId
                            uiFlowState.voyageDraft.dropOffLocationName = dockName
                        }
                    }
                ))
                showDockSheet = false
            }
        )
    }

    // MARK: - Private helpers

    private func handleOnAppear() {
        viewModel.send(.onAppear)
        // Apply business pre-selection if arriving from a business dock tap
        if let selection = uiFlowState.businessVoyageSelection {
            viewModel.send(.applyBusinessSelection(
                selection,
                pickupSetter:  { pickupLocation = $0 },
                dropoffSetter: { dropoffLocation = $0 }
            ))
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.dismissKeyboard()
    }
}

// MARK: - CustomTextField (shared component)

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let iconName: String
    let iconColor: Color
    var keyboardType: UIKeyboardType = .default
    var isTappable: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline).foregroundColor(.gray)
            HStack {
                Image(systemName: iconName).foregroundColor(iconColor).frame(width: 24)
                if isTappable {
                    Text(text.isEmpty ? "Select \(title.lowercased())" : text)
                        .foregroundColor(text.contains("Select") ? .gray : .black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    TextField("Enter \(title.lowercased())", text: $text)
                        .keyboardType(keyboardType)
                        .disabled(isTappable)
                }
            }
            .padding()
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

// MARK: - CalendarView (shared component)

struct CalendarView: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack {
            Text("Select Date").font(.title).padding()
            DatePicker("Choose a Date", selection: .constant(Date()), displayedComponents: .date)
                .datePickerStyle(.graphical).padding()
            Button("Done") { presentationMode.wrappedValue.dismiss() }
                .padding().background(Color.blue).foregroundColor(.white).cornerRadius(10)
        }
    }
}

// MARK: - DockSelectionSheetView (shared component)

struct DockSelectionSheetView: View {
    let selectedField: DockFieldType
    @Binding var pickupLocation: Dock?
    @Binding var dropoffLocation: Dock?
    let docks: [Dock]
    let onDockSelected: (Dock) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            Group {
                if docks.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "location.slash").font(.system(size: 50)).foregroundColor(.gray)
                        Text("No docks available").font(.headline).foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(docks) { dock in
                        Button {
                            if selectedField == .current { pickupLocation = dock }
                            else { dropoffLocation = dock }
                            onDockSelected(dock)
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dock.name).font(.headline).foregroundColor(.black)
                                    Text(dock.address.isEmpty ? "No Address Available" : dock.address)
                                        .font(.subheadline).foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.gray).font(.system(size: 12))
                            }
                            .padding(.leading, 20).padding(.vertical, 8)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(selectedField == .current ? "Select Pickup Location" : "Select Dropoff Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

struct ConfirmView_Previews: PreviewProvider {
    static var previews: some View {
        FindBoatPopUpVC(
            showSheet: .constant(true),
            pickupLocation: .constant(nil),
            dropoffLocation: .constant(nil),
            moveToNext: .constant(false),
            moveToMenu: .constant(false),
            dependencies: previewDependencies
        )
        .environmentObject(VoyagerHomeViewModel(
            apiClient: PreviewAPIClient(),
            identityProvider: PreviewSessionPreferences()
        ))
        .environmentObject(UIFlowState())
    }
}

// MARK: - Preview support types

private let previewPreferences     = PreviewSessionPreferences()
private let previewKeychain        = PreviewKeychainStore()
private let previewTokenStore      = TokenStore(keychain: previewKeychain)
private let previewSessionManager  = SessionManager(
    tokenStore: previewTokenStore,
    preferences: previewPreferences,
    refreshService: PreviewRefreshTokenService()
)
private let previewDependencies    = AppDependencies(
    apiClient: PreviewAPIClient(),
    sessionManager: previewSessionManager,
    preferences: previewPreferences,
    sessionPreferences: previewPreferences,
    tokenStore: previewTokenStore,
    dateFormatter: DateFormatterHelper(),
    routingNotifier: AppRoutingNotifier(),
    businessSaveMediaUploader: AlamofireBusinessSaveMediaUploader(tokenStore: previewTokenStore)
)

private final class PreviewAPIClient: APIClientProtocol {
    func request<T: Decodable>(
        endpoint: String, method: Alamofire.HTTPMethod,
        parameters: Alamofire.Parameters?,
        encoding: any Alamofire.ParameterEncoding,
        requiresAuth: Bool
    ) async throws -> T { throw APIError.invalidResponse }
}

private final class PreviewSessionPreferences: SessionPreferenceStoring, PreferenceStoring {
    var isLoggedIn: Bool = false; var userRole: String = ""
    var missingStep: Int = 1;     var userID: String = ""
    var username: String = "";    var userEmail: String = ""
    var fromBusinessDetail: Bool = false
    func clearSessionPreferences() { isLoggedIn = false; userRole = ""; missingStep = 1; userID = ""; username = ""; userEmail = "" }
}

private struct PreviewRefreshTokenService: RefreshTokenServicing {
    func refreshToken(accessToken: String, refreshToken: String) async throws -> SessionTokenData {
        throw APIError.invalidResponse
    }
}

private final class PreviewKeychainStore: KeychainStoring {
    private var storage: [String: String] = [:]
    func saveSecureValue(_ value: String, for key: String) -> Bool { storage[key] = value; return true }
    func retrieveSecureValue(for key: String) -> String? { storage[key] }
    func deleteSecureValue(for key: String) -> Bool { storage.removeValue(forKey: key); return true }
}
