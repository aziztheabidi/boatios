import SwiftUI
import Alamofire

@MainActor
final class FindBoatPopUpViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let voyageCategories: [VoyageCategory]
        let isLoadingCategories: Bool
        let categoryErrorMessage: String?
        let isTokenExpired: Bool
        let validationError: ValidationError?
        let isReadyToBook: Bool
    }

    var state: State {
        State(
            voyageCategories: voyageCategories,
            isLoadingCategories: isLoadingCategories,
            categoryErrorMessage: categoryErrorMessage,
            isTokenExpired: isTokenExpired,
            validationError: validationError,
            isReadyToBook: isReadyToBook
        )
    }

    // MARK: - Validation errors (value type — view switches on this, not scattered booleans)

    enum ValidationError: Equatable {
        case missingPickup
        case missingDropoff
        case missingVoyagerCount
        case missingCategory
        case categoryCapacityExceededSmall   // cat 1, >29
        case categoryCapacityTooLowLarge     // cat 2, <30
        case none

        var message: String {
            switch self {
            case .missingPickup:              return "Please select a pickup location."
            case .missingDropoff:             return "Please select a dropoff location."
            case .missingVoyagerCount:        return "Please enter the number of voyagers."
            case .missingCategory:            return "Please select a voyage category."
            case .categoryCapacityExceededSmall: return "Please select 29 or less than 29 voyagers as per selected category."
            case .categoryCapacityTooLowLarge:   return "Please select 30 or more than 30 voyagers as per selected category."
            case .none:                       return ""
            }
        }

        /// true = show a custom alert modal; false = show inline toast
        var requiresCustomAlert: Bool {
            switch self {
            case .categoryCapacityExceededSmall, .categoryCapacityTooLowLarge: return true
            default: return false
            }
        }
    }

    // MARK: - Actions

    enum Action {
        case onAppear
        case loadCategories
        case applyBusinessSelection(BusinessVoyageSelection, pickupSetter: (Dock) -> Void, dropoffSetter: (Dock) -> Void)
        case selectDockForField(DockFieldType, dock: Dock, updateDraft: (String, String, DockFieldType) -> Void)
        case selectCategory(VoyageCategory, updateDraft: (String) -> Void)
        case attemptBook(
            pickup: Dock?, dropoff: Dock?,
            voyagerCount: String,
            category: VoyageCategory?,
            commitDraft: (String, String, String) -> Void
        )
        case clearValidationError
        case tokenExpiredAcknowledged
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            fetchVoyageCategories()
        case .loadCategories:
            fetchVoyageCategories()
        case .applyBusinessSelection(let selection, let pickupSetter, let dropoffSetter):
            applyBusinessSelection(selection, pickupSetter: pickupSetter, dropoffSetter: dropoffSetter)
        case .selectDockForField(let field, let dock, let updateDraft):
            applyDockSelection(field: field, dock: dock, updateDraft: updateDraft)
        case .selectCategory(let category, let updateDraft):
            updateDraft(String(category.id))
        case .attemptBook(let pickup, let dropoff, let count, let category, let commitDraft):
            validateAndBook(pickup: pickup, dropoff: dropoff, voyagerCount: count, category: category, commitDraft: commitDraft)
        case .clearValidationError:
            validationError = nil
            isReadyToBook = false
        case .tokenExpiredAcknowledged:
            isTokenExpired = false
        }
    }

    // MARK: - Published state

    @Published var voyageCategories: [VoyageCategory] = []
    @Published var isLoadingCategories: Bool = false
    @Published var categoryErrorMessage: String?
    @Published var isTokenExpired: Bool = false
    @Published var validationError: ValidationError?
    @Published var isReadyToBook: Bool = false

    // MARK: - Dependencies

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    // MARK: - Private logic

    private func applyBusinessSelection(
        _ selection: BusinessVoyageSelection,
        pickupSetter: (Dock) -> Void,
        dropoffSetter: (Dock) -> Void
    ) {
        let dock = Dock(businessID: selection.businessID, name: selection.businessName)
        switch selection.voyageType {
        case .pickup:  pickupSetter(dock)
        case .dropoff: dropoffSetter(dock)
        }
    }

    private func applyDockSelection(
        field: DockFieldType,
        dock: Dock,
        updateDraft: (String, String, DockFieldType) -> Void
    ) {
        updateDraft(String(dock.dockTypeId), dock.name, field)
    }

    private func validateAndBook(
        pickup: Dock?,
        dropoff: Dock?,
        voyagerCount: String,
        category: VoyageCategory?,
        commitDraft: (String, String, String) -> Void
    ) {
        let count = voyagerCount.trimmingCharacters(in: .whitespacesAndNewlines)

        if pickup == nil              { validationError = .missingPickup;       return }
        if dropoff == nil             { validationError = .missingDropoff;      return }
        if count.isEmpty              { validationError = .missingVoyagerCount; return }
        if category == nil            { validationError = .missingCategory;     return }

        if let cat = category, let n = Int(count) {
            if cat.id == 1, n > 29 {
                validationError = .categoryCapacityExceededSmall; return
            }
            if cat.id == 2, n < 30 {
                validationError = .categoryCapacityTooLowLarge; return
            }
        }

        validationError = .none
        isReadyToBook = true
        // Caller commits the draft and dismisses the sheet
        commitDraft(
            count,
            pickup?.name ?? "",
            dropoff?.name ?? ""
        )
    }

    // MARK: - Private network

    private func fetchVoyageCategories() {
        isLoadingCategories = true
        categoryErrorMessage = nil
        Task {
            do {
                let response: VoyageCategoryResponse = try await apiClient.request(
                    endpoint: "/Lookup/VoyageCategory",
                    method: .get,
                    parameters: nil,
                    encoding: JSONEncoding.default,
                    requiresAuth: true
                )
                self.isLoadingCategories = false
                self.voyageCategories = response.categories
            } catch let error as APIError {
                self.isLoadingCategories = false
                if case .unauthorized = error { self.isTokenExpired = true }
                else { self.categoryErrorMessage = error.localizedDescription }
            } catch {
                self.isLoadingCategories = false
                self.categoryErrorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Legacy call-site compat

    func getVoyageCategories() { send(.onAppear) }
}
