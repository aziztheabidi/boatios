import XCTest
import Alamofire
@testable import BoatSharingApp

@MainActor
final class TravelNowViewModelTests: XCTestCase {
    func testOnAppearFetchFailureEndsInRetryableErrorPhase() async {
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == "/Voyager/GetImmediatelyBookedVoyage" {
                return .failure(APIError.invalidResponse)
            }
            return .failure(APIError.invalidResponse)
        }
        let viewModel = TravelNowViewModel(
            networkRepository: AppNetworkRepository(apiClient: apiClient),
            identityProvider: ViewModelSessionPreferenceStore()
        )
        viewModel.send(.onAppear)
        await waitUntil { viewModel.state.mainPhase == .retryableError }
        XCTAssertEqual(viewModel.state.mainPhase, .retryableError)
    }

    func testStartSponsorPaymentOnBehalfWithoutUserIdSetsError() {
        let preferences = ViewModelSessionPreferenceStore()
        preferences.userID = ""
        let viewModel = TravelNowViewModel(
            networkRepository: AppNetworkRepository(apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) }),
            identityProvider: preferences
        )

        viewModel.send(.payNow("voyage-1"))

        XCTAssertEqual(viewModel.state.errorMessage, "Missing user id.")
    }

    func testSponsorsPaymentSuccessCallsPaymentConfirmationEndpoint() async {
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == AppConfiguration.API.Endpoints.sponsorPaymentConfirmation {
                return .success(PaymentSuccessResponse(status: 200, message: "OK", obj: "ok"))
            }
            return .failure(APIError.invalidResponse)
        }
        let viewModel = TravelNowViewModel(
            networkRepository: AppNetworkRepository(apiClient: apiClient),
            identityProvider: ViewModelSessionPreferenceStore()
        )

        viewModel.sponsorsPaymentSuccess(voyageId: "v-1", paymentIntentId: "pi_1")
        await Task.yield()

        XCTAssertTrue(apiClient.requestedEndpoints.contains(AppConfiguration.API.Endpoints.sponsorPaymentConfirmation))
    }

    func testVoyageConfirmationSuccess200ShowsPaymentPopup() async {
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == "/Voyage/Confirm" {
                return .success(VoyageConfirmationResponse(status: 200, message: "OK", obj: "ok"))
            }
            return .failure(APIError.invalidResponse)
        }
        let viewModel = TravelNowViewModel(
            networkRepository: AppNetworkRepository(apiClient: apiClient),
            identityProvider: ViewModelSessionPreferenceStore()
        )

        viewModel.voyageConfirmation(voyageId: "voyage-1")
        await waitUntil { !viewModel.state.isConfirming }

        XCTAssertTrue(viewModel.state.showPaymentPopup)
        XCTAssertTrue(viewModel.state.showPendingSponsorInvite)
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
            networkRepository: AppNetworkRepository(apiClient: apiClient),
            identityProvider: ViewModelSessionPreferenceStore()
        )

        viewModel.voyageConfirmation(voyageId: "voyage-1")
        await waitUntil { !viewModel.state.isConfirming }

        XCTAssertFalse((viewModel.state.errorMessage ?? "").isEmpty)
        XCTAssertFalse(viewModel.state.isConfirming)
    }

    func testDismissScreenSetsDismissFlagAndClearResetsIt() {
        let viewModel = TravelNowViewModel(
            networkRepository: AppNetworkRepository(apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) }),
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
