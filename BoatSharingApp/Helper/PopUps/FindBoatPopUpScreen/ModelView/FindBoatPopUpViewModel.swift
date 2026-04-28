import SwiftUI
import UIKit
import Combine

@MainActor
final class FindBoatPopUpViewModel: ObservableObject {

    struct State {
        let voyageCategories: [VoyageCategory]
        let isLoadingCategories: Bool
        let categoryErrorMessage: String?
        let isTokenExpired: Bool
        let validationError: ValidationError?
        let isReadyToBook: Bool
        let formattedHeaderDate: String
        let keyboardOffset: CGFloat
        let locationBindingPatch: LocationBindingPatch?
    }

    struct LocationBindingPatch: Equatable {
        var pickup: DockLocation?
        var dropoff: DockLocation?
    }

    var state: State {
        State(
            voyageCategories: voyageCategories,
            isLoadingCategories: isLoadingCategories,
            categoryErrorMessage: categoryErrorMessage,
            isTokenExpired: isTokenExpired,
            validationError: validationError,
            isReadyToBook: isReadyToBook,
            formattedHeaderDate: formattedHeaderDate,
            keyboardOffset: keyboardOffset,
            locationBindingPatch: locationBindingPatch
        )
    }

    enum ValidationError: Equatable {
        case missingPickup
        case missingDropoff
        case missingVoyagerCount
        case missingCategory
        case categoryCapacityExceededSmall
        case categoryCapacityTooLowLarge
        case none

        var message: String {
            switch self {
            case .missingPickup: return "Please select a pickup location."
            case .missingDropoff: return "Please select a dropoff location."
            case .missingVoyagerCount: return "Please enter the number of voyagers."
            case .missingCategory: return "Please select a voyage category."
            case .categoryCapacityExceededSmall: return "Please select 29 or less than 29 voyagers as per selected category."
            case .categoryCapacityTooLowLarge: return "Please select 30 or more than 30 voyagers as per selected category."
            case .none: return ""
            }
        }

        var requiresCustomAlert: Bool {
            switch self {
            case .categoryCapacityExceededSmall, .categoryCapacityTooLowLarge: return true
            default: return false
            }
        }
    }

    enum Action {
        case onAppear(flowSelection: BusinessVoyageSelection?)
        case loadCategories
        case locationPatchConsumed
        case selectDockForField(DockFieldType, dock: DockLocation, updateDraft: (String, String, DockFieldType) -> Void)
        case selectCategory(VoyageCategory, updateDraft: (String) -> Void)
        case attemptBook(
            pickup: DockLocation?, dropoff: DockLocation?,
            voyagerCount: String,
            category: VoyageCategory?,
            commitDraft: (String, String, String) -> Void
        )
        case clearValidationError
        case tokenExpiredAcknowledged
        case startKeyboardObservers
        case stopKeyboardObservers
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear(let flowSelection):
            refreshHeaderDate()
            fetchVoyageCategories()
            if let flowSelection {
                computeLocationPatch(for: flowSelection)
            }
        case .loadCategories:
            fetchVoyageCategories()
        case .locationPatchConsumed:
            locationBindingPatch = nil
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
        case .startKeyboardObservers:
            startKeyboardObservers()
        case .stopKeyboardObservers:
            stopKeyboardObservers()
        }
    }

    @Published var voyageCategories: [VoyageCategory] = []
    @Published var isLoadingCategories: Bool = false
    @Published var categoryErrorMessage: String?
    @Published var isTokenExpired: Bool = false
    @Published var validationError: ValidationError?
    @Published var isReadyToBook: Bool = false
    @Published private(set) var formattedHeaderDate: String = ""
    @Published private(set) var keyboardOffset: CGFloat = 0
    @Published private(set) var locationBindingPatch: LocationBindingPatch?

    private let networkRepository: AppNetworkRepositoryProtocol
    private var keyboardCancellables = Set<AnyCancellable>()
    private let headerDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd, MMMM, yyyy"
        f.timeZone = TimeZone(identifier: "Asia/Karachi")
        return f
    }()

    init(networkRepository: AppNetworkRepositoryProtocol) {
        self.networkRepository = networkRepository
        refreshHeaderDate()
    }

    deinit {
        // Combine subscriptions cancelled with cancellables deallocation
    }

    func getVoyageCategories() { send(.onAppear(flowSelection: nil)) }

    private func refreshHeaderDate() {
        formattedHeaderDate = headerDateFormatter.string(from: Date())
    }

    private func computeLocationPatch(for selection: BusinessVoyageSelection) {
        let dock = DockLocation.businessSelection(businessID: selection.businessID, displayName: selection.businessName)
        switch selection.voyageType {
        case .pickup:
            locationBindingPatch = LocationBindingPatch(pickup: dock, dropoff: nil)
        case .dropoff:
            locationBindingPatch = LocationBindingPatch(pickup: nil, dropoff: dock)
        }
    }

    private func startKeyboardObservers() {
        keyboardCancellables.removeAll()
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] note in
                guard let self else { return }
                if let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    self.keyboardOffset = frame.height
                }
            }
            .store(in: &keyboardCancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.keyboardOffset = 0 }
            .store(in: &keyboardCancellables)
    }

    private func stopKeyboardObservers() {
        keyboardCancellables.removeAll()
        keyboardOffset = 0
    }

    private func applyDockSelection(
        field: DockFieldType,
        dock: DockLocation,
        updateDraft: (String, String, DockFieldType) -> Void
    ) {
        updateDraft(String(dock.dockTypeId), dock.name, field)
    }

    private func validateAndBook(
        pickup: DockLocation?,
        dropoff: DockLocation?,
        voyagerCount: String,
        category: VoyageCategory?,
        commitDraft: (String, String, String) -> Void
    ) {
        let count = voyagerCount.trimmingCharacters(in: .whitespacesAndNewlines)

        if pickup == nil { validationError = .missingPickup; return }
        if dropoff == nil { validationError = .missingDropoff; return }
        if count.isEmpty { validationError = .missingVoyagerCount; return }
        if category == nil { validationError = .missingCategory; return }

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
        commitDraft(
            count,
            pickup?.name ?? "",
            dropoff?.name ?? ""
        )
    }

    private func fetchVoyageCategories() {
        isLoadingCategories = true
        categoryErrorMessage = nil
        Task { @MainActor in
            do {
                let response = try await networkRepository.lookup_voyageCategories()
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
}
