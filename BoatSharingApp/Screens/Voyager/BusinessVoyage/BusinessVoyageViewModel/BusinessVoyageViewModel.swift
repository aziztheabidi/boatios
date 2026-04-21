import SwiftUI

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

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    // MARK: - Private network

    private func fetchBusinessRelationship() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let response: BusinessVoyageModel = try await apiClient.request(
                    endpoint: "/Voyager/GetBusinessRelationship",
                    method: .get,
                    parameters: nil,
                    requiresAuth: true
                )
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
                let response: FollowBusinessUpdateResponse = try await apiClient.request(
                    endpoint: "/Voyager/FollowBusiness",
                    method: .post,
                    parameters: ["BusinessDockId": id],
                    requiresAuth: true
                )
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
                let response: FollowBusinessUpdateResponse = try await apiClient.request(
                    endpoint: "/Voyager/UnFollowBusiness",
                    method: .post,
                    parameters: ["BusinessDockId": id],
                    requiresAuth: true
                )
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

    // MARK: - Legacy call-site compat (completion block preserved for existing view call-sites)

    func getBusinessRelationship() { send(.onAppear) }

    func followedBusinessVoyage(businessId: Int, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        Task {
            do {
                let response: FollowBusinessUpdateResponse = try await apiClient.request(
                    endpoint: "/Voyager/FollowBusiness",
                    method: .post,
                    parameters: ["BusinessDockId": businessId],
                    requiresAuth: true
                )
                self.isLoading = false
                if response.status.isSuccess {
                    self.successMessage = response.message
                    completion(true)
                } else {
                    self.errorMessage = response.message
                    completion(false)
                }
            } catch let error as APIError {
                self.isLoading = false
                if case .unauthorized = error { self.isTokenExpired = true }
                else { self.errorMessage = error.localizedDescription }
                completion(false)
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                completion(false)
            }
        }
    }

    func UnfollowedBusinessVoyage(businessId: Int, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        Task {
            do {
                let response: FollowBusinessUpdateResponse = try await apiClient.request(
                    endpoint: "/Voyager/UnFollowBusiness",
                    method: .post,
                    parameters: ["BusinessDockId": businessId],
                    requiresAuth: true
                )
                self.isLoading = false
                if response.status.isSuccess {
                    self.successMessage = response.message
                    completion(true)
                } else {
                    self.errorMessage = response.message
                    completion(false)
                }
            } catch let error as APIError {
                self.isLoading = false
                if case .unauthorized = error { self.isTokenExpired = true }
                else { self.errorMessage = error.localizedDescription }
                completion(false)
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                completion(false)
            }
        }
    }
}
