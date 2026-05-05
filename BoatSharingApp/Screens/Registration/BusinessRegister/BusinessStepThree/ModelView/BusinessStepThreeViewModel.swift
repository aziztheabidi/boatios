import SwiftUI
import Combine

@MainActor
final class BusinessStepThreeViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let isLoading: Bool
        let isSuccess: Bool
        let message: String
        let shouldNavigate: Bool
    }

    var state: State {
        State(isLoading: isLoading, isSuccess: isSuccess, message: message, shouldNavigate: shouldNavigate)
    }

    // MARK: - Actions

    enum Action {
        case saveBusiness(description: String, isDock: Bool, userId: String)
    }

    func send(_ action: Action) {
        switch action {
        case .saveBusiness(let desc, let dock, let uid):
            performSaveBusiness(description: desc, isDock: dock, userId: uid)
        }
    }

    // MARK: - Published state

    @Published var message: String = ""
    @Published var isSuccess: Bool = false
    @Published var isLoading: Bool = false
    @Published var shouldNavigate: Bool = false

    // MARK: - Dependencies

    private let networkRepository: AppNetworkRepositoryProtocol
    private let sessionPreferences: SessionPreferenceStoring

    init(networkRepository: AppNetworkRepositoryProtocol, sessionPreferences: SessionPreferenceStoring) {
        self.networkRepository = networkRepository
        self.sessionPreferences = sessionPreferences
    }

    var sessionUserId: String {
        sessionPreferences.userID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private network

    private func performSaveBusiness(description: String, isDock: Bool, userId: String) {
        isLoading = true
        let parameters: [String: Any] = [
            "Description": description,
            "IsDock": isDock,
            "UserId": userId
        ]
        Task {
            do {
                let response = try await networkRepository.businessInfo_saveAbout(parameters: parameters)
                self.isLoading      = false
                self.message        = response.Message
                self.isSuccess      = response.Status == 200
                self.shouldNavigate = self.isSuccess
            } catch {
                self.isLoading = false
                self.message   = error.localizedDescription
                self.isSuccess = false
            }
        }
    }

}

