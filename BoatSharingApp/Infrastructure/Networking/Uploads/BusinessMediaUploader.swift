import Foundation
import UIKit
import Alamofire

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

        return try await AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(Data(userID.utf8), withName: "UserID")
                if !logoImage.size.equalTo(.zero), let logoData = logoImage.jpegData(compressionQuality: 0.8) {
                    multipartFormData.append(logoData, withName: "Logo", fileName: "logo.jpg", mimeType: "image/jpeg")
                }
                for (index, businessImage) in businessImages.enumerated() {
                    if let imageData = businessImage.jpegData(compressionQuality: 0.8) {
                        multipartFormData.append(imageData, withName: "Images", fileName: "business_image_\(index).jpg", mimeType: "image/jpeg")
                    }
                }
            },
            to: url,
            headers: headers
        )
        .validate(statusCode: 200..<600)
        .serializingDecodable(BusinessStepFourModel.self, decoder: JSONDecoder())
        .value
    }
}
