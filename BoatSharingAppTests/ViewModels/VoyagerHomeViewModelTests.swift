import XCTest
import Alamofire
@testable import BoatSharingApp

@MainActor
final class VoyagerHomeViewModelTests: XCTestCase {
    func testGetActiveDockListWhenUnauthorizedSetsTokenExpired() async {
        let unauthorized = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint == "/Dock/GetActive" {
                return .failure(unauthorized)
            }
            return .failure(APIError.invalidResponse)
        }
        let preferences = ViewModelSessionPreferenceStore()
        preferences.userID = "u-1"
        let viewModel = VoyagerHomeViewModel(apiClient: apiClient, identityProvider: preferences)

        viewModel.getActiveDockList()
        await Task.yield()

        XCTAssertTrue(viewModel.isTokenExpired)
    }

    func testGetActiveVoyagerWhenUnauthorizedSetsTokenExpired() async {
        let unauthorized = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
        let apiClient = GenericEndpointAPIClient { endpoint in
            if endpoint.contains("/VoyagerDashboard/GetActiveVoyage") {
                return .failure(unauthorized)
            }
            return .failure(APIError.invalidResponse)
        }
        let preferences = ViewModelSessionPreferenceStore()
        preferences.userID = "u-1"
        let viewModel = VoyagerHomeViewModel(apiClient: apiClient, identityProvider: preferences)

        viewModel.getActiveVoyager(userid: "u-1")
        await waitUntil { !viewModel.isVoyageLoading }

        XCTAssertTrue(viewModel.isTokenExpired)
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

