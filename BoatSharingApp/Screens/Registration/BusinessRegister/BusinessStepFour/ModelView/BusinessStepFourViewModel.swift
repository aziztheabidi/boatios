import Foundation
import UIKit

// MARK: - Business media upload (Alamofire multipart, off the ViewModel)

protocol BusinessSaveMediaUploading: AnyObject {
    func uploadBusinessMedia(
        userID: String,
        logoImage: UIImage,
        businessImages: [UIImage],
        completion: @escaping (Result<BusinessStepFourModel, Error>) -> Void
    )
}

final class AlamofireBusinessSaveMediaUploader: BusinessSaveMediaUploading {
    private let tokenStore: TokenStoring

    init(tokenStore: TokenStoring) {
        self.tokenStore = tokenStore
    }

    func uploadBusinessMedia(
        userID: String,
        logoImage: UIImage,
        businessImages: [UIImage],
        completion: @escaping (Result<BusinessStepFourModel, Error>) -> Void
    ) {
        let url = "\(AppConfiguration.API.baseURL)\(AppConfiguration.API.Endpoints.businessSaveMedia)"
        let token = tokenStore.accessToken ?? ""
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token.isEmpty ? "token" : token)",
            "Accept": "application/json"
        ]
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
        .responseDecodable(of: BusinessStepFourModel.self) { response in
            if let error = response.error { completion(.failure(error)); return }
            switch response.result {
            case .success(let model): completion(.success(model))
            case .failure(let error): completion(.failure(error))
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
    private let routingNotifier: AppRoutingNotifying
    private let mediaUploader: BusinessSaveMediaUploading

    init(
        preferences: PreferenceStoring,
        routingNotifier: AppRoutingNotifying,
        mediaUploader: BusinessSaveMediaUploading
    ) {
        self.preferences = preferences
        self.routingNotifier = routingNotifier
        self.mediaUploader = mediaUploader
    }

    // MARK: - Legacy call-site compat

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
        mediaUploader.uploadBusinessMedia(userID: userID, logoImage: image, businessImages: images) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let model):
                    if model.Status == 200 {
                        self.message = model.Message.isEmpty ? "Images uploaded successfully" : model.Message
                        self.isSuccess = true
                        self.preferences.isLoggedIn = true
                        self.routingNotifier.setRoutingIsLoggedIn(true)
                    } else {
                        self.message = model.Message.isEmpty ? "Upload failed" : model.Message
                        self.isSuccess = false
                    }
                case .failure(let error):
                    self.message = "Upload failed: \(error.localizedDescription)"
                    self.isSuccess = false
                }
            }
        }
    }
}
