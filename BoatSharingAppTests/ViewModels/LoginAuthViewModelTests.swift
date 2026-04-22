import XCTest
import Combine
import Alamofire
@testable import BoatSharingApp

final class LoginAuthViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    func testLoginSuccessUpdatesStateAndSession() async {
        let response = BaseResponse<UserData>(
            Status: 200,
            Message: "OK",
            obj: UserData(
                email: "voyager@test.com",
                userId: "user-1",
                username: "voyager",
                role: "Voyager",
                password: nil,
                MissingStep: 0,
                accessToken: "access-1",
                refreshToken: "refresh-1"
            )
        )
        let sessionManager = LoginTestSessionManager()
        let authRepository = AuthRepository(apiClient: LoginTestAPIClient(result: .success(response)), sessionManager: sessionManager)
        let preferences = LoginTestPreferenceStore()
        let tokenStore = LoginTestTokenStore(deviceToken: "device-token-1")
        let viewModel = LoginAuthViewModel(
            authRepository: authRepository,
            sessionManager: sessionManager,
            preferences: preferences,
            tokenStore: tokenStore,
            routingNotifier: NoOpAppRoutingNotifier()
        )

        viewModel.login(email: "voyager@test.com", password: "secret")
        await waitUntil { !viewModel.state.isLoading }

        XCTAssertTrue(viewModel.state.isAuthenticated)
        XCTAssertEqual(viewModel.state.userId, "user-1")
        XCTAssertEqual(viewModel.state.role, "Voyager")
        XCTAssertEqual(viewModel.state.missingStep, 0)
        XCTAssertEqual(sessionManager.savedAccessToken, "access-1")
        XCTAssertEqual(sessionManager.savedRefreshToken, "refresh-1")
        XCTAssertEqual(preferences.userRole, "Voyager")
        XCTAssertEqual(preferences.missingStep, 0)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    @MainActor
    func testSubmitLoginWithInvalidEmailDoesNotCallAPI() {
        let apiClient = LoginTestAPIClient(
            result: .failure(APIError.invalidResponse)
        )
        let sessionManager = LoginTestSessionManager()
        let authRepository = AuthRepository(apiClient: apiClient, sessionManager: sessionManager)
        let viewModel = LoginAuthViewModel(
            authRepository: authRepository,
            sessionManager: sessionManager,
            preferences: LoginTestPreferenceStore(),
            tokenStore: LoginTestTokenStore(),
            routingNotifier: NoOpAppRoutingNotifier()
        )

        viewModel.submitLogin(email: "bad-email", password: "12345678")

        XCTAssertEqual(viewModel.state.emailError, "Invalid email format")
        XCTAssertNil(viewModel.state.passwordError)
        XCTAssertTrue(viewModel.state.showValidationErrors)
        XCTAssertEqual(apiClient.requestCallCount, 0)
        XCTAssertFalse(viewModel.state.isLoading)
    }

    @MainActor
    func testSubmitLoginWithShortPasswordDoesNotCallAPI() {
        let apiClient = LoginTestAPIClient(
            result: .failure(APIError.invalidResponse)
        )
        let sessionManager = LoginTestSessionManager()
        let authRepository = AuthRepository(apiClient: apiClient, sessionManager: sessionManager)
        let viewModel = LoginAuthViewModel(
            authRepository: authRepository,
            sessionManager: sessionManager,
            preferences: LoginTestPreferenceStore(),
            tokenStore: LoginTestTokenStore(),
            routingNotifier: NoOpAppRoutingNotifier()
        )

        viewModel.submitLogin(email: "voyager@test.com", password: "123")

        XCTAssertNil(viewModel.state.emailError)
        XCTAssertEqual(viewModel.state.passwordError, "Password must be at least 8 characters")
        XCTAssertEqual(apiClient.requestCallCount, 0)
    }

    func testLoginFailureSetsErrorAndUnauthenticatedState() async {
        let sessionManager = LoginTestSessionManager()
        let apiClient = LoginTestAPIClient(result: .failure(APIError.noInternetConnection))
        let authRepository = AuthRepository(apiClient: apiClient, sessionManager: sessionManager)
        let viewModel = LoginAuthViewModel(
            authRepository: authRepository,
            sessionManager: sessionManager,
            preferences: LoginTestPreferenceStore(),
            tokenStore: LoginTestTokenStore(),
            routingNotifier: NoOpAppRoutingNotifier()
        )

        viewModel.login(email: "voyager@test.com", password: "secret")
        await waitUntil { !viewModel.state.isLoading }

        XCTAssertFalse(viewModel.state.isAuthenticated)
        XCTAssertEqual(viewModel.state.errorMessage, APIError.noInternetConnection.localizedDescription)
    }

