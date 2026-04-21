import XCTest
import Alamofire
@testable import BoatSharingApp

@MainActor
final class TravelNowViewModelTests: XCTestCase {
    func testMainPhaseReflectsLoadingAndErrorStates() {
        let viewModel = TravelNowViewModel(
            apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) },
            identityProvider: ViewModelSessionPreferenceStore()
        )

        viewModel.isLoading = true
        XCTAssertEqual(viewModel.mainPhase, .loading)

        viewModel.isLoading = false
        viewModel.statusCode = 404
        XCTAssertEqual(viewModel.mainPhase, .noVoyageFound)

        viewModel.statusCode = nil
        viewModel.errorMessage = "boom"
        XCTAssertEqual(viewModel.mainPhase, .retryableError)
    }

    func testStartSponsorPaymentOnBehalfWithoutUserIdSetsError() {
        let preferences = ViewModelSessionPreferenceStore()
        preferences.userID = ""
        let viewModel = TravelNowViewModel(
            apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) },
            identityProvider: preferences
        )

        viewModel.send(.payNow("voyage-1"))

        XCTAssertEqual(viewModel.errorMessage, "Missing user id.")
    }

    func testSponsorsPaymentSuccessCallsPaymentConfirmationEndpoint() async {
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == AppConfiguration.API.Endpoints.sponsorPaymentConfirmation {
                return .success(PaymentSuccessResponse(status: 200, message: "OK", obj: "ok"))
            }
            return .failure(APIError.invalidResponse)
        }
        let viewModel = TravelNowViewModel(
            apiClient: apiClient,
            identityProvider: ViewModelSessionPreferenceStore()
        )

        viewModel.sponsorsPaymentSuccess(voyageId: "v-1", paymentIntentId: "pi_1")
        await Task.yield()

        XCTAssertTrue(apiClient.requestedEndpoints.contains(AppConfiguration.API.Endpoints.sponsorPaymentConfirmation))
    }

    func testVoyageConfirmationSuccess200SetsPayNowFlag() async {
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == "/Voyage/Confirm" {
                return .success(VoyageConfirmationResponse(status: 200, message: "OK", obj: "ok"))
            }
            return .failure(APIError.invalidResponse)
        }
        let viewModel = TravelNowViewModel(
            apiClient: apiClient,
            identityProvider: ViewModelSessionPreferenceStore()
        )

        viewModel.voyageConfirmation(voyageId: "voyage-1")
        await waitUntil { !viewModel.isConfirming }

        XCTAssertTrue(viewModel.payNow)
    }

    func testVoyageConfirmationFailureSetsErrorMessageAndStopsLoading() async {
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == "/Voyage/Confirm" {
                return .failure(APIError.timeout)
            }
            if endpoint == "/Voyager/GetImmediatelyBookedVoyage" {
                return .failure(APIError.noInternetConnection)
            }
            return .failure(APIError.invalidResponse)
        }
        let viewModel = TravelNowViewModel(
            apiClient: apiClient,
            identityProvider: ViewModelSessionPreferenceStore()
        )

        viewModel.voyageConfirmation(voyageId: "voyage-1")
        await waitUntil { !viewModel.isConfirming }

        XCTAssertFalse((viewModel.errorMessage ?? "").isEmpty)
        XCTAssertFalse(viewModel.isConfirming)
    }

    func testDismissScreenSetsDismissFlagAndClearResetsIt() {
        let viewModel = TravelNowViewModel(
            apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) },
            identityProvider: ViewModelSessionPreferenceStore()
        )

        viewModel.send(.dismissScreen)
        XCTAssertTrue(viewModel.state.shouldDismissScreen)

        viewModel.send(.clearDismissRequest)
        XCTAssertFalse(viewModel.state.shouldDismissScreen)
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

