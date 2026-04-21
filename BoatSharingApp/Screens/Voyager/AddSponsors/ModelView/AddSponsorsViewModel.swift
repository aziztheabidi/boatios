import SwiftUI

@MainActor
final class AddSponsorsViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let allSponsors: [VoyagerProfile]
        let myProfile: VoyagerProfile?
        let followedVoyagers: [VoyagerProfile]
        let isLoading: Bool
        let errorMessage: String?
    }

    var state: State {
        State(
            allSponsors: allSponsors,
            myProfile: myProfile,
            followedVoyagers: followedVoyagers,
            isLoading: isLoading,
            errorMessage: errorMessage
        )
    }

    // MARK: - Actions

    enum Action {
        case onAppear
        case retry
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear, .retry:
            fetchFollowedVoyagers()
        }
    }

    // MARK: - Published state

    @Published var myProfile: VoyagerProfile?
    @Published var followedVoyagers: [VoyagerProfile] = []
    @Published var allSponsors: [VoyagerProfile] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    private let apiClient: APIClientProtocol
    private let sessionPreferences: SessionPreferenceStoring

    init(apiClient: APIClientProtocol, sessionPreferences: SessionPreferenceStoring) {
        self.apiClient = apiClient
        self.sessionPreferences = sessionPreferences
    }

    // MARK: - Derived

    private var currentUserId: String? {
        let id = sessionPreferences.userID.trimmingCharacters(in: .whitespacesAndNewlines)
        return id.isEmpty ? nil : id
    }

    // MARK: - Private network

    private func fetchFollowedVoyagers() {
        isLoading = true
        guard let userId = currentUserId else {
            isLoading = false
            errorMessage = "Missing user id."
            return
        }
        Task {
            do {
                let response: AddSponsorsModel = try await apiClient.request(
                    endpoint: "/VoyagerDashboard/GetFollowedVoyagers?UserId=\(userId)",
                    method: .get,
                    parameters: nil,
                    requiresAuth: true
                )
                self.isLoading = false
                if response.status == 200 {
                    self.myProfile = response.obj.mySelf
                    self.followedVoyagers = response.obj.followed
                    self.allSponsors = [response.obj.mySelf] + response.obj.followed
                } else {
                    self.errorMessage = response.message
                }
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Legacy call-site compat

    func getFollowedVoyagers() { send(.onAppear) }
}
