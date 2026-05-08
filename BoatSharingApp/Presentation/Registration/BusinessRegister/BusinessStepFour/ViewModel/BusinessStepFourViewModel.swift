import Foundation
import UIKit
import Combine

// MARK: - ViewModel

@MainActor
final class BusinessStepFourViewModel: ObservableObject {

    // MARK: - State

    struct State {
        let isLoading: Bool
        let isSuccess: Bool
        let message: String
        let shouldNavigateAfterSuccessDelay: Bool
    }

    var state: State {
        State(
            isLoading: isLoading,
            isSuccess: isSuccess,
            message: message,
            shouldNavigateAfterSuccessDelay: shouldNavigateAfterSuccessDelay
        )
    }

    // MARK: - Actions

    enum Action {
        case onAppear
        case onDisappear
        case uploadBusinessLogo(userID: String, image: UIImage, images: [UIImage])
        case scheduleNavigationAfterSuccessDelay
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear, .onDisappear:
            break
        case .uploadBusinessLogo(let userID, let image, let images):
            performUpload(userID: userID, image: image, images: images)
        case .scheduleNavigationAfterSuccessDelay:
            shouldNavigateAfterSuccessDelay = true
        }
    }

    // MARK: - Published state

    @Published var isLoading: Bool = false
    @Published var isSuccess: Bool = false
    @Published var message: String = ""
    @Published var shouldNavigateAfterSuccessDelay: Bool = false

    // MARK: - Dependencies

    private let preferences: PreferenceStoring
    private let sessionPreferences: SessionPreferenceStoring
    private let routingNotifier: AppRoutingNotifying
    private let mediaUploader: BusinessSaveMediaUploading

    init(
        preferences: PreferenceStoring,
        sessionPreferences: SessionPreferenceStoring,
        routingNotifier: AppRoutingNotifying,
        mediaUploader: BusinessSaveMediaUploading
    ) {
        self.preferences = preferences
        self.sessionPreferences = sessionPreferences
        self.routingNotifier = routingNotifier
        self.mediaUploader = mediaUploader
    }

    var sessionUserId: String {
        sessionPreferences.userID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Public action helpers

    func uploadBusinesslogo(UserID: String, image: UIImage, images: [UIImage]) {
        send(.uploadBusinessLogo(userID: UserID, image: image, images: images))
    }

    func scheduleNavigationAfterSuccessDelay() {
        send(.scheduleNavigationAfterSuccessDelay)
    }

    // MARK: - Private

    private func performUpload(userID: String, image: UIImage, images: [UIImage]) {
        beginUpload()
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let model = try await mediaUploader.uploadBusinessMedia(
                    userID: userID,
                    logoImage: image,
                    businessImages: images
                )
                handleUploadResponse(model)
            } catch {
                handleUploadFailure(error)
            }
        }
    }

    private func beginUpload() {
        isLoading = true
        isSuccess = false
        message = ""
    }

    private func handleUploadResponse(_ model: BusinessStepFourModel) {
        isLoading = false
        if model.Status == 200 {
            message = model.Message.isEmpty ? "Images uploaded successfully" : model.Message
            isSuccess = true
            preferences.isLoggedIn = true
            routingNotifier.setRoutingIsLoggedIn(true)
        } else {
            message = model.Message.isEmpty ? "Upload failed" : model.Message
            isSuccess = false
        }
    }

    private func handleUploadFailure(_ error: Error) {
        isLoading = false
        message = "Upload failed: \(error.localizedDescription)"
        isSuccess = false
    }
}

