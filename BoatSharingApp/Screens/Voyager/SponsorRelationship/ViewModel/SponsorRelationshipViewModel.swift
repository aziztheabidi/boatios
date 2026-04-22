import SwiftUI

@MainActor
final class SponsorRelationshipViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let myself: VoyagerUser?
        let followers: [VoyagerUser]
        let followings: [VoyagerUser]
        let allSponsors: [VoyagerUser]
        let isLoading: Bool
        let errorMessage: String?
    }

    var state: State {
        State(
            myself: myself,
            followers: followed,
            followings: unfollowed,
            allSponsors: allSponsors,
            isLoading: isLoading,
            errorMessage: errorMessage
        )
    }

    // MARK: - Actions

    enum Action {
        case onAppear
        case retry
        case follow(voyagerId: String)
        case unfollow(voyagerId: String)
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear, .retry:
            fetchRelationship()
        case .follow(let id):
            performFollow(voyagerId: id)
        case .unfollow(let id):
            performUnfollow(voyagerId: id)
        }
    }

    // MARK: - Published state

    @Published var myself: VoyagerUser?
    @Published var followed: [VoyagerUser] = []
    @Published var unfollowed: [VoyagerUser] = []
    @Published var allSponsors: [VoyagerUser] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    private let networkRepository: AppNetworkRepositoryProtocol
    private let sessionPreferences: SessionPreferenceStoring

    init(networkRepository: AppNetworkRepositoryProtocol, sessionPreferences: SessionPreferenceStoring) {
        self.networkRepository = networkRepository
        self.sessionPreferences = sessionPreferences
    }

    // MARK: - Derived

    var currentUserId: String { sessionPreferences.userID }

    // MARK: - Private network methods

    private func fetchRelationship() {
        Task {
            do {
                let response = try await networkRepository.voyager_getRelationship()
                self.myself = response.obj.mySelf
                self.followed = response.obj.followed
                self.unfollowed = response.obj.unFollowed
                self.allSponsors = [response.obj.mySelf] + response.obj.followed
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func performFollow(voyagerId: String) {
        isLoading = true
        Task {
            do {
                _ = try await networkRepository.voyager_follow(parameters: ["VoyagerUserId": voyagerId])
                self.isLoading = false
                self.fetchRelationship()
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func performUnfollow(voyagerId: String) {
        isLoading = true
        Task {
            do {
                _ = try await networkRepository.voyager_unfollow(parameters: ["VoyagerUserId": voyagerId])
                self.isLoading = false
                self.fetchRelationship()
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

}

