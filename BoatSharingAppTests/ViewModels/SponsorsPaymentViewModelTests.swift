import XCTest
import Alamofire
@testable import BoatSharingApp

@MainActor
final class SponsorsPaymentViewModelTests: XCTestCase {
    func testFilteredPaymentsUsesSearchTextCaseInsensitive() {
        let viewModel = SponsorsPaymentViewModel(
            networkRepository: AppNetworkRepository(apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) }),
            sessionPreferences: ViewModelSessionPreferenceStore()
        )
        viewModel.sponsorPayments = [
            SponsorPayment(
                id: "1",
                name: "Trip 1",
                voyagerName: "Alice",
                voyagerPhoneNumber: "111",
                pickupDock: "A",
                pickupDockLatitude: 1,
                pickupDockLongitude: 1,
                dropOffDock: "B",
                dropOffDockLatitude: 2,
                dropOffDockLongitude: 2,
                amountToPay: 10,
                noOfVoyagers: 1,
                waterStay: "No",
                duration: "1h",
                VoyageStatus: "Pending"
            ),
            SponsorPayment(
                id: "2",
                name: "Trip 2",
                voyagerName: "Bob",
                voyagerPhoneNumber: "222",
                pickupDock: "A",
                pickupDockLatitude: 1,
                pickupDockLongitude: 1,
                dropOffDock: "B",
                dropOffDockLatitude: 2,
                dropOffDockLongitude: 2,
                amountToPay: 20,
                noOfVoyagers: 2,
                waterStay: "No",
                duration: "2h",
                VoyageStatus: "Pending"
            )
        ]

        viewModel.send(.updateSearchText("ali"))

        XCTAssertEqual(viewModel.state.filteredPayments.count, 1)
        XCTAssertEqual(viewModel.state.filteredPayments.first?.voyagerName, "Alice")
    }

    func testRequestPaymentIdsWithoutCurrentUserSetsError() {
        let preferences = ViewModelSessionPreferenceStore()
        preferences.userID = "   "
        let viewModel = SponsorsPaymentViewModel(
            networkRepository: AppNetworkRepository(apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) }),
            sessionPreferences: preferences
        )
        let paymentViewModel = NewRequestPopUpViewModel(
            networkRepository: AppNetworkRepository(apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) }),
            sessionPreferences: preferences
        )

        viewModel.send(.requestPaymentIds(voyageId: "v-1", paymentViewModel: paymentViewModel))

        XCTAssertEqual(viewModel.errorMessage, "Missing user id.")
    }

    func testHandlePaymentCompletedRoutesImmediately() {
        let viewModel = SponsorsPaymentViewModel(
            networkRepository: AppNetworkRepository(apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) }),
            sessionPreferences: ViewModelSessionPreferenceStore()
        )
        viewModel.shouldPresentStripeSheet = true

        viewModel.send(.paymentCompleted)

        XCTAssertTrue(viewModel.shouldNavigateToSuccess)
        XCTAssertEqual(viewModel.route, .paymentSuccess)
        XCTAssertEqual(viewModel.toastMessage, "Payment successful")
        XCTAssertFalse(viewModel.shouldPresentStripeSheet)
    }

    func testGetSponsorPaymentsNon200SetsErrorMessage() async {
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint.contains(AppConfiguration.API.Endpoints.voyagerSponsorPaymentsByUserId) {
                return .success(SponsorPaymentResponse(status: 500, message: "Server issue", obj: []))
            }
            return .failure(APIError.invalidResponse)
        }
        let preferences = ViewModelSessionPreferenceStore()
        preferences.userID = "u-1"
        let viewModel = SponsorsPaymentViewModel(networkRepository: AppNetworkRepository(apiClient: apiClient), sessionPreferences: preferences)

        viewModel.getSponsorPayments()
        await waitUntil { !viewModel.isLoading }

        XCTAssertEqual(viewModel.errorMessage, "Server issue")
        XCTAssertTrue(viewModel.sponsorPayments.isEmpty)
    }

    func testGetSponsorPaymentsFailureSetsErrorMessage() async {
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint.contains(AppConfiguration.API.Endpoints.voyagerSponsorPaymentsByUserId) {
                return .failure(APIError.noInternetConnection)
            }
            return .failure(APIError.invalidResponse)
        }
        let preferences = ViewModelSessionPreferenceStore()
        preferences.userID = "u-1"
        let viewModel = SponsorsPaymentViewModel(networkRepository: AppNetworkRepository(apiClient: apiClient), sessionPreferences: preferences)

        viewModel.getSponsorPayments()
        await waitUntil { !viewModel.isLoading }

        XCTAssertFalse((viewModel.errorMessage ?? "").isEmpty)
    }

    func testDismissScreenSetsDismissFlagAndClearResetsIt() {
        let viewModel = SponsorsPaymentViewModel(
            networkRepository: AppNetworkRepository(apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) }),
            sessionPreferences: ViewModelSessionPreferenceStore()
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

