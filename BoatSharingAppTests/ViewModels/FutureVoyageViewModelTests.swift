import XCTest
import Alamofire
@testable import BoatSharingApp

@MainActor
final class FutureVoyageViewModelTests: XCTestCase {
    func testSelectSectionUpdatesState() {
        let viewModel = FutureVoyageViewModel(
            networkRepository: AppNetworkRepository(apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) }),
            identityProvider: ViewModelSessionPreferenceStore()
        )

        viewModel.send(.selectSection(.pending))

        XCTAssertEqual(viewModel.state.selectedSection, .pending)
    }

    func testPresentCancelConfirmationSetsPopupAndVoyageId() {
        let viewModel = FutureVoyageViewModel(
            networkRepository: AppNetworkRepository(apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) }),
            identityProvider: ViewModelSessionPreferenceStore()
        )

        viewModel.send(.presentCancelConfirmation("voyage-77"))

        XCTAssertTrue(viewModel.showCancelPopup)
        XCTAssertEqual(viewModel.selectedVoyageIdForCancel, "voyage-77")
    }

    func testStartSponsorPaymentWithoutUserIdShowsToast() {
        let preferences = ViewModelSessionPreferenceStore()
        preferences.userID = ""
        let viewModel = FutureVoyageViewModel(
            networkRepository: AppNetworkRepository(apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) }),
            identityProvider: preferences
        )
        viewModel.voyageIdForPayment = "voyage-1"

        viewModel.send(.payNow)

        XCTAssertEqual(viewModel.toastMessage, "Missing user id.")
        XCTAssertTrue(viewModel.isShowToast)
    }

    func testHandleStripeCompletedCallsSponsorPaymentConfirmation() async {
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == AppConfiguration.API.Endpoints.sponsorPaymentConfirmation {
                return .success(PaymentSuccessResponse(status: 200, message: "OK", obj: "ok"))
            }
            if endpoint.contains("/Voyager/GetFutureBookedVoyagesByUserId") {
                return .success(
                    FutureVoyageResponse(
                        status: 200,
                        message: "OK",
                        obj: FutureVoyageDetails(unConfirmed: nil, confirmed: [])
                    )
                )
            }
            return .failure(APIError.invalidResponse)
        }
        let preferences = ViewModelSessionPreferenceStore()
        preferences.userID = "u-1"
        let viewModel = FutureVoyageViewModel(networkRepository: AppNetworkRepository(apiClient: apiClient), identityProvider: preferences)
        viewModel.voyageIdForPayment = "voyage-1"
        viewModel.stripePaymentIntentId = "pi_1"

        viewModel.send(.handleStripeResult(.completed))
        await Task.yield()

        XCTAssertEqual(viewModel.toastMessage, "Payment successful")
        XCTAssertTrue(apiClient.requestedEndpoints.contains(AppConfiguration.API.Endpoints.sponsorPaymentConfirmation))
    }

    func testVoyageConfirmationFailure400OpensPaymentPopup() async {
        let af400 = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 400))
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == "/Voyage/Confirm" {
                return .failure(af400)
            }
            return .failure(APIError.invalidResponse)
        }
        let preferences = ViewModelSessionPreferenceStore()
        preferences.userID = "u-1"
        let viewModel = FutureVoyageViewModel(networkRepository: AppNetworkRepository(apiClient: apiClient), identityProvider: preferences)

        viewModel.VoyageConfirmation(Voyageid: "voyage-1")
        await waitUntil { !viewModel.isConfirming }

        XCTAssertTrue(viewModel.payNowTrigger)
        XCTAssertTrue(viewModel.showPaymentPopup)
    }

    func testVoyageValidationFailureSetsErrorMessage() async {
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == "/Voyage/Cancel" {
                return .failure(APIError.noInternetConnection)
            }
            if endpoint.contains("/Voyager/GetFutureBookedVoyagesByUserId") {
                return .failure(APIError.noInternetConnection)
            }
            return .failure(APIError.invalidResponse)
        }
        let preferences = ViewModelSessionPreferenceStore()
        preferences.userID = "u-1"
        let viewModel = FutureVoyageViewModel(networkRepository: AppNetworkRepository(apiClient: apiClient), identityProvider: preferences)

        viewModel.VoyageValidation(Voyageid: "voyage-1")
        await waitUntil { !viewModel.isCancelling }

        XCTAssertFalse((viewModel.voyageErrorMessage ?? "").isEmpty)
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

