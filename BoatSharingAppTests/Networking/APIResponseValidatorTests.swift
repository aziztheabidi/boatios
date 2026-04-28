import XCTest
@testable import BoatSharingApp

final class APIResponseValidatorTests: XCTestCase {
    struct TestPayload: Codable, Equatable {
        let id: Int
        let name: String
    }

    func testRequireSuccessReturnsPayloadForSuccessResponse() throws {
        let payload = TestPayload(id: 10, name: "voyage")
        let response = BaseResponse(Status: 200, Message: "OK", obj: payload)

        let result = try APIResponseValidator.requireSuccess(response)

        XCTAssertEqual(result, payload)
    }

    func testRequireSuccessThrowsBusinessErrorForFailureStatus() {
        let response = BaseResponse<TestPayload>(Status: 400, Message: "Bad request", obj: nil)

        XCTAssertThrowsError(try APIResponseValidator.requireSuccess(response)) { error in
            guard case AppError.business(let message) = error else {
                return XCTFail("Expected AppError.business")
            }
            XCTAssertEqual(message, "Bad request")
        }
    }

    func testRequireSuccessThrowsEmptyPayloadForMissingObject() {
        let response = BaseResponse<TestPayload>(Status: 200, Message: "OK", obj: nil)

        XCTAssertThrowsError(try APIResponseValidator.requireSuccess(response)) { error in
            guard case AppError.emptyPayload = error else {
                return XCTFail("Expected AppError.emptyPayload")
            }
        }
    }
}
