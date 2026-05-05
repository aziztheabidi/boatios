import Foundation
import Alamofire

/// Single application networking surface for feature code: ViewModel to AppNetworkRepository to `APIClientWithRetry`.
/// ViewModels must not call `APIClientProtocol` directly. Encoding, retries, and 401 refresh stay in the client stack.
protocol AppNetworkRepositoryProtocol: AnyObject {

    // MARK: - Voyager list APIs (`VoyageData` / `RelationshipData`)

    func voyager_getActiveVoyageList() async throws -> VoyageData?
    func voyager_getPastVoyageList() async throws -> [VoyageData]
    func voyager_getFutureVoyageList(userId: String) async throws -> [VoyageData]
    func voyager_getRelationshipList() async throws -> [RelationshipData]
    /// Follow/Unfollow accept both `FolloweeId` and `VoyagerUserId` parameter shapes used by existing screens.
    func voyager_follow(parameters: [String: Any]) async throws -> FollowResponseModel
    func voyager_unfollow(parameters: [String: Any]) async throws -> FollowResponseModel

    // MARK: - Voyager dashboard / docks

    func dock_getActive() async throws -> ActiveDocks
    func voyagerDashboard_getActiveVoyage(voyagerUserId: String) async throws -> VoyageSession
    func voyagerDashboard_getPastVoyages(userId: String) async throws -> PastVoyageResponse
    func captain_getPastVoyages() async throws -> CaptainCompletedVoyagesResponse

    // MARK: - Travel / future / rate / find boat / book

    func voyager_getImmediatelyBookedVoyage() async throws -> TravelVoyageResponse
    func voyage_cancel(voyageId: String) async throws -> VoyageValidationResponse
    func voyage_confirm(voyageId: String) async throws -> VoyageConfirmationResponse
    func voyage_sponsorPaymentConfirm(voyageId: String, paymentIntentId: String) async throws -> PaymentSuccessResponse
    func voyager_getFutureBookedVoyages(userId: String) async throws -> FutureVoyageResponse
    func voyage_calculateFare(
        fromDockId: String,
        toDockId: String,
        durationHours: String,
        numberOfVoyagers: String,
        voyageCategoryId: String
    ) async throws -> VoyagerRateResponse
    func voyage_findBoat(parameters: [String: Any]) async throws -> FindBoatResponse
    func voyage_book(parameters: [String: Any]) async throws -> VoyageBookingResponse

    func lookup_voyageCategories() async throws -> VoyageCategoryResponse

    // MARK: - Captain

    func captainProfile_setAvailability(userId: String, isAvailable: String) async throws -> DeviceTokenResponse
    func captain_getActiveVoyages() async throws -> CaptainActiveVoyagesResponse
    func voyage_accept(parameters: [String: Any]) async throws -> AcceptVoyageResponse
    func voyage_start(parameters: [String: Any]) async throws -> VoyageValidationResponse
    func voyage_complete(parameters: [String: Any]) async throws -> VoyageValidationResponse

    // MARK: - Business voyage / active

    func voyager_getBusinessRelationship() async throws -> BusinessVoyageModel
    func voyager_followBusiness(businessDockId: Int) async throws -> FollowBusinessUpdateResponse
    func voyager_unfollowBusiness(businessDockId: Int) async throws -> FollowBusinessUpdateResponse
    func business_getActiveVoyages() async throws -> VoyagerPaymentResponse

    // MARK: - Payments (voyage / sponsor)

    func voyage_paymentInitiate(voyagerId: String) async throws -> PaymentInitiationResponse
    func voyage_paymentConfirm(voyageId: String, paymentIntentId: String) async throws -> PaymentSuccessResponse
    /// Sponsor payment initiate uses dynamic keys (see `NewRequestPopUpViewModel`); pass the exact `parameters` dict.
    func voyage_sponsorPaymentInitiate(parameters: [String: Any]) async throws -> PaymentInitiationResponse

    // MARK: - Registration / account

