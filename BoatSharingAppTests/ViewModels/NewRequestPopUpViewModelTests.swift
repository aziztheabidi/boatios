import XCTest
@testable import BoatSharingApp

@MainActor
final class NewRequestPopUpViewModelTests: XCTestCase {

    func testOnAppearWithCompletedVoyageSetsDismissAndFeedbackRoute() {
        let viewModel = NewRequestPopUpViewModel(
            networkRepository: AppNetworkRepository(apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) }),
            sessionPreferences: ViewModelSessionPreferenceStore()
        )

        viewModel.send(.onAppear(voyageStatus: "Completed"))

        XCTAssertTrue(viewModel.state.shouldDismissPopupForCompletedVoyage)
        XCTAssertTrue(viewModel.state.shouldNavigateToFeedbackForCompletedVoyage)
        XCTAssertEqual(viewModel.state.route, .dismissPopup)
    }

    func testOnAppearWithNonCompletedVoyageKeepsPopupStateUntouched() {
        let viewModel = NewRequestPopUpViewModel(
            networkRepository: AppNetworkRepository(apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) }),
            sessionPreferences: ViewModelSessionPreferenceStore()
        )

        viewModel.send(.onAppear(voyageStatus: "Accepted"))

        XCTAssertFalse(viewModel.state.shouldDismissPopupForCompletedVoyage)
        XCTAssertFalse(viewModel.state.shouldNavigateToFeedbackForCompletedVoyage)
        XCTAssertNil(viewModel.state.route)
    }

    func testGetSponsorPaymentIdsWithCanonicalKeyAlsoSendsBackendVariantKey() async {
        let apiClient = CapturingEndpointAPIClient { endpoint, _ in
            if endpoint == AppConfiguration.API.Endpoints.sponsorPaymentInitiate {
                return .success(
                    PaymentInitiationResponse(
                        status: 200,
                        message: "OK",
                        obj: PaymentInitiationData(
                            publishableKey: "pk",
                            customerId: "cust_1",
                            ephemeralKey: "ek",
                            clientSecret: "sec",
                            ephemeralKeyAndroid: "ek_a",
                            paymentIntentId: "pi_1"
                        )
                    )
                )
            }
            return .failure(APIError.invalidResponse)
        }
        let viewModel = NewRequestPopUpViewModel(
            networkRepository: AppNetworkRepository(apiClient: apiClient),
            sessionPreferences: ViewModelSessionPreferenceStore()
        )

        viewModel.send(
            .getSponsorPaymentIds(
                voyagerId: "voyage-1",
                sponsorId: "sponsor-1",
                user: BackendContractCoding.SponsorPaymentInitiateKey.sponsorUserIdCanonical
            )
        )
        await waitUntil { !viewModel.state.isPaymentLoaded }

        let record = try XCTUnwrap(apiClient.requestRecords.last)
        let params = record.parameters ?? [:]
        XCTAssertEqual(record.endpoint, AppConfiguration.API.Endpoints.sponsorPaymentInitiate)
        XCTAssertEqual(params["Id"] as? String, "voyage-1")
        XCTAssertEqual(params[BackendContractCoding.SponsorPaymentInitiateKey.sponsorUserIdCanonical] as? String, "sponsor-1")
        XCTAssertEqual(params[BackendContractCoding.SponsorPaymentInitiateKey.sponsorUserIdBackendVariant] as? String, "sponsor-1")
        XCTAssertTrue(viewModel.state.initialPaymentSuccess)
        XCTAssertEqual(viewModel.state.paymentData?.paymentIntentId, "pi_1")
    }

    func testVoyagerPaymentSuccessFailureSetsErrorMessage() async {
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == "/Voyage/PaymentConfirmation" {
                return .failure(APIError.timeout)
            }
            return .failure(APIError.invalidResponse)
        }
        let viewModel = NewRequestPopUpViewModel(
            networkRepository: AppNetworkRepository(apiClient: apiClient),
            sessionPreferences: ViewModelSessionPreferenceStore()
        )

        viewModel.send(.voyagerPaymentSuccess(voyageId: "voyage-1", paymentIntentId: "pi_1"))
        await waitUntil { !viewModel.state.isPaymentLoaded }

        XCTAssertEqual(viewModel.state.initialPaymentErrorMessage, APIError.timeout.localizedDescription)
        XCTAssertFalse(viewModel.state.paymentConfirmed)
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
