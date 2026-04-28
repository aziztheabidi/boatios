import XCTest
import Alamofire
@testable import BoatSharingApp

@MainActor
final class VoyagerFeedbackViewModelTests: XCTestCase {
    func testSubmitFeedbackWithoutRatingOrRemarksShowsValidationToast() {
        let viewModel = VoyagerFeedbackViewModel(
            networkRepository: AppNetworkRepository(apiClient: FeedbackTestAPIClient(result: .failure(APIError.invalidResponse)))
        )

        viewModel.send(.submit(voyageId: "voyage-1", source: .voyager))

        XCTAssertEqual(viewModel.toastMessage, "Please submit feedback and rating first")
        XCTAssertTrue(viewModel.isShowingToast)
        XCTAssertFalse(viewModel.isFeedbackLoading)
    }

    func testNavigateLaterRoutesVoyagerToVoyagerHome() {
        let viewModel = VoyagerFeedbackViewModel(
            networkRepository: AppNetworkRepository(apiClient: FeedbackTestAPIClient(result: .failure(APIError.invalidResponse)))
        )

        viewModel.send(.navigateLater(.voyager))

        XCTAssertTrue(viewModel.shouldNavigateVoyagerHome)
        XCTAssertFalse(viewModel.shouldNavigateCaptainHome)
    }

    func testSubmitFeedbackVoyagerSuccessRoutesToVoyagerHome() async {
        let apiClient = FeedbackTestAPIClient(
            result: .success(FeedbackResponse(status: 201, message: "OK", obj: "done"))
        )
        let viewModel = VoyagerFeedbackViewModel(networkRepository: AppNetworkRepository(apiClient: apiClient))
        viewModel.send(.selectRating(4))
        viewModel.send(.updateRemarks("Great ride"))

        viewModel.send(.submit(voyageId: "voyage-1", source: .voyager))
        await waitUntil { !viewModel.isFeedbackLoading }

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
    private let result: Result<FeedbackResponse, Error>
    private(set) var requestCount = 0

    init(result: Result<FeedbackResponse, Error>) {
        self.result = result
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: Parameters?,
        requiresAuth: Bool
    ) async throws -> T {
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