    func voyagerProfile_save(parameters: [String: Any]) async throws -> BusinessStepOneModel
    func businessProfile_save(parameters: [String: Any]) async throws -> BusinessStepOneModel
    func businessProfile_getByUserId(userId: String) async throws -> GetBusinessFirstResponse
    func voyagerProfile_getByUserId(userId: String) async throws -> GetBusinessFirstResponse
    func businessInfo_save(parameters: [String: Any]) async throws -> BusinessStepTwoModel
    func businessInfo_getByUserId(userId: String) async throws -> GetBusinessInfoResponse
    func businessInfo_saveAbout(parameters: [String: Any]) async throws -> BusinessStepThreeModel
    func captainProfile_save(parameters: [String: Any]) async throws -> CaptainRegStepOneModel
    func captainProfile_getByUserId(userId: String) async throws -> CaptainProfileOneResponse
    func captainDocument_save(parameters: [String: Any]) async throws -> CaptainRegStepTwoModel
    func captainDocument_getByUserId(userId: String) async throws -> CaptainDocumentResponse
    func captainBoat_save(parameters: [String: Any]) async throws -> CaptainRegStepThreeModel
    func captainBoat_getByUserId(userId: String) async throws -> CaptainBoatResponse
    func registrationTemp_add(parameters: [String: Any]) async throws -> BasicInfoModel
    func registrationTemp_verify(parameters: [String: Any]) async throws -> OTPModel
    func account_register(parameters: [String: Any]) async throws -> CreatePasswordModel
    func account_updateRole(parameters: [String: Any]) async throws -> RoleSectionModel
    func account_forgotPassword(email: String) async throws -> ResetPasswordModel

    // MARK: - Social / sponsors / feedback / chat

    func voyager_getRelationship() async throws -> SponsorRelationshipModel
    func voyagerDashboard_getFollowedVoyagers(userId: String) async throws -> AddSponsorsModel
    func voyager_getSponsorPayments(userId: String) async throws -> SponsorPaymentResponse
    func voyage_voyagerFeedback(parameters: [String: Any]) async throws -> FeedbackResponse
    func voyage_captainFeedback(parameters: [String: Any]) async throws -> FeedbackResponse
    func voyager_complain(parameters: [String: Any]) async throws -> TagChatMessage
}

final class AppNetworkRepository: AppNetworkRepositoryProtocol {

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    // MARK: - Voyager list