    func testLoginTogglesLoadingState() async {
        let response = BaseResponse<UserData>(Status: 200, Message: "OK", obj: UserData(
            email: "voyager@test.com",
            userId: "user-1",
            username: "voyager",
            role: "Voyager",
            password: nil,
            MissingStep: 1,
            accessToken: "access-1",
            refreshToken: "refresh-1"
        ))
        let sessionManager = LoginTestSessionManager()
        let apiClient = LoginTestAPIClient(result: .success(response), delayNanoseconds: 100_000_000)
        let authRepository = AuthRepository(apiClient: apiClient, sessionManager: sessionManager)
        let viewModel = LoginAuthViewModel(
            authRepository: authRepository,
            sessionManager: sessionManager,
            preferences: LoginTestPreferenceStore(),
            tokenStore: LoginTestTokenStore(),
            routingNotifier: NoOpAppRoutingNotifier()
        )

        let expectation = XCTestExpectation(description: "captures loading transitions")
        var states: [Bool] = []
        viewModel.$state
            .map(\.isLoading)
            .sink { value in
                states.append(value)
                if states.contains(true), states.last == false, states.count > 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.login(email: "voyager@test.com", password: "secret")
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(states.contains(true))
        XCTAssertEqual(states.last, false)
    }

    func testLoginSuccessSyncsRoutingFromStorage() async {
        let response = BaseResponse<UserData>(
            Status: 200,
            Message: "OK",
            obj: UserData(
                email: "voyager@test.com",
                userId: "user-1",
                username: "voyager",
                role: "Voyager",
                password: nil,
                MissingStep: 0,
                accessToken: "access-1",
                refreshToken: "refresh-1"
            )
        )
        let routing = SpyAppRoutingNotifier()
        let sessionManager = LoginTestSessionManager()
        let authRepository = AuthRepository(apiClient: LoginTestAPIClient(result: .success(response)), sessionManager: sessionManager)
        let viewModel = LoginAuthViewModel(
            authRepository: authRepository,
            sessionManager: sessionManager,
            preferences: LoginTestPreferenceStore(),
            tokenStore: LoginTestTokenStore(),
            routingNotifier: routing
        )

        viewModel.login(email: "voyager@test.com", password: "secret")
        await waitUntil { !viewModel.state.isLoading }

        XCTAssertEqual(routing.syncRoutingCallCount, 1)
    }

    @MainActor
    func testLogoutSyncsRoutingFromStorage() async {
        let routing = SpyAppRoutingNotifier()
        let sessionManager = LoginTestSessionManager()
        let response = BaseResponse<UserData>(
            Status: 200,
            Message: "OK",
            obj: UserData(
                email: "voyager@test.com",
                userId: "user-1",
                username: "voyager",
                role: "Voyager",
                password: nil,
                MissingStep: 0,
                accessToken: "access-1",
                refreshToken: "refresh-1"
            )
        )
        let authRepository = AuthRepository(apiClient: LoginTestAPIClient(result: .success(response)), sessionManager: sessionManager)
        let viewModel = LoginAuthViewModel(
            authRepository: authRepository,
            sessionManager: sessionManager,
            preferences: LoginTestPreferenceStore(),
            tokenStore: LoginTestTokenStore(),
            routingNotifier: routing
        )
        viewModel.login(email: "voyager@test.com", password: "secretsecret")
        await waitUntil { viewModel.state.isAuthenticated }

        viewModel.logout()

        XCTAssertFalse(viewModel.state.isAuthenticated)
        XCTAssertTrue(sessionManager.logoutCalled)
        XCTAssertEqual(routing.syncRoutingCallCount, 2)
    }

    private func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping () -> Bool
    ) async {
        let start = DispatchTime.now().uptimeNanoseconds
        while !condition() {
            if DispatchTime.now().uptimeNanoseconds - start > timeoutNanoseconds {
                break
            }
            await Task.yield()
        }
    }
}

private final class SpyAppRoutingNotifier: AppRoutingNotifying {
    private(set) var syncRoutingCallCount = 0
    private(set) var setLoggedInValues: [Bool] = []

    func bind(_ state: RoutableAppState?) {}

    func syncRoutingFromStorageIfNeeded() {
        syncRoutingCallCount += 1
    }

    func setRoutingIsLoggedIn(_ value: Bool) {
        setLoggedInValues.append(value)
    }
}

private final class LoginTestAPIClient: APIClientProtocol {
    private let result: Result<BaseResponse<UserData>, Error>
    private let delayNanoseconds: UInt64
    private(set) var requestCallCount = 0

    init(result: Result<BaseResponse<UserData>, Error>, delayNanoseconds: UInt64 = 0) {
        self.result = result
        self.delayNanoseconds = delayNanoseconds
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: Parameters?,
        requiresAuth: Bool
    ) async throws -> T {
        requestCallCount += 1
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        switch result {
        case .success(let response):
            guard let typed = response as? T else {
                throw APIError.invalidResponse
            }
            return typed
        case .failure(let error):
            throw error
        }
    }
}

private final class LoginTestSessionManager: SessionManaging {
    var accessToken: String?
    var refreshToken: String?
    var eventPublisher = PassthroughSubject<SessionEvent, Never>()

    var savedAccessToken: String?
    var savedRefreshToken: String?
    var logoutCalled = false

    func saveTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.savedAccessToken = accessToken
        self.savedRefreshToken = refreshToken
    }

    func saveUserData(userID: String, username: String, email: String, role: String, missingStep: Int?) {}
    func clearTokens() {}
    func clearUserData() {}
    func refreshToken() async -> Bool { false }
    func hasValidSession() -> Bool { accessToken != nil && refreshToken != nil }
    func logout() { logoutCalled = true }
}

private final class LoginTestPreferenceStore: PreferenceStoring {
    var isLoggedIn: Bool = false
    var userRole: String = ""
    var missingStep: Int = 1
    var fromBusinessDetail: Bool = false
}

private final class LoginTestTokenStore: TokenStoring {
    var accessToken: String?
    var refreshToken: String?
    var deviceToken: String?
    var fcmToken: String?

    init(
        accessToken: String? = nil,
        refreshToken: String? = nil,
        deviceToken: String? = nil,
        fcmToken: String? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.deviceToken = deviceToken
        self.fcmToken = fcmToken
    }

    func clearSessionTokens() {}
}
