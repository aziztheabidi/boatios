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
    @Binding var pickupLocation: DockLocation?
    @Binding var dropoffLocation: DockLocation?
    let onNavigateToCreateVoyage: () -> Void

    @EnvironmentObject var homeViewModel: VoyagerHomeViewModel
    @EnvironmentObject var uiFlowState: UIFlowState

    @StateObject private var viewModel: FindBoatPopUpViewModel

    init(
        showSheet: Binding<Bool>,
        pickupLocation: Binding<DockLocation?>,
        dropoffLocation: Binding<DockLocation?>,
        onNavigateToCreateVoyage: @escaping () -> Void,
        dependencies: AppDependencies
    ) {
        _showSheet = showSheet
        _pickupLocation = pickupLocation
        _dropoffLocation = dropoffLocation
        self.onNavigateToCreateVoyage = onNavigateToCreateVoyage
        _viewModel = StateObject(wrappedValue: FindBoatPopUpViewModel(networkRepository: dependencies.networkRepository))
    }

    // MARK: - Pure presentation state (belongs in the view)

    @State private var numberOfVoyagers: String = ""
    @State private var selectedVoyageCategory: VoyageCategory? = nil
    @State private var showVoyageCategoryDropdown = false
    @State private var showDockSheet = false
    @State private var selectedField: DockFieldType? = nil
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
                    .onAppear {
                        let selection = uiFlowState.businessVoyageSelection
                        uiFlowState.clearBusinessSelection()
                        viewModel.send(.onAppear(flowSelection: selection))
                        viewModel.send(.startKeyboardObservers)
                    }
                    .onDisappear {
                        viewModel.send(.stopKeyboardObservers)
                    }
                    .offset(y: -viewModel.state.keyboardOffset)
                    .animation(.easeOut(duration: 0.25), value: viewModel.state.keyboardOffset)
                    .onTapGesture { hideKeyboard() }
                    .ignoresSafeArea(.keyboard)
                    .onChange(of: viewModel.state.locationBindingPatch) { _, patch in
                        guard let patch else { return }
                        if let p = patch.pickup { pickupLocation = p }
                        if let d = patch.dropoff { dropoffLocation = d }
                        viewModel.send(.locationPatchConsumed)
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
                            onNavigateToCreateVoyage()
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
            Text("Current Date: \(viewModel.state.formattedHeaderDate)")
                .font(.footnote)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        }
        .padding(.top, 10)
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
    @Binding var pickupLocation: DockLocation?
    @Binding var dropoffLocation: DockLocation?
    let docks: [DockLocation]
    let onDockSelected: (DockLocation) -> Void
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
            onNavigateToCreateVoyage: {},
            dependencies: previewDependencies
        )
        .environmentObject(VoyagerHomeViewModel(
            networkRepository: AppNetworkRepository(apiClient: PreviewAPIClient()),
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
private let previewAPIClient = PreviewAPIClient()
private let previewDependencies    = AppDependencies(
    apiClient: previewAPIClient,
    sessionManager: previewSessionManager,
    preferences: previewPreferences,
    sessionPreferences: previewPreferences,
    tokenStore: previewTokenStore,
    dateFormatter: DateFormatterHelper(),
    routingNotifier: AppRoutingNotifier(),
    businessSaveMediaUploader: AlamofireBusinessSaveMediaUploader(tokenStore: previewTokenStore),
    businessRepository: BusinessRepository(apiClient: previewAPIClient),
    authRepository: AuthRepository(apiClient: previewAPIClient, sessionManager: previewSessionManager),
    networkRepository: AppNetworkRepository(apiClient: previewAPIClient),
    deviceIdentifierStore: previewPreferences
)

private final class PreviewAPIClient: APIClientProtocol {
    func request<T: Decodable>(
        endpoint: String, method: Alamofire.HTTPMethod,
        parameters: Alamofire.Parameters?,
        requiresAuth: Bool
    ) async throws -> T { throw APIError.invalidResponse }
}

private final class PreviewSessionPreferences: SessionPreferenceStoring, PreferenceStoring, DeviceIdentifierStoring {
    var isLoggedIn: Bool = false; var userRole: String = ""
    var missingStep: Int = 1;     var userID: String = ""
    var username: String = "";    var userEmail: String = ""
    var fromBusinessDetail: Bool = false
    var fcmToken: String?
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
