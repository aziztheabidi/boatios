import SwiftUI
import Combine

@MainActor
final class CaptainRegStepOneViewModel: ObservableObject {

    private let apiClient: APIClientProtocol
    private let sessionPreferences: SessionPreferenceStoring

    init(apiClient: APIClientProtocol, sessionPreferences: SessionPreferenceStoring) {
        self.apiClient = apiClient
        self.sessionPreferences = sessionPreferences
    }

    @Published var message: String = ""
    @Published var isSuccess: Bool = false
    @Published var isLoading: Bool = false
    @Published var shouldNavigate: Bool = false
    @Published var captainProfile: CaptainProfile?
    @Published var errorMessage: String?
    @Published var isTokenExpired: Bool = false
    @Published var shouldHideToast: Bool = false
    private var toastHideCancellable: AnyCancellable?

    func CaptainRegister(UserID: String, Phone: String, FirstName: String, LastName: String, Address: String, DOB: String, Email: String) {
        let parameters: [String: Any] = [
            "UserId": UserID, "PhoneNumber": Phone,
            "FirstName": FirstName, "LastName": LastName,
            "Address": Address, "DateOfBirth": DOB, "StripeEmail": Email
        ]
        isLoading = true
        Task {
            do {
                let response: CaptainRegStepOneModel = try await apiClient.request(
                    endpoint: "/CaptainProfile/Save",
                    method: .post,
                    parameters: parameters,
                    requiresAuth: true
                )
                self.isLoading = false
                self.message = response.Message
                self.isSuccess = response.Status == 200
                if self.isSuccess { self.shouldNavigate = true }
            } catch {
                self.isLoading = false
                self.message = error.localizedDescription
                self.isSuccess = false
            }
        }
    }

    func getCaptainProfileOne() {
        isLoading = true
        let userId = sessionPreferences.userID
        guard !userId.isEmpty else {
            errorMessage = "User ID not found"
            isLoading = false
            return
        }
        Task {
            do {
                let response: CaptainProfileOneResponse = try await apiClient.request(
                    endpoint: "/CaptainProfile/GetByUserId?UserId=\(userId)",
                    method: .get,
                    parameters: nil,
                    requiresAuth: true
                )
                self.isLoading = false
                if response.status == 200 {
                    self.captainProfile = response.profile
                } else {
                    self.errorMessage = response.message
                }
            } catch let error as APIError {
                self.isLoading = false
                if case .unauthorized = error { self.isTokenExpired = true }
                else { self.errorMessage = error.localizedDescription }
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func scheduleToastHide() {
        toastHideCancellable?.cancel()
        toastHideCancellable = Just(())
            .delay(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.shouldHideToast = true }
    }
}
