import SwiftUI

@MainActor
final class PastVoyageViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let pastVoyages: [PastVoyage]
        let captainPastVoyages: [CaptainCompletedVoyage]
        let selectedController: String
        let isLoading: Bool
        let errorMessage: String?
        let preferredVoyagerName: String
    }

    var state: State {
        State(
            pastVoyages: pastVoyageDetails,
            captainPastVoyages: CaptainpastVoyageDetails,
            selectedController: selectedController,
            isLoading: isPastVoyageLoading,
            errorMessage: errorMessage,
            preferredVoyagerName: preferredVoyagerName
        )
    }

    // MARK: - Actions

    enum Action {
        case onAppear
        case onDisappear
        case retry
        case switchController(String)
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:       onAppearLoad()
        case .onDisappear:    hasCompletedInitialAppear = false
        case .retry:          loadData(for: selectedController)
        case .switchController(let c): loadData(for: c)
        }
    }

    // MARK: - Published state

    @Published var pastVoyageDetails: [PastVoyage] = []
    @Published var CaptainpastVoyageDetails: [CaptainCompletedVoyage] = []
    @Published var errorMessage: String?
    @Published var isPastVoyageLoading: Bool = false
    @Published var selectedController: String

    // MARK: - Dependencies

    private let networkRepository: AppNetworkRepositoryProtocol
    private let identityProvider: SessionPreferenceStoring
    private let initialRole: String
    private var hasCompletedInitialAppear = false

    init(networkRepository: AppNetworkRepositoryProtocol, identityProvider: SessionPreferenceStoring, initialRole: String) {
        self.networkRepository = networkRepository
        self.identityProvider = identityProvider
        self.initialRole = initialRole
        self.selectedController = initialRole
    }

    // MARK: - Derived

    var preferredVoyagerName: String { identityProvider.username }

    private var currentUserId: String? {
        let id = identityProvider.userID.trimmingCharacters(in: .whitespacesAndNewlines)
        return id.isEmpty ? nil : id
    }

    // MARK: - Private lifecycle

    private func onAppearLoad() {
        guard !hasCompletedInitialAppear else { return }
        hasCompletedInitialAppear = true
        loadData(for: initialRole)
    }

    private func loadData(for controller: String) {
        selectedController = controller
        if controller == "Voyager" {
            guard let userId = currentUserId else { errorMessage = "Missing user id."; return }
            fetchVoyagerPastVoyages(userId: userId)
        } else if controller == "Captain" {
            fetchCaptainPastVoyages()
        }
    }

    // MARK: - Private network

    private func fetchVoyagerPastVoyages(userId: String) {
        isPastVoyageLoading = true
        errorMessage = nil
        Task {
            do {
                let response = try await networkRepository.voyagerDashboard_getPastVoyages(userId: userId)
                self.isPastVoyageLoading = false
                if response.voyages.isEmpty {
                    self.errorMessage = "No past voyages found."
                    self.pastVoyageDetails = []
                } else {
                    self.errorMessage = nil
                    self.pastVoyageDetails = response.voyages
                }
            } catch {
                self.isPastVoyageLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func fetchCaptainPastVoyages() {
        isPastVoyageLoading = true
        errorMessage = nil
        Task {
            do {
                let response = try await networkRepository.captain_getPastVoyages()
                self.isPastVoyageLoading = false
                if response.voyages.isEmpty {
                    self.errorMessage = "No past voyages found."
                    self.CaptainpastVoyageDetails = []
                } else {
                    self.errorMessage = nil
                    self.CaptainpastVoyageDetails = response.voyages
                }
            } catch {
                self.isPastVoyageLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Public action helpers

    func getPastVoyages(userId: String) { fetchVoyagerPastVoyages(userId: userId) }
    func getCaptainPastVoyages() { fetchCaptainPastVoyages() }
    func loadInitialData(for controller: String) { loadData(for: controller) }
    func retry() { send(.retry) }
    func onAppearLoad_public() { send(.onAppear) }
    func resetInitialLoadForDismiss() { send(.onDisappear) }
}

