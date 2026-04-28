import XCTest
import Combine
@testable import BoatSharingApp

@MainActor
final class RoleSelectionViewModelTests: XCTestCase {

    func testUpdateRoleWithoutAccessTokenFailsFast() {
        let session = RoleSelectionSessionManager()
        session.accessToken = nil
        let viewModel = RoleSelectionViewModel(
            networkRepository: AppNetworkRepository(apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) }),
            sessionManager: session,
            sessionPreferences: ViewModelSessionPreferenceStore()
        )

        viewModel.send(.updateRole(userId: "u-1", role: "Voyager"))

        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertFalse(viewModel.state.isAuthenticated)
        XCTAssertEqual(viewModel.state.errorMessage, "Authentication token missing. Please try again.")
    }

    func testUpdateRoleSuccessAuthenticatesAndSavesReturnedTokens() async {
        let session = RoleSelectionSessionManager()
        session.accessToken = "initial-access"
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == "/Account/UpdateRole" {
                return .success(
                    RoleSectionModel(
                        Status: 200,
                        Message: "OK",
                        obj: RoleRegistrationData(accessToken: "new-access", refreshToken: "new-refresh")
                    )
                )
            }
            return .failure(APIError.invalidResponse)
        }
        let viewModel = RoleSelectionViewModel(
            networkRepository: AppNetworkRepository(apiClient: apiClient),
            sessionManager: session,
            sessionPreferences: ViewModelSessionPreferenceStore()
        )

        viewModel.send(.updateRole(userId: "u-1", role: "Captain"))
        await waitUntil { !viewModel.state.isLoading && viewModel.state.isAuthenticated }

        XCTAssertTrue(viewModel.state.isAuthenticated)
        XCTAssertEqual(viewModel.state.selectedRole, "Captain")
        XCTAssertEqual(session.savedAccessToken, "new-access")
        XCTAssertEqual(session.savedRefreshToken, "new-refresh")
    }

    func testUpdateRoleUnauthorizedMapsToUserFriendlyMessage() async {
        let session = RoleSelectionSessionManager()
        session.accessToken = "expired-token"
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == "/Account/UpdateRole" {
                return .failure(APIError.unauthorized)
            }
            return .failure(APIError.invalidResponse)
        }
        let viewModel = RoleSelectionViewModel(
            networkRepository: AppNetworkRepository(apiClient: apiClient),
            sessionManager: session,
            sessionPreferences: ViewModelSessionPreferenceStore()
        )

        viewModel.send(.updateRole(userId: "u-1", role: "Business"))
        await waitUntil { !viewModel.state.isLoading && viewModel.state.errorMessage != nil }

        XCTAssertFalse(viewModel.state.isAuthenticated)
        XCTAssertEqual(viewModel.state.errorMessage, "Unable to update role. Please try again.")
    }

    private func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping () -> Bool
    ) async {
        let start = DispatchTime.now().uptimeNanoseconds
        while !condition() {
            if DispatchTime.now().uptimeNanoseconds - start > timeoutNanoseconds { break }
            await Task.yield()
        }
    }
}

private final class RoleSelectionSessionManager: SessionManaging {
    var accessToken: String?
    var refreshToken: String?
    let eventPublisher = PassthroughSubject<SessionEvent, Never>()

    private(set) var savedAccessToken: String?
    private(set) var savedRefreshToken: String?

    func saveTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        savedAccessToken = accessToken
        savedRefreshToken = refreshToken
    }

    func saveUserData(userID: String, username: String, email: String, role: String, missingStep: Int?) {}
    func clearTokens() {}
    func clearUserData() {}
    func refreshToken() async -> Bool { false }
    func hasValidSession() -> Bool { accessToken != nil && refreshToken != nil }
    func logout() {}
}
