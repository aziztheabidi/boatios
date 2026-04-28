import XCTest
import Alamofire
import Combine
@testable import BoatSharingApp

final class AuthRepositoryTests: XCTestCase {
    func testLoginPersistsSessionDataOnSuccess() async throws {
        let user = LoginUserData(
            UserId: "user-1",
            Username: "captain",
            Email: "captain@boatit.com",
            Role: "Captain",
            Accesstoken: "access-1",
            Refreshtoken: "refresh-1",
            MissingStep: 0
        )
        let response = LoginResponse(Status: 200, Message: "OK", obj: user)
        let apiClient = MockAPIClient(result: .success(response))
        let session = MockSessionManager()
        let repository = AuthRepository(apiClient: apiClient, sessionManager: session)

        let result = try await repository.login(email: "captain@boatit.com", password: "secret")

        XCTAssertEqual(result.UserId, "user-1")
        XCTAssertEqual(session.savedAccessToken, "access-1")
        XCTAssertEqual(session.savedRefreshToken, "refresh-1")
        XCTAssertEqual(session.savedUserID, "user-1")
        XCTAssertEqual(session.savedRole, "Captain")
    }

    func testLoginThrowsServerErrorWhenStatusNotSuccess() async {
        let response = LoginResponse(Status: 401, Message: "Invalid credentials", obj: nil)
        let apiClient = MockAPIClient(result: .success(response))
        let repository = AuthRepository(apiClient: apiClient, sessionManager: MockSessionManager())

        await XCTAssertThrowsErrorAsync(try await repository.login(email: "bad@boatit.com", password: "bad")) { error in
            guard case APIError.serverError(let statusCode, let message) = error else {
                return XCTFail("Expected APIError.serverError")
            }
            XCTAssertEqual(statusCode, 401)
            XCTAssertEqual(message, "Invalid credentials")
        }
    }
}

private final class MockAPIClient: APIClientProtocol {
    private let responseData: Data
    private let error: Error?

    init<T: Encodable>(result: Result<T, Error>) {
        switch result {
        case .success(let value):
            self.responseData = try! JSONEncoder().encode(value)
            self.error = nil
        case .failure(let error):
            self.responseData = Data()
            self.error = error
        }
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: Parameters?,
        requiresAuth: Bool
    ) async throws -> T {
        if let error {
            throw error
        }
        return try JSONDecoder().decode(T.self, from: responseData)
    }
}

private final class MockSessionManager: SessionManaging {
    var accessToken: String?
    var refreshToken: String?
    var eventPublisher = PassthroughSubject<SessionEvent, Never>()

    var savedAccessToken: String?
    var savedRefreshToken: String?
    var savedUserID: String?
    var savedRole: String?

    func saveTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.savedAccessToken = accessToken
        self.savedRefreshToken = refreshToken
    }

    func saveUserData(userID: String, username: String, email: String, role: String, missingStep: Int?) {
        savedUserID = userID
        savedRole = role
    }

    func clearTokens() {}
    func clearUserData() {}
    func refreshToken() async -> Bool { false }
    func hasValidSession() -> Bool { accessToken != nil && refreshToken != nil }
    func logout() {}
}

private extension XCTestCase {
    func XCTAssertThrowsErrorAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line,
        _ errorHandler: (_ error: Error) -> Void = { _ in }
    async {
        do {
            _ = try await expression()
            XCTFail(message(), file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}
