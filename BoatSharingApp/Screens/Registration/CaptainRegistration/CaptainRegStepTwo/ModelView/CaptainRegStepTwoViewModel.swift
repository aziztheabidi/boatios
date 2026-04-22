import SwiftUI
import Combine

@MainActor
final class CaptainRegStepTwoViewModel: ObservableObject {

    private let networkRepository: AppNetworkRepositoryProtocol
    private let sessionPreferences: SessionPreferenceStoring

    init(networkRepository: AppNetworkRepositoryProtocol, sessionPreferences: SessionPreferenceStoring) {
        self.networkRepository = networkRepository
        self.sessionPreferences = sessionPreferences
    }

    var sessionUserId: String {
        sessionPreferences.userID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @Published var message: String = ""
    @Published var isSuccess: Bool = false
    @Published var isLoading: Bool = false
    @Published var shouldNavigate: Bool = false
    @Published var captainDocument: CaptainDocument? = nil
    @Published var errorMessage: String = ""
    @Published var isTokenExpired: Bool = false
    @Published var shouldHideToast: Bool = false
    private var toastHideCancellable: AnyCancellable?

    func CaptainDocument(UserId: String, LicenseNumber: String, LicenseExpiration: String, TypeOfLicense: String, InsuranceCompany: String, PolicyNumber: String, PolicyExpiration: String) {
        let parameters: [String: Any] = [
            "UserId": UserId, "LicenseNumber": LicenseNumber,
            "LicenseExpiration": LicenseExpiration, "TypeOfLicense": TypeOfLicense,
            "InsuranceCompany": InsuranceCompany, "PolicyNumber": PolicyNumber,
            "PolicyExpiration": PolicyExpiration
        ]
        isLoading = true
        Task {
            do {
                let response = try await networkRepository.captainDocument_save(parameters: parameters)
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

    func getCaptainDocument() {
        isLoading = true
        let userId = sessionPreferences.userID
        guard !userId.isEmpty else {
            errorMessage = "User ID not found"
            isLoading = false
            return
        }
        Task {
            do {
                let response = try await networkRepository.captainDocument_getByUserId(userId: userId)
                self.isLoading = false
                if response.status == 200 {
                    self.captainDocument = response.document
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

