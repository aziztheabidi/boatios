import Foundation
import UIKit
import Combine
import Alamofire

// MARK: - Business media upload (Alamofire multipart, off the ViewModel)

protocol BusinessSaveMediaUploading: AnyObject {
    func uploadBusinessMedia(
        userID: String,
        logoImage: UIImage,
        businessImages: [UIImage]
    ) async throws -> BusinessStepFourModel
}

final class AlamofireBusinessSaveMediaUploader: BusinessSaveMediaUploading {
    private let tokenStore: TokenStoring

    init(tokenStore: TokenStoring) {
        self.tokenStore = tokenStore
    }

    func uploadBusinessMedia(
        userID: String,
        logoImage: UIImage,
        businessImages: [UIImage]
    ) async throws -> BusinessStepFourModel {
        let url = "\(AppConfiguration.API.baseURL)\(AppConfiguration.API.Endpoints.businessSaveMedia)"
        let token = tokenStore.accessToken ?? ""
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token.isEmpty ? "token" : token)",
            "Accept": "application/json"
        ]
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BusinessStepFourModel, Error>) in
            AF.upload(multipartFormData: { multipartFormData in
                multipartFormData.append(Data(userID.utf8), withName: "UserID")
                if !logoImage.size.equalTo(.zero), let logoData = logoImage.jpegData(compressionQuality: 0.8) {
                    multipartFormData.append(logoData, withName: "Logo", fileName: "logo.jpg", mimeType: "image/jpeg")
                }
                for (index, businessImage) in businessImages.enumerated() {
                    if let imageData = businessImage.jpegData(compressionQuality: 0.8) {
                        multipartFormData.append(imageData, withName: "Images", fileName: "business_image_\(index).jpg", mimeType: "image/jpeg")
                    }
                }
            }, to: url, headers: headers)
            .validate(statusCode: 200..<600)
            .responseDecodable(of: BusinessStepFourModel.self, decoder: JSONDecoder()) { response in
                if let error = response.error {
                    continuation.resume(throwing: error)
                    return
                }
                switch response.result {
                case .success(let model):
                    continuation.resume(returning: model)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

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
        isLoading = true
        isSuccess = false
        message = ""
        Task { [weak self] in
            guard let self else { return }
            do {
                let model = try await mediaUploader.uploadBusinessMedia(
                    userID: userID,
                    logoImage: image,
                    businessImages: images
                )
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.isLoading = false
                    if model.Status == 200 {
                        self.message = model.Message.isEmpty ? "Images uploaded successfully" : model.Message
                        self.isSuccess = true
                        self.preferences.isLoggedIn = true
                        self.routingNotifier.setRoutingIsLoggedIn(true)
                    } else {
                        self.message = model.Message.isEmpty ? "Upload failed" : model.Message
                        self.isSuccess = false
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.isLoading = false
                    self.message = "Upload failed: \(error.localizedDescription)"
                    self.isSuccess = false
                }
            }
        }
    }
}

