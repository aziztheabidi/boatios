import XCTest
import UIKit
@testable import BoatSharingApp

@MainActor
final class BusinessStepFourViewModelTests: XCTestCase {
    func testSuccessfulUploadUpdatesPreferencesAndRoutingLoginFlag() async {
        let preferences = ViewModelSessionPreferenceStore()
        preferences.isLoggedIn = false
        preferences.userID = "user-1"
        let routing = BusinessStepFourRoutingSpy()
        let model = BusinessStepFourModel(Status: 200, Message: "Done", obj: "")
        let uploader = MockBusinessSaveMediaUploader(result: .success(model))
        let viewModel = BusinessStepFourViewModel(
            preferences: preferences,
            sessionPreferences: preferences,
            routingNotifier: routing,
            mediaUploader: uploader
        )

        viewModel.uploadBusinesslogo(UserID: "user-1", image: UIImage(), images: [])
        await waitForUploadSideEffects()

        XCTAssertTrue(viewModel.isSuccess)
        XCTAssertTrue(preferences.isLoggedIn)
        XCTAssertEqual(routing.setLoggedInValues, [true])
        XCTAssertEqual(uploader.capturedUserID, "user-1")
    }

    func testNon200ResponseLeavesLoggedOutAndSkipsRoutingLogin() async {
        let preferences = ViewModelSessionPreferenceStore()
        preferences.isLoggedIn = false
        preferences.userID = "user-1"
        let routing = BusinessStepFourRoutingSpy()
        let model = BusinessStepFourModel(Status: 400, Message: "Bad", obj: "")
        let uploader = MockBusinessSaveMediaUploader(result: .success(model))
        let viewModel = BusinessStepFourViewModel(
            preferences: preferences,
            sessionPreferences: preferences,
            routingNotifier: routing,
            mediaUploader: uploader
        )

        viewModel.uploadBusinesslogo(UserID: "user-1", image: UIImage(), images: [])
        await waitForUploadSideEffects()

        XCTAssertFalse(viewModel.isSuccess)
        XCTAssertFalse(preferences.isLoggedIn)
        XCTAssertTrue(routing.setLoggedInValues.isEmpty)
    }

    private func waitForUploadSideEffects() async {
        for _ in 0..<50 {
            await Task.yield()
        }
    }
}

private final class MockBusinessSaveMediaUploader: BusinessSaveMediaUploading {
    private let result: Result<BusinessStepFourModel, Error>
    private(set) var capturedUserID: String?

    init(result: Result<BusinessStepFourModel, Error>) {
        self.result = result
    }

    func uploadBusinessMedia(
        userID: String,
        logoImage: UIImage,
        businessImages: [UIImage]
    ) async throws -> BusinessStepFourModel {
        capturedUserID = userID
        return try result.get()
    }
}

private final class BusinessStepFourRoutingSpy: AppRoutingNotifying {
    private(set) var setLoggedInValues: [Bool] = []

    func bind(_ state: RoutableAppState?) {}
    func syncRoutingFromStorageIfNeeded() {}
    func setRoutingIsLoggedIn(_ value: Bool) {
        setLoggedInValues.append(value)
    }
}
