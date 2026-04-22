import SwiftUI
import Combine

// OTPViewModel intentionally keeps ObservableObject without @MainActor
// because startTimer() uses a main-thread Combine publisher directly.
@MainActor
final class OTPViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let isLoading: Bool
        let isSuccess: Bool
        let message: String
        let shouldNavigate: Bool
        let shouldShowToast: Bool
        let timerValue: Int
        let isResendAvailable: Bool
    }

    var state: State {
        State(
            isLoading: isLoading,
            isSuccess: isSuccess,
            message: message,
            shouldNavigate: shouldNavigate,
            shouldShowToast: shouldShowToast,
            timerValue: timerValue,
            isResendAvailable: isResendAvailable
        )
    }

    // MARK: - Actions

    enum Action {
        case verifyOTP(email: String, otp: Int)
        case handleInvalidInput
        case dismissToast
        case startTimer
        case resetTimer
    }

    func send(_ action: Action) {
        switch action {
        case .verifyOTP(let email, let otp): performVerifyOTP(email: email, otp: otp)
        case .handleInvalidInput:  handleInvalidInput()
        case .dismissToast:        shouldShowToast = false
        case .startTimer:          startTimer()
        case .resetTimer:          startTimer()
        }
    }

    // MARK: - Published state

    @Published var message: String = ""
    @Published var isSuccess: Bool = false
    @Published var isLoading: Bool = false
    @Published var shouldNavigate: Bool = false
    @Published var shouldShowToast: Bool = false
    @Published var timerValue: Int = 30
    @Published var isResendAvailable: Bool = false

    // MARK: - Dependencies

    private let networkRepository: AppNetworkRepositoryProtocol
    private let tokenStore: TokenStoring
    private var countdownCancellable: AnyCancellable?
    private var navigationDelayTask: Task<Void, Never>?

    init(networkRepository: AppNetworkRepositoryProtocol, tokenStore: TokenStoring) {
        self.networkRepository = networkRepository
        self.tokenStore = tokenStore
    }

    deinit { navigationDelayTask?.cancel() }

    // MARK: - Private logic

    private func handleInvalidInput() {
        message = "Invalid OTP Format"
        shouldShowToast = true
    }

    /// Pure UX timer — 30-second countdown to enable Resend button.
    /// This is intentional visual timing, not business logic.
    func startTimer() {
        countdownCancellable?.cancel()
        isResendAvailable = false
        timerValue = 30
        countdownCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.timerValue > 0 { self.timerValue -= 1 }
                if self.timerValue <= 0 {
                    self.isResendAvailable = true
                    self.countdownCancellable?.cancel()
                }
            }
    }

    // MARK: - Private network

    private func performVerifyOTP(email: String, otp: Int) {
        isLoading = true
        Task {
            do {
                let response = try await networkRepository.registrationTemp_verify(parameters: ["OTP": otp, "Email": email])
                self.isLoading = false
                self.message   = response.Message
                self.tokenStore.accessToken = response.obj ?? ""
                self.isSuccess = response.Status == 200
                if self.isSuccess {
                    self.shouldShowToast = true
                    // Short UX delay so the success toast is visible before navigation
                    self.navigationDelayTask?.cancel()
                    self.navigationDelayTask = Task { [weak self] in
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        guard !Task.isCancelled else { return }
                        self?.shouldShowToast = false
                        self?.shouldNavigate  = true
                    }
                } else if !self.message.isEmpty {
                    self.shouldShowToast = true
                }
            } catch {
                self.isLoading = false
                let desc = error.localizedDescription
                // Filter out session/expire messages for registration — not a real session error here
                if desc.lowercased().contains("session") ||
                   desc.lowercased().contains("expire") ||
                   desc.lowercased().contains("unauthorized") {
                    self.message = "Unable to verify OTP. Please try again."
                } else {
                    self.message = desc
                }
                self.isSuccess     = false
                self.shouldShowToast = true
            }
        }
    }

    // MARK: - Public action helpers

    func EnterOTP(email: String, OTP: Int) { send(.verifyOTP(email: email, otp: OTP)) }
    func handleInvalidOtpInput()           { send(.handleInvalidInput) }
    func dismissToast()                    { send(.dismissToast) }
    func resetTimer()                      { send(.resetTimer) }
}

