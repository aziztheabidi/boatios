import SwiftUI
import Combine

@MainActor
final class BusinessStepOneViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let isLoading: Bool
        let isSuccess: Bool
        let message: String
        let shouldNavigateBusiness: Bool
        let shouldNavigateVoyager: Bool
        let isProfileLoading: Bool
        let profileErrorMessage: String?
        let businessProfile: GetBusinessFirstProfile?
    }

    var state: State {
        State(
            isLoading: isLoading,
            isSuccess: isSuccess,
            message: message,
            shouldNavigateBusiness: shouldNavigateBusiness,
            shouldNavigateVoyager: shouldNavigateVoyager,
            isProfileLoading: isBusniesProfileLoading,
            profileErrorMessage: ErrorMessage,
            businessProfile: BusinessProfile
        )
    }

    // MARK: - Actions

    enum Action {
        case registerUser(
            type: UserType,
            userID: String,
            phone: String,
            firstName: String,
            lastName: String,
            address: String,
            dob: String,
            email: String
        )
        case loadBusinessProfile(userId: String)
        case loadVoyagerProfile(userId: String)
        case scheduleToastHide
    }

    func send(_ action: Action) {
        switch action {
        case .registerUser(let type, let id, let phone, let first, let last, let addr, let dob, let email):
            performRegisterUser(userType: type, userID: id, phone: phone, firstName: first, lastName: last, address: addr, dob: dob, email: email)
        case .loadBusinessProfile(let uid): fetchBusinessProfile(userId: uid)
        case .loadVoyagerProfile(let uid):  fetchVoyagerProfile(userId: uid)
        case .scheduleToastHide:            scheduleToastHideInternal()
        }
    }

    // MARK: - Published state

    @Published var message: String = ""
    @Published var isSuccess: Bool = false
    @Published var isLoading: Bool = false
    @Published var shouldNavigateBusiness: Bool = false
    @Published var shouldNavigateVoyager: Bool = false
    @Published var isBusniesProfileLoading: Bool = false
    @Published var ErrorMessage: String?
    @Published var BusinessProfile: GetBusinessFirstProfile?
    @Published var shouldHideToast: Bool = false

    // MARK: - Dependencies

    private let networkRepository: AppNetworkRepositoryProtocol
    private let preferences: PreferenceStoring
    private let sessionPreferences: SessionPreferenceStoring
    private var toastHideCancellable: AnyCancellable?

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

    // MARK: - User type

    enum UserType { case voyager; case business }

    // MARK: - Private network

    private func performRegisterUser(
        userType: UserType,
        userID: String, phone: String, firstName: String, lastName: String,
        address: String, dob: String, email: String
    ) {
        var parameters: [String: Any] = [
            "UserId": userID, "PhoneNumber": phone,
            "FirstName": firstName, "LastName": lastName,
            "Address": address, "DateOfBirth": dob, "StripeEmail": email
        ]
        switch userType {
        case .voyager:  parameters["UserType"] = "Voyager"
        case .business: parameters["UserType"] = "Business"
        }

        isLoading = true
        Task {
            do {
                let response: BusinessStepOneModel
                switch userType {
                case .voyager:
                    response = try await networkRepository.voyagerProfile_save(parameters: parameters)
                case .business:
                    response = try await networkRepository.businessProfile_save(parameters: parameters)
                }
                self.isLoading = false
                self.message    = response.Message
                self.isSuccess  = response.Status == 200
                if self.isSuccess {
                    if userType == .voyager {
                        self.preferences.isLoggedIn = true
                        self.shouldNavigateVoyager  = true
                        self.shouldNavigateBusiness = false
                    } else {
                        self.shouldNavigateBusiness = true
                        self.shouldNavigateVoyager  = false
                    }
                }
            } catch {
                self.isLoading = false
                self.message   = error.localizedDescription
                self.isSuccess = false
            }
        }
    }

    private func fetchBusinessProfile(userId: String) {
        isBusniesProfileLoading = true
        ErrorMessage = nil
        Task {
            do {
                let response = try await networkRepository.businessProfile_getByUserId(userId: userId)
                self.isBusniesProfileLoading = false
                self.BusinessProfile = response.obj
            } catch {
                self.isBusniesProfileLoading = false
                self.ErrorMessage = error.localizedDescription
            }
        }
    }

    private func fetchVoyagerProfile(userId: String) {
        isBusniesProfileLoading = true
        ErrorMessage = nil
        Task {
            do {
                let response = try await networkRepository.voyagerProfile_getByUserId(userId: userId)
                self.isBusniesProfileLoading = false
                self.BusinessProfile = response.obj
            } catch {
                self.isBusniesProfileLoading = false
                self.ErrorMessage = error.localizedDescription
            }
        }
    }

    private func scheduleToastHideInternal() {
        toastHideCancellable?.cancel()
        toastHideCancellable = Just(())
            .delay(for: .seconds(3), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.shouldHideToast = true }
    }

    // MARK: - Public action helpers

    func registerUser(userType: UserType, UserID: String, Phone: String, FirstName: String, LastName: String, Address: String, DOB: String, Email: String) {
        send(.registerUser(type: userType, userID: UserID, phone: Phone, firstName: FirstName, lastName: LastName, address: Address, dob: DOB, email: Email))
    }

    func getBusinessProfile(userid: String) { send(.loadBusinessProfile(userId: userid)) }
    func GetVoyagerProfile(userid: String)   { send(.loadVoyagerProfile(userId: userid)) }
    func scheduleToastHide()                 { send(.scheduleToastHide) }
}

