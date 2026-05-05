import SwiftUI
import Combine

@MainActor
final class BusinessVoyageViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let followedBusinesses: [BusinessRelationship]
        let unfollowedBusinesses: [BusinessRelationship]
        let isLoading: Bool
        let isTokenExpired: Bool
        let errorMessage: String?
        let successMessage: String?
    }

    var state: State {
        State(
            followedBusinesses: followedBusinesses,
            unfollowedBusinesses: unfollowedBusinesses,
            isLoading: isLoading,
            isTokenExpired: isTokenExpired,
            errorMessage: errorMessage,
            successMessage: successMessage
        )
    }

    // MARK: - Actions

    enum Action {
        case onAppear
        case onDisappear
        case retry
        case followBusiness(id: Int)
        case unfollowBusiness(id: Int)
        case tokenExpiredAcknowledged
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear, .retry: fetchBusinessRelationship()
        case .onDisappear:      break
        case .followBusiness(let id):   performFollowBusiness(id: id)
        case .unfollowBusiness(let id): performUnfollowBusiness(id: id)
        case .tokenExpiredAcknowledged: isTokenExpired = false
        }
    }

    // MARK: - Published state

    @Published var followedBusinesses: [BusinessRelationship] = []
    @Published var unfollowedBusinesses: [BusinessRelationship] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading: Bool = false
    @Published var isTokenExpired: Bool = false

    // MARK: - Dependencies

    private let networkRepository: AppNetworkRepositoryProtocol

    init(networkRepository: AppNetworkRepositoryProtocol) {
        self.networkRepository = networkRepository
    }

    // MARK: - Private network

    private func fetchBusinessRelationship() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let response = try await networkRepository.voyager_getBusinessRelationship()
                self.isLoading = false
                if response.status == .success {
                    self.followedBusinesses = response.obj.followed
                    self.unfollowedBusinesses = response.obj.unFollowed
                } else {
                    self.errorMessage = response.message
                }
            } catch let error as APIError {
                self.isLoading = false
                if case .unauthorized = error { self.isTokenExpired = true }
                else { self.errorMessage = error.localizedDescription }
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func performFollowBusiness(id: Int) {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        Task {
            do {
                let response = try await networkRepository.voyager_followBusiness(businessDockId: id)
                self.isLoading = false
                if response.status.isSuccess {
                    self.successMessage = response.message
                    self.fetchBusinessRelationship()
                } else {
                    self.errorMessage = response.message
                }
            } catch let error as APIError {
                self.isLoading = false
                if case .unauthorized = error { self.isTokenExpired = true }
                else { self.errorMessage = error.localizedDescription }
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func performUnfollowBusiness(id: Int) {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        Task {
            do {
                let response = try await networkRepository.voyager_unfollowBusiness(businessDockId: id)
                self.isLoading = false
                if response.status.isSuccess {
                    self.successMessage = response.message
                    self.fetchBusinessRelationship()
                } else {
                    self.errorMessage = response.message
                }
            } catch let error as APIError {
                self.isLoading = false
                if case .unauthorized = error { self.isTokenExpired = true }
                else { self.errorMessage = error.localizedDescription }
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func getBusinessRelationship() { send(.onAppear) }
}

