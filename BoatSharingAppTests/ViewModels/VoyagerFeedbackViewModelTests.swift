import XCTest
import Alamofire
@testable import BoatSharingApp

@MainActor
final class VoyagerFeedbackViewModelTests: XCTestCase {
    func testSubmitFeedbackWithoutRatingOrRemarksShowsValidationToast() {
        let viewModel = VoyagerFeedbackViewModel(apiClient: FeedbackTestAPIClient(result: .failure(APIError.invalidResponse)))

        viewModel.submitFeedback(voyageId: "voyage-1", source: .voyager)

        XCTAssertEqual(viewModel.toastMessage, "Please submit feedback and rating first")
        XCTAssertTrue(viewModel.isShowingToast)
        XCTAssertFalse(viewModel.isFeedbackloading)
    }

    func testNavigateLaterRoutesVoyagerToVoyagerHome() {
        let viewModel = VoyagerFeedbackViewModel(apiClient: FeedbackTestAPIClient(result: .failure(APIError.invalidResponse)))

        viewModel.navigateLater(source: .voyager)

        XCTAssertTrue(viewModel.shouldNavigateVoyagerHome)
        XCTAssertFalse(viewModel.shouldNavigateCaptainHome)
    }

    func testSubmitFeedbackVoyagerSuccessRoutesToVoyagerHome() async {
        let apiClient = FeedbackTestAPIClient(
            result: .success(FeedBackResponse(status: 201, message: "OK", obj: "done"))
        )
        let viewModel = VoyagerFeedbackViewModel(apiClient: apiClient)
        viewModel.selectRating(4)
        viewModel.remarks = "Great ride"

        viewModel.submitFeedback(voyageId: "voyage-1", source: .voyager)
        await waitUntil { !viewModel.isFeedbackloading }

        XCTAssertTrue(viewModel.isFeedbackSuccess)
        XCTAssertTrue(viewModel.shouldNavigateVoyagerHome)
        XCTAssertEqual(apiClient.requestCount, 1)
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

private final class FeedbackTestAPIClient: APIClientProtocol {
    private let result: Result<FeedBackResponse, Error>
    private(set) var requestCount = 0

    init(result: Result<FeedBackResponse, Error>) {
        self.result = result
    }

    func request<T>(
        endpoint: String,
        method: HTTPMethod,
        parameters: Parameters?,
        encoding: any ParameterEncoding,
        requiresAuth: Bool
    ) async throws -> T where T : Decodable {
        requestCount += 1
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
