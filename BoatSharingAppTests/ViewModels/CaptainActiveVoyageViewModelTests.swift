import XCTest
import Alamofire
import CoreLocation
@testable import BoatSharingApp

@MainActor
final class CaptainActiveVoyageViewModelTests: XCTestCase {
    func testGetCaptainActiveVoyagesUnauthorizedSetsTokenExpired() async {
        let unauthorized = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == "/Captain/GetActiveVoyages" {
                return .failure(unauthorized)
            }
            return .failure(APIError.invalidResponse)
        }
        let preferences = ViewModelSessionPreferenceStore()
        preferences.userID = "captain-1"
        let viewModel = CaptainActiveVoyageViewModel(
            networkRepository: AppNetworkRepository(apiClient: apiClient),
            identityProvider: preferences,
            locationProvider: StaticCaptainLocationProvider()
        )

        viewModel.getCaptainActiveVoyages()
        await waitUntil { !viewModel.isLoading }

        XCTAssertTrue(viewModel.isTokenExpired)
    }

    func testHandleSessionExpiredAcknowledgedRoutesToLogin() {
        let viewModel = CaptainActiveVoyageViewModel(
            networkRepository: AppNetworkRepository(apiClient: GenericEndpointAPIClient { _ in .failure(APIError.invalidResponse) }),
            identityProvider: ViewModelSessionPreferenceStore(),
            locationProvider: StaticCaptainLocationProvider()
        )

        viewModel.handleSessionExpiredAcknowledged()

        XCTAssertTrue(viewModel.shouldNavigateToLogin)
        XCTAssertEqual(viewModel.route, .login)
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

private struct StaticCaptainLocationProvider: CaptainLocationProviding {
    var currentCoordinate: CLLocationCoordinate2D? {
        CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
}

