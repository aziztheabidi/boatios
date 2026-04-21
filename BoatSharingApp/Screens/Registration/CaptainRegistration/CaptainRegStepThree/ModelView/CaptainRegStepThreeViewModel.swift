import SwiftUI

@MainActor
final class CaptainRegStepThreeViewModel: ObservableObject {

    private let apiClient: APIClientProtocol
    private let preferences: PreferenceStoring

    init(apiClient: APIClientProtocol, preferences: PreferenceStoring) {
        self.apiClient = apiClient
        self.preferences = preferences
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
                let response: CaptainRegStepThreeModel = try await apiClient.request(
                    endpoint: "/CaptainBoat/Save",
                    method: .post,
                    parameters: parameters,
                    requiresAuth: true
                )
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
                let response: CaptainBoatResponse = try await apiClient.request(
                    endpoint: "/CaptainBoat/GetByUserId?UserId=\(userId)",
                    method: .get,
                    parameters: nil,
                    requiresAuth: true
                )
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
