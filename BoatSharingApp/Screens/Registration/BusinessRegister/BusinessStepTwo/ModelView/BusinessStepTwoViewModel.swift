import SwiftUI

@MainActor
final class BusinessStepTwoViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let isLoading: Bool
        let isSuccess: Bool
        let message: String
        let shouldNavigate: Bool
        let isBusinessInfoLoading: Bool
        let errorMessage: String?
        let businessInfo: GetBusinessInfoProfile?
    }

    var state: State {
        State(
            isLoading: isLoading,
            isSuccess: isSuccess,
            message: message,
            shouldNavigate: shouldNavigate,
            isBusinessInfoLoading: isBusinessInfoLoading,
            errorMessage: errorMessage,
            businessInfo: businessInfo
        )
    }

    // MARK: - Actions

    enum Action {
        case saveBusiness(userId: String, name: String, type: String, address: String, phone: String, year: String, time: String)
        case loadBusinessInfo(userId: String)
    }

    func send(_ action: Action) {
        switch action {
        case .saveBusiness(let uid, let n, let t, let a, let p, let y, let ti):
            performSaveBusiness(userId: uid, name: n, type: t, address: a, phone: p, year: y, time: ti)
        case .loadBusinessInfo(let uid):
            fetchBusinessInfo(userId: uid)
        }
    }

    // MARK: - Published state

    @Published var message: String = ""
    @Published var isSuccess: Bool = false
    @Published var isLoading: Bool = false
    @Published var shouldNavigate: Bool = false
    @Published var isBusinessInfoLoading: Bool = false
    @Published var errorMessage: String?
    @Published var businessInfo: GetBusinessInfoProfile?

    // MARK: - Dependencies

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    // MARK: - Private network

    private func performSaveBusiness(userId: String, name: String, type: String, address: String, phone: String, year: String, time: String) {
        isLoading = true
        let parameters: [String: Any] = [
            "UserId": userId, "Name": name, "Type": type,
            "Address": address, "PhoneNumber": phone,
            "YearOfEstablishment": year, "Time": time
        ]
        Task {
            do {
                let response: BusinessStepTwoModel = try await apiClient.request(
                    endpoint: "/BusinessInfo/Save", method: .post,
                    parameters: parameters, requiresAuth: true
                )
                self.isLoading    = false
                self.message      = response.Message
                self.isSuccess    = response.Status == 200
                self.shouldNavigate = self.isSuccess
            } catch {
                self.isLoading = false
                self.message   = error.localizedDescription
                self.isSuccess = false
            }
        }
    }

    private func fetchBusinessInfo(userId: String) {
        isBusinessInfoLoading = true
        errorMessage = nil
        Task {
            do {
                let response: GetBusinessInfoResponse = try await apiClient.request(
                    endpoint: "/BusinessInfo/GetByUserId?UserId=\(userId)",
                    method: .get, parameters: nil, requiresAuth: true
                )
                self.isBusinessInfoLoading = false
                self.businessInfo = response.obj
            } catch {
                self.isBusinessInfoLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func getBusinessInfo(userId: String) { send(.loadBusinessInfo(userId: userId)) }
}
