import SwiftUI
import Combine

@MainActor
final class BusinessActiveVoyageViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let voyages: [VoyageDetail]
        let errorMessage: String?
        let isLoading: Bool
        let bannerMessage: String
    }

    var state: State {
        State(
            voyages: voyages,
            errorMessage: errorMessage,
            isLoading: isLoading,
            bannerMessage: activeVoyagesBannerMessage
        )
    }

    // MARK: - Actions

    enum Action {
        case onAppear
        case onDisappear
        case retry
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:   onAppearLoad()
        case .onDisappear: hasLoaded = false
        case .retry:      fetchVoyages()
        }
    }

    // MARK: - Published state

    @Published var voyages: [VoyageDetail] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    private let networkRepository: AppNetworkRepositoryProtocol
    private let sessionPreferences: SessionPreferenceStoring
    private var hasLoaded = false

    init(networkRepository: AppNetworkRepositoryProtocol, sessionPreferences: SessionPreferenceStoring) {
        self.networkRepository = networkRepository
        self.sessionPreferences = sessionPreferences
    }

    // MARK: - Derived

    var greetingUsername: String {
        let name = sessionPreferences.username
        return name.isEmpty ? "Username" : name
    }

    var activeVoyagesBannerMessage: String {
        "Hey \(greetingUsername), here are your active voyages."
    }

    // MARK: - Private lifecycle

    private func onAppearLoad() {
        guard !hasLoaded else { return }
        hasLoaded = true
        fetchVoyages()
    }

    // MARK: - Private network

    private func fetchVoyages() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let response = try await networkRepository.business_getActiveVoyages()
                self.isLoading = false
                if response.status == 200 {
                    self.voyages = response.obj
                } else {
                    self.errorMessage = response.message
                }
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Public action helpers

    func getVoyages() { fetchVoyages() }
    func retry() { send(.retry) }
    func resetInitialLoadForDismiss() { send(.onDisappear) }
}

