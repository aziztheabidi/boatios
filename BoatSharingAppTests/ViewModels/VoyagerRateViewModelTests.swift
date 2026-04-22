import XCTest
@testable import BoatSharingApp

@MainActor
final class VoyagerRateViewModelTests: XCTestCase {

    func testGetVoyagerRateWithMissingDraftDataSetsValidationError() {
        let preferences = ViewModelSessionPreferenceStore()
        let viewModel = VoyagerRateViewModel(
            networkRepository: AppNetworkRepository(apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) }),
            sessionPreferences: preferences
        )

        viewModel.getVoyagerRate(using: .init())

        XCTAssertEqual(viewModel.errorMessage, "Missing required voyage data. Please reselect voyage details.")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testGetVoyagerRateSuccessUpdatesFareState() async {
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint.contains(AppConfiguration.API.Endpoints.voyageCalculateFare) {
                return .success(
                    VoyagerRateResponse(
                        status: 201,
                        message: "OK",
                        obj: DockRate(perHourRate: 120, totalFare: 360)
                    )
                )
            }
            return .failure(APIError.invalidResponse)
        }
        let viewModel = VoyagerRateViewModel(
            networkRepository: AppNetworkRepository(apiClient: apiClient),
            sessionPreferences: ViewModelSessionPreferenceStore()
        )
        var draft = VoyageDraft()
        draft.pickupDockID = "1"
        draft.dropOffDockID = "2"
        draft.estimatedHours = "3"
        draft.numberOfVoyagers = "2"
        draft.voyageCategoryID = "1"

        viewModel.getVoyagerRate(using: draft)
        await waitUntil { !viewModel.isLoading }

        XCTAssertEqual(viewModel.perHourRate, 120)
        XCTAssertEqual(viewModel.totalFare, 360)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFindBoatSuccessSetsImmediateRouteFlag() async {
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == AppConfiguration.API.Endpoints.voyageFindBoat {
                return .success(FindBoatResponse(status: 200, message: "OK", obj: "captain-1"))
            }
            return .failure(APIError.invalidResponse)
        }
        let viewModel = VoyagerRateViewModel(
            networkRepository: AppNetworkRepository(apiClient: apiClient),
            sessionPreferences: ViewModelSessionPreferenceStore()
        )

        viewModel.findBoat(
            voyagerUserId: "u-1",
            pickupDockId: "1",
            dropOffDockId: "2",
            estimatedCost: "45",
            numberOfVoyagers: "2",
            isImmediately: true,
            bookingDate: "2026-04-22",
            isSplitPayment: false,
            voyageCategoryID: 1
        )
        await waitUntil { viewModel.isFindBoat || viewModel.errorMessage != nil }

        XCTAssertTrue(viewModel.isFindBoat)
    }

    func testBookVoyageServer400ShowsPendingRequestToast() async {
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == AppConfiguration.API.Endpoints.voyageBook {
                return .failure(APIError.serverError(statusCode: 400, message: "Pending voyage"))
            }
            return .failure(APIError.invalidResponse)
        }
        let viewModel = VoyagerRateViewModel(
            networkRepository: AppNetworkRepository(apiClient: apiClient),
            sessionPreferences: ViewModelSessionPreferenceStore()
        )

        viewModel.bookVoyage(
            voyagerUserId: "u-1",
            pickupDockId: "1",
            dropOffDockId: "2",
            numberOfVoyagers: "3",
            isImmediately: false,
            bookingDate: "22 Apr 2026",
            startTime: "10:00",
            endTime: "12:00",
            isStayOnWater: true,
            isSplitPayment: true,
            perHourRate: 20,
            durationInHours: 2,
            numberOfSponsors: 1,
            estimatedCost: 40,
            individualAmount: 20,
            sponsors: ["s-1"],
            voyageCategoryID: 1
        )
        await waitUntil { viewModel.showToast || viewModel.isVoyageBooked || viewModel.errorMessage != nil }

        XCTAssertTrue(viewModel.showToast)
        XCTAssertEqual(
            viewModel.toastMessage,
            "You have a pending unconfirmed voyage request. Please confirm or cancel it first."
        )
        XCTAssertFalse(viewModel.isVoyageBooked)
    }

    func testBookVoyageSuccessSetsBookedVoyageTransitionState() async {
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == AppConfiguration.API.Endpoints.voyageBook {
                return .success(VoyageBookingResponse(status: 200, message: "Booked", obj: "voyage-1"))
            }
            return .failure(APIError.invalidResponse)
        }
        let viewModel = VoyagerRateViewModel(
            networkRepository: AppNetworkRepository(apiClient: apiClient),
            sessionPreferences: ViewModelSessionPreferenceStore()
        )

        viewModel.bookVoyage(
            voyagerUserId: "u-1",
            pickupDockId: "1",
            dropOffDockId: "2",
            numberOfVoyagers: "3",
            isImmediately: false,
            bookingDate: "22 Apr 2026",
            startTime: "10:00",
            endTime: "12:00",
            isStayOnWater: true,
            isSplitPayment: true,
            perHourRate: 20,
            durationInHours: 2,
            numberOfSponsors: 0,
            estimatedCost: 40,
            individualAmount: 0,
            sponsors: [],
            voyageCategoryID: 1
        )
        await waitUntil { viewModel.isVoyageBooked || viewModel.errorMessage != nil }

        XCTAssertTrue(viewModel.isVoyageBooked)
        XCTAssertEqual(viewModel.bookedVoyageId, "voyage-1")
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
