import SwiftUI
import Combine

@MainActor
final class CaptainRegStepThreeViewModel: ObservableObject {

    private let networkRepository: AppNetworkRepositoryProtocol
    private let preferences: PreferenceStoring
    private let sessionPreferences: SessionPreferenceStoring

    init(
        networkRepository: AppNetworkRepositoryProtocol,
        preferences: PreferenceStoring,
        sessionPreferences: SessionPreferenceStoring
    ) {
        self.networkRepository = networkRepository
        self.preferences = preferences
        self.sessionPreferences = sessionPreferences
    }

    var sessionUserId: String {
        sessionPreferences.userID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @Published var message: String = ""
    @Published var isSuccess: Bool = false
    @Published var isLoading: Bool = false
    @Published var shouldNavigate: Bool = false
    @Published var fetchedBoat: CaptainBoat? = nil

    func CaptainSavedBoat(UserId: String, BoatName: String, Make: String, Model: String, BoatYear: Int, BoatSize: Int, Capacity: Int) {
        let parameters: [String: Any] = [
            "UserId": UserId, "Name": BoatName, "Make": Make,
            "Model": Model, "Year": BoatYear, "Size": BoatSize, "Capacity": Capacity
        ]
        isLoading = true
        Task {
            do {
                let response = try await networkRepository.captainBoat_save(parameters: parameters)
                self.isLoading = false
                self.message = response.Message
                self.isSuccess = response.Status == 200
                if self.isSuccess {
                    self.preferences.isLoggedIn = true
                    self.shouldNavigate = true
                }
            } catch {
                self.isLoading = false
                self.message = error.localizedDescription
                self.isSuccess = false
            }
        }
    }

    func getCaptainBoat(userId: String) {
        isLoading = true
        Task {
            do {
                let response = try await networkRepository.captainBoat_getByUserId(userId: userId)
                self.isLoading = false
                self.isSuccess = response.status == 200
                self.message = response.message
                self.fetchedBoat = response.obj
            } catch {
                self.isLoading = false
                self.message = error.localizedDescription
                self.isSuccess = false
            }
        }
    }
}

