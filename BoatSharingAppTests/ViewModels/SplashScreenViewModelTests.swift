import XCTest
@testable import BoatSharingApp

@MainActor
final class SplashScreenViewModelTests: XCTestCase {
    func testHandleAppearUsesStoredFCMTokenAndActivates() {
        let store = SplashDeviceIdentifierStore()
        store.fcmToken = "fcm-123"
        let viewModel = SplashViewModel(deviceIdentifierStore: store)

        viewModel.send(.onAppear)

        XCTAssertEqual(viewModel.state.fcmToken, "fcm-123")
        XCTAssertTrue(viewModel.state.isActive)
        XCTAssertEqual(viewModel.state.route, .intro)
    }

    func testHandleAppearWithoutTokenSetsFallbackAndActivates() {
        let viewModel = SplashViewModel(deviceIdentifierStore: SplashDeviceIdentifierStore())

        viewModel.send(.onAppear)

        XCTAssertEqual(viewModel.state.fcmToken, "No token available")
        XCTAssertTrue(viewModel.state.isActive)
    }
}

private final class SplashDeviceIdentifierStore: DeviceIdentifierStoring {
    var fcmToken: String?
}
