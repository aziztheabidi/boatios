import XCTest
import Combine
@testable import BoatSharingApp

final class SessionManagerTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var tokenStore: MockTokenStore!
    private var preferenceStore: MockSessionPreferenceStore!
    private var refreshService: MockRefreshTokenService!
    private var session: SessionManager!

    override func setUp() {
        super.setUp()
        cancellables.removeAll()
        tokenStore = MockTokenStore()
        preferenceStore = MockSessionPreferenceStore()
        refreshService = MockRefreshTokenService()
        session = SessionManager(
            tokenStore: tokenStore,
            preferences: preferenceStore,
            refreshService: refreshService
        )
    }

    override func tearDown() {
        cancellables.removeAll()
        session = nil
        refreshService = nil
        preferenceStore = nil
        tokenStore = nil
        super.tearDown()
    }

    func testLogoutClearsTokensAndPreferences() {
        session.saveTokens(accessToken: "access-token", refreshToken: "refresh-token")
        session.saveUserData(
            userID: "user-1",
            username: "tester",
            email: "tester@example.com",
            role: "Voyager",
            missingStep: 0
        )

        session.logout()

        XCTAssertNil(session.accessToken)
        XCTAssertNil(session.refreshToken)
        XCTAssertFalse(preferenceStore.isLoggedIn)
        XCTAssertEqual(preferenceStore.userRole, "")
        XCTAssertEqual(preferenceStore.userID, "")
    }

    func testLogoutPublishesLoginRequiredEvent() {
        let expectation = XCTestExpectation(description: "publishes loginRequired")

        session.eventPublisher
            .sink { event in
                if event == .loginRequired {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        session.logout()
        wait(for: [expectation], timeout: 1.0)
    }

    func testRefreshTokenFailsWhenTokensMissingAndPublishesSessionExpired() async {
        let expectation = XCTestExpectation(description: "publishes sessionExpired")

        session.eventPublisher
            .sink { event in
                if event == .sessionExpired {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let success = await session.refreshToken()

        XCTAssertFalse(success)
        XCTAssertFalse(session.isAuthenticated)
        XCTAssertTrue(tokenStore.clearSessionTokensCalled)
        wait(for: [expectation], timeout: 1.0)
    }

    func testRefreshTokenSuccessUpdatesTokensAndPublishesTokenRefreshed() async {
        tokenStore.accessToken = "old-access"
        tokenStore.refreshToken = "old-refresh"
        refreshService.result = .success(SessionTokenData(Accesstoken: "new-access", Refreshtoken: "new-refresh"))
        let expectation = XCTestExpectation(description: "publishes tokenRefreshed")

        session.eventPublisher
            .sink { event in
                if event == .tokenRefreshed {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let success = await session.refreshToken()

        XCTAssertTrue(success)
        XCTAssertEqual(tokenStore.accessToken, "new-access")
        XCTAssertEqual(tokenStore.refreshToken, "new-refresh")
        wait(for: [expectation], timeout: 1.0)
    }

    func testRefreshTokenFailureClearsSessionState() async {
        tokenStore.accessToken = "old-access"
        tokenStore.refreshToken = "old-refresh"
        preferenceStore.isLoggedIn = true
        preferenceStore.userID = "u1"
        refreshService.result = .failure(APIError.unauthorized)

        let success = await session.refreshToken()

        XCTAssertFalse(success)
        XCTAssertNil(tokenStore.accessToken)
        XCTAssertNil(tokenStore.refreshToken)
        XCTAssertFalse(preferenceStore.isLoggedIn)
        XCTAssertEqual(preferenceStore.userID, "")
    }
}

private final class MockTokenStore: TokenStoring {
    var accessToken: String?
    var refreshToken: String?
    var deviceToken: String?
    var fcmToken: String?
    var clearSessionTokensCalled = false

    func clearSessionTokens() {
        clearSessionTokensCalled = true
        accessToken = nil
        refreshToken = nil
    }
}

private final class MockSessionPreferenceStore: SessionPreferenceStoring {
    var isLoggedIn: Bool = false
    var userRole: String = ""
    var missingStep: Int = 1
    var userID: String = ""
    var username: String = ""
    var userEmail: String = ""

    func clearSessionPreferences() {
        userID = ""
        username = ""
        userEmail = ""
        userRole = ""
        missingStep = 1
        isLoggedIn = false
    }
}

private final class MockRefreshTokenService: RefreshTokenServicing {
    var result: Result<SessionTokenData, Error> = .failure(APIError.unauthorized)

    func refreshToken(accessToken: String, refreshToken: String) async throws -> SessionTokenData {
        switch result {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
}
