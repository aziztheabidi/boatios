import XCTest
@testable import BoatSharingApp

@MainActor
final class SplashScreenViewModelTests: XCTestCase {
    func testHandleAppearUsesStoredFCMTokenAndActivates() {
        let tokenStore = SplashTokenStore()
        tokenStore.fcmToken = "fcm-123"
        let viewModel = SplashScreenViewModel(tokenStore: tokenStore)

        viewModel.send(.onAppear)

        XCTAssertEqual(viewModel.state.fcmToken, "fcm-123")
        XCTAssertTrue(viewModel.state.isActive)
    }

    func testHandleAppearWithoutTokenSetsFallbackAndActivates() {
        let viewModel = SplashScreenViewModel(tokenStore: SplashTokenStore())

        viewModel.send(.onAppear)

        XCTAssertEqual(viewModel.state.fcmToken, "No token available")
        XCTAssertTrue(viewModel.state.isActive)
    }
}

private final class SplashTokenStore: TokenStoring {
    var accessToken: String?
    var refreshToken: String?
    var deviceToken: String?
    var fcmToken: String?

    func clearSessionTokens() {}
}