    func voyager_getActiveVoyageList() async throws -> VoyageData? {
        let response: BaseResponse<VoyageData> = try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.voyagerActiveVoyage,
            method: HTTPMethod.get,
            parameters: nil,
            requiresAuth: true
        )
        return response.obj
    }

    func voyager_getPastVoyageList() async throws -> [VoyageData] {
        let response: BaseResponse<[VoyageData]> = try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.voyagerPastVoyages,
            method: HTTPMethod.get,
            parameters: nil,
            requiresAuth: true
        )
        return response.obj ?? []
    }

    func voyager_getFutureVoyageList(userId: String) async throws -> [VoyageData] {
        let response: BaseResponse<[VoyageData]> = try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.voyagerFutureVoyages,
            method: HTTPMethod.get,
            parameters: ["UserId": userId],
            requiresAuth: true
        )
        return response.obj ?? []
    }

    func voyager_getRelationshipList() async throws -> [RelationshipData] {
        let response: BaseResponse<[RelationshipData]> = try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.voyagerRelationship,
            method: HTTPMethod.get,
            parameters: nil,
            requiresAuth: true
        )
        return response.obj ?? []
    }

    func voyager_follow(parameters: [String: Any]) async throws -> FollowResponseModel {
        try await apiClient.request(
            endpoint: "/Voyager/Follow",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func voyager_unfollow(parameters: [String: Any]) async throws -> FollowResponseModel {
        try await apiClient.request(
            endpoint: "/Voyager/UnFollow",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    // MARK: - Dashboard

    func dock_getActive() async throws -> ActiveDocks {
        let dto: ActiveDocksResponseDTO = try await apiClient.request(
            endpoint: "/Dock/GetActive",
            method: HTTPMethod.get,
            parameters: nil,
            requiresAuth: true
        )
        return VoyagerDashboardMapping.activeDocks(from: dto)
    }

    func voyagerDashboard_getActiveVoyage(voyagerUserId: String) async throws -> VoyageSession {
        let dto: ActiveVoyagerResponseDTO = try await apiClient.request(
            endpoint: "/VoyagerDashboard/GetActiveVoyage",
            method: HTTPMethod.get,
            parameters: ["VoyagerUserId": voyagerUserId],
            requiresAuth: true
        )
        return VoyagerDashboardMapping.voyageSession(from: dto.obj)
    }

    func voyagerDashboard_getPastVoyages(userId: String) async throws -> PastVoyageResponse {
        try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.voyagerPastVoyages,
            method: HTTPMethod.get,
            parameters: ["UserId": userId],
            requiresAuth: true
        )
    }

    func captain_getPastVoyages() async throws -> CaptainCompletedVoyagesResponse {
        try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.captainPastVoyages,
            method: HTTPMethod.get,
            parameters: nil,
            requiresAuth: true
        )
    }

    // MARK: - Travel / voyage

    func voyager_getImmediatelyBookedVoyage() async throws -> TravelVoyageResponse {
        try await apiClient.request(
            endpoint: "/Voyager/GetImmediatelyBookedVoyage",
            method: HTTPMethod.get,
            parameters: nil,
            requiresAuth: true
        )
    }

    func voyage_cancel(voyageId: String) async throws -> VoyageValidationResponse {
        try await apiClient.request(
            endpoint: "/Voyage/Cancel",
            method: HTTPMethod.post,
            parameters: ["Id": voyageId],
            requiresAuth: true
        )
    }

    func voyage_confirm(voyageId: String) async throws -> VoyageConfirmationResponse {
        try await apiClient.request(
            endpoint: "/Voyage/Confirm",
            method: HTTPMethod.post,
            parameters: ["Id": voyageId],
            requiresAuth: true
        )
    }

    func voyage_sponsorPaymentConfirm(voyageId: String, paymentIntentId: String) async throws -> PaymentSuccessResponse {
        try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.sponsorPaymentConfirmation,
            method: HTTPMethod.post,
            parameters: ["Id": voyageId, "PaymentIntentId": paymentIntentId],
            requiresAuth: true
        )
    }

    func voyager_getFutureBookedVoyages(userId: String) async throws -> FutureVoyageResponse {
        try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.voyagerFutureVoyages,
            method: HTTPMethod.get,
            parameters: ["UserId": userId],
            requiresAuth: true
        )
    }

    func voyage_calculateFare(
        fromDockId: String,
        toDockId: String,
        durationHours: String,
        numberOfVoyagers: String,
        voyageCategoryId: String
    ) async throws -> VoyagerRateResponse {
        let path = AppConfiguration.API.Endpoints.voyageCalculateFare
        let query =
            "FromDockId=\(fromDockId)&ToDockId=\(toDockId)&DurationInHours=\(durationHours)&NoOfVoyagers=\(numberOfVoyagers)&\(BackendContractCoding.QueryParameter.voyageCategoryId)=\(voyageCategoryId)"
        return try await apiClient.request(
            endpoint: "\(path)?\(query)",
            method: HTTPMethod.get,
            parameters: nil,
            requiresAuth: true
        )
    }

    func voyage_findBoat(parameters: [String: Any]) async throws -> FindBoatResponse {
        try await apiClient.request(
            endpoint: "/Voyage/FindBoat",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func voyage_book(parameters: [String: Any]) async throws -> VoyageBookingResponse {
        try await apiClient.request(
            endpoint: "/Voyage/Book",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func lookup_voyageCategories() async throws -> VoyageCategoryResponse {
        try await apiClient.request(
            endpoint: "/Lookup/VoyageCategory",
            method: HTTPMethod.get,
            parameters: nil,
            requiresAuth: true
        )
    }

    // MARK: - Captain

    func captainProfile_setAvailability(userId: String, isAvailable: String) async throws -> DeviceTokenResponse {
        try await apiClient.request(
            endpoint: "/CaptainProfile/Availability",
            method: HTTPMethod.post,
            parameters: ["UserId": userId, "IsAvailable": isAvailable],
            requiresAuth: true
        )
    }

    func captain_getActiveVoyages() async throws -> CaptainActiveVoyagesResponse {
        try await apiClient.request(
            endpoint: "/Captain/GetActiveVoyages",
            method: HTTPMethod.get,
            parameters: nil,
            requiresAuth: true
        )
    }

    func voyage_accept(parameters: [String: Any]) async throws -> AcceptVoyageResponse {
        try await apiClient.request(
            endpoint: "/Voyage/Accept",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func voyage_start(parameters: [String: Any]) async throws -> VoyageValidationResponse {
        try await apiClient.request(
            endpoint: "/Voyage/Start",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func voyage_complete(parameters: [String: Any]) async throws -> VoyageValidationResponse {
        try await apiClient.request(
            endpoint: "/Voyage/Complete",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    // MARK: - Business

    func voyager_getBusinessRelationship() async throws -> BusinessVoyageModel {
        try await apiClient.request(
            endpoint: "/Voyager/GetBusinessRelationship",
            method: HTTPMethod.get,
            parameters: nil,
            requiresAuth: true
        )
    }

    func voyager_followBusiness(businessDockId: Int) async throws -> FollowBusinessUpdateResponse {
        try await apiClient.request(
            endpoint: "/Voyager/FollowBusiness",
            method: HTTPMethod.post,
            parameters: ["BusinessDockId": businessDockId],
            requiresAuth: true
        )
    }

    func voyager_unfollowBusiness(businessDockId: Int) async throws -> FollowBusinessUpdateResponse {
        try await apiClient.request(
            endpoint: "/Voyager/UnFollowBusiness",
            method: HTTPMethod.post,
            parameters: ["BusinessDockId": businessDockId],
            requiresAuth: true
        )
    }

    func business_getActiveVoyages() async throws -> VoyagerPaymentResponse {
        try await apiClient.request(
            endpoint: "/Business/GetActiveVoyages",
            method: HTTPMethod.get,
            parameters: nil,
            requiresAuth: true
        )
    }

    // MARK: - Payments

    func voyage_paymentInitiate(voyagerId: String) async throws -> PaymentInitiationResponse {
        try await apiClient.request(
            endpoint: "/Voyage/PaymentInitiate",
            method: HTTPMethod.post,
            parameters: ["Id": voyagerId],
            requiresAuth: true
        )
    }

    func voyage_paymentConfirm(voyageId: String, paymentIntentId: String) async throws -> PaymentSuccessResponse {
        try await apiClient.request(
            endpoint: "/Voyage/PaymentConfirmation",
            method: HTTPMethod.post,
            parameters: ["Id": voyageId, "PaymentIntentId": paymentIntentId],
            requiresAuth: true
        )
    }

    func voyage_sponsorPaymentInitiate(parameters: [String: Any]) async throws -> PaymentInitiationResponse {
        try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.sponsorPaymentInitiate,
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    // MARK: - Registration

    func voyagerProfile_save(parameters: [String: Any]) async throws -> BusinessStepOneModel {
        try await apiClient.request(
            endpoint: "/VoyagerProfile/Save",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func businessProfile_save(parameters: [String: Any]) async throws -> BusinessStepOneModel {
        try await apiClient.request(
            endpoint: "/BusinessProfile/Save",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func businessProfile_getByUserId(userId: String) async throws -> GetBusinessFirstResponse {
        try await apiClient.request(
            endpoint: "/BusinessProfile/GetByUserId",
            method: HTTPMethod.get,
            parameters: ["UserId": userId],
            requiresAuth: true
        )
    }

    func voyagerProfile_getByUserId(userId: String) async throws -> GetBusinessFirstResponse {
        try await apiClient.request(
            endpoint: "/VoyagerProfile/GetByUserId",
            method: HTTPMethod.get,
            parameters: ["UserId": userId],
            requiresAuth: true
        )
    }

    func businessInfo_save(parameters: [String: Any]) async throws -> BusinessStepTwoModel {
        try await apiClient.request(
            endpoint: "/BusinessInfo/Save",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func businessInfo_getByUserId(userId: String) async throws -> GetBusinessInfoResponse {
        try await apiClient.request(
            endpoint: "/BusinessInfo/GetByUserId",
            method: HTTPMethod.get,
            parameters: ["UserId": userId],
            requiresAuth: true
        )
    }

    func businessInfo_saveAbout(parameters: [String: Any]) async throws -> BusinessStepThreeModel {
        try await apiClient.request(
            endpoint: "/BusinessInfo/SaveAbout",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func captainProfile_save(parameters: [String: Any]) async throws -> CaptainRegStepOneModel {
        try await apiClient.request(
            endpoint: "/CaptainProfile/Save",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func captainProfile_getByUserId(userId: String) async throws -> CaptainProfileOneResponse {
        try await apiClient.request(
            endpoint: "/CaptainProfile/GetByUserId",
            method: HTTPMethod.get,
            parameters: ["UserId": userId],
            requiresAuth: true
        )
    }

    func captainDocument_save(parameters: [String: Any]) async throws -> CaptainRegStepTwoModel {
        try await apiClient.request(
            endpoint: "/CaptainDocument/Save",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func captainDocument_getByUserId(userId: String) async throws -> CaptainDocumentResponse {
        try await apiClient.request(
            endpoint: "/CaptainDocument/GetByUserId",
            method: HTTPMethod.get,
            parameters: ["UserId": userId],
            requiresAuth: true
        )
    }

    func captainBoat_save(parameters: [String: Any]) async throws -> CaptainRegStepThreeModel {
        try await apiClient.request(
            endpoint: "/CaptainBoat/Save",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func captainBoat_getByUserId(userId: String) async throws -> CaptainBoatResponse {
        try await apiClient.request(
            endpoint: "/CaptainBoat/GetByUserId",
            method: HTTPMethod.get,
            parameters: ["UserId": userId],
            requiresAuth: true
        )
    }

    func registrationTemp_add(parameters: [String: Any]) async throws -> BasicInfoModel {
        try await apiClient.request(
            endpoint: "/RegistrationTemp/Add",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: false
        )
    }

    func registrationTemp_verify(parameters: [String: Any]) async throws -> OTPModel {
        try await apiClient.request(
            endpoint: "/RegistrationTemp/Verify",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: false
        )
    }

    func account_register(parameters: [String: Any]) async throws -> CreatePasswordModel {
        try await apiClient.request(
            endpoint: "/Account/Register",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func account_updateRole(parameters: [String: Any]) async throws -> RoleSectionModel {
        try await apiClient.request(
            endpoint: "/Account/UpdateRole",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func account_forgotPassword(email: String) async throws -> ResetPasswordModel {
        try await apiClient.request(
            endpoint: "/Account/ForgotPassword",
            method: HTTPMethod.post,
            parameters: ["Email": email],
            requiresAuth: false
        )
    }

    // MARK: - Social / feedback / chat

    func voyager_getRelationship() async throws -> SponsorRelationshipModel {
        try await apiClient.request(
            endpoint: "/Voyager/GetRelationship",
            method: HTTPMethod.get,
            parameters: nil,
            requiresAuth: true
        )
    }

    func voyagerDashboard_getFollowedVoyagers(userId: String) async throws -> AddSponsorsModel {
        try await apiClient.request(
            endpoint: "/VoyagerDashboard/GetFollowedVoyagers",
            method: HTTPMethod.get,
            parameters: ["UserId": userId],
            requiresAuth: true
        )
    }

    func voyager_getSponsorPayments(userId: String) async throws -> SponsorPaymentResponse {
        let endpoint = "\(AppConfiguration.API.Endpoints.voyagerSponsorPaymentsByUserId)?UserId=\(userId)"
        return try await apiClient.request(
            endpoint: endpoint,
            method: HTTPMethod.get,
            parameters: nil,
            requiresAuth: true
        )
    }

    func voyage_voyagerFeedback(parameters: [String: Any]) async throws -> FeedbackResponse {
        try await apiClient.request(
            endpoint: "/Voyage/VoyagerFeedback",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func voyage_captainFeedback(parameters: [String: Any]) async throws -> FeedbackResponse {
        try await apiClient.request(
            endpoint: "/Voyage/CaptainFeedback",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }

    func voyager_complain(parameters: [String: Any]) async throws -> TagChatMessage {
        try await apiClient.request(
            endpoint: "/Voyager/Complain",
            method: HTTPMethod.post,
            parameters: parameters,
            requiresAuth: true
        )
    }
}

// MARK: - Voyager list models

struct VoyageData: Codable, Identifiable {
    let id: String?
    let voyageId: String?
    let captainId: String?
    let captainName: String?
    let boatName: String?
    let departureTime: String?
    let arrivalTime: String?
    let status: String?
    let fare: Double?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case voyageId = "VoyageId"
        case captainId = "CaptainId"
        case captainName = "CaptainName"
        case boatName = "BoatName"
        case departureTime = "DepartureTime"
        case arrivalTime = "ArrivalTime"
        case status = "Status"
        case fare = "Fare"
    }
}

struct RelationshipData: Codable {
    let followeeId: String?
    let followeeName: String?
    let followeeEmail: String?
    let isFollowing: Bool?

    enum CodingKeys: String, CodingKey {
        case followeeId = "FolloweeId"
        case followeeName = "FolloweeName"
        case followeeEmail = "FolloweeEmail"
        case isFollowing = "IsFollowing"
    }
}

