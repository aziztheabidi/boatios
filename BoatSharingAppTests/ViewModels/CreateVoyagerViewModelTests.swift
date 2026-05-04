import XCTest
@testable import BoatSharingApp

@MainActor
final class CreateVoyageViewModelTests: XCTestCase {
    func testSaveAndProceedWithoutDateOrStartTimeShowsToast() {
        let viewModel = CreateVoyageViewModel(dateFormatter: DateFormatterHelper())
        let flowState = UIFlowState()

        viewModel.send(.saveAndProceed(flowState))

        XCTAssertTrue(viewModel.showToast)
        XCTAssertEqual(viewModel.toastMessage, "Please select a date and start time.")
        XCTAssertFalse(viewModel.moveToNextScreen)
    }

    func testSaveAndProceedWithSpendOnWaterWithoutEndTimeShowsToast() {
        let viewModel = CreateVoyageViewModel(dateFormatter: DateFormatterHelper())
        let flowState = UIFlowState()
        viewModel.selectedDate = Date()
        viewModel.selectedStartTime = Date()
        viewModel.isSpendOnWater = true
        viewModel.selectedEndTime = nil

        viewModel.send(.saveAndProceed(flowState))

        XCTAssertTrue(viewModel.showToast)
        XCTAssertEqual(viewModel.toastMessage, "Please select end time.")
        XCTAssertFalse(viewModel.moveToNextScreen)
    }

    func testSaveAndProceedSetsDraftAndRoutesToRate() {
        let viewModel = CreateVoyageViewModel(dateFormatter: DateFormatterHelper())
        let flowState = UIFlowState()
        let start = Date()
        let end = start.addingTimeInterval(3600)
        viewModel.selectedDate = start
        viewModel.selectedStartTime = start
        viewModel.selectedEndTime = end
        viewModel.isSpendOnWater = true
        viewModel.isTravelNow = false

        viewModel.send(.saveAndProceed(flowState))

        XCTAssertTrue(viewModel.moveToNextScreen)
        XCTAssertEqual(viewModel.route, .proceedToRate)
        XCTAssertEqual(flowState.voyageDraft.estimatedHours, 1.0, accuracy: 0.001)
        XCTAssertEqual(flowState.voyageDraft.isSpendOnWater, true)
    }
}
