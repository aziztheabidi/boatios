import Foundation

// MARK: - Focused repository interfaces
//
// These adapters provide explicit feature boundaries on top of AppNetworkRepository.
// They preserve current behavior while making ViewModel dependencies more granular.

protocol BookingRepositoryProtocol: AnyObject {
    func lookupVoyageCategories() async throws -> VoyageCategoryResponse
    func findBoat(parameters: [String: Any]) async throws -> FindBoatResponse
    func bookVoyage(parameters: [String: Any]) async throws -> VoyageBookingResponse
    func calculateFare(
        fromDockId: String,
        toDockId: String,
        durationHours: String,
        numberOfVoyagers: String,
        voyageCategoryId: String
    ) async throws -> VoyagerRateResponse
}

protocol VoyageRepositoryProtocol: AnyObject {
    func getActiveVoyageList() async throws -> VoyageData?
    func getPastVoyageList() async throws -> [VoyageData]
    func getFutureVoyageList(userId: String) async throws -> [VoyageData]
    func cancelVoyage(voyageId: String) async throws -> VoyageValidationResponse
    func confirmVoyage(voyageId: String) async throws -> VoyageConfirmationResponse
}

protocol PaymentRepositoryProtocol: AnyObject {
    func initiateVoyagePayment(voyagerId: String) async throws -> PaymentInitiationResponse
    func confirmVoyagePayment(voyageId: String, paymentIntentId: String) async throws -> PaymentSuccessResponse
    func initiateSponsorPayment(parameters: [String: Any]) async throws -> PaymentInitiationResponse
    func confirmSponsorPayment(voyageId: String, paymentIntentId: String) async throws -> PaymentSuccessResponse
    func getSponsorPayments(userId: String) async throws -> SponsorPaymentResponse
}

protocol DashboardRepositoryProtocol: AnyObject {
    func getActiveDocks() async throws -> ActiveDocks
    func getVoyagerActiveVoyage(voyagerUserId: String) async throws -> VoyageSession
    func getVoyagerPastVoyages(userId: String) async throws -> PastVoyageResponse
    func getCaptainPastVoyages() async throws -> CaptainCompletedVoyagesResponse
    func getFollowedVoyagers(userId: String) async throws -> AddSponsorsModel
}

protocol CaptainRepositoryProtocol: AnyObject {
    func setAvailability(userId: String, isAvailable: String) async throws -> DeviceTokenResponse
    func getActiveVoyages() async throws -> CaptainActiveVoyagesResponse
    func getPastVoyages() async throws -> CaptainCompletedVoyagesResponse
}

protocol AccountRepositoryProtocol: AnyObject {
    func register(parameters: [String: Any]) async throws -> CreatePasswordModel
    func updateRole(parameters: [String: Any]) async throws -> RoleSectionModel
    func forgotPassword(email: String) async throws -> ResetPasswordModel
}

protocol RegistrationRepositoryProtocol: AnyObject {
    func saveVoyagerProfile(parameters: [String: Any]) async throws -> BusinessStepOneModel
    func saveBusinessProfile(parameters: [String: Any]) async throws -> BusinessStepOneModel
    func getBusinessProfile(userId: String) async throws -> GetBusinessFirstResponse
    func getVoyagerProfile(userId: String) async throws -> GetBusinessFirstResponse
    func saveBusinessInfo(parameters: [String: Any]) async throws -> BusinessStepTwoModel
    func getBusinessInfo(userId: String) async throws -> GetBusinessInfoResponse
    func saveBusinessAbout(parameters: [String: Any]) async throws -> BusinessStepThreeModel
    func saveCaptainProfile(parameters: [String: Any]) async throws -> CaptainRegStepOneModel
    func getCaptainProfile(userId: String) async throws -> CaptainProfileOneResponse
    func saveCaptainDocument(parameters: [String: Any]) async throws -> CaptainRegStepTwoModel
    func getCaptainDocument(userId: String) async throws -> CaptainDocumentResponse
    func saveCaptainBoat(parameters: [String: Any]) async throws -> CaptainRegStepThreeModel
    func getCaptainBoat(userId: String) async throws -> CaptainBoatResponse
    func addRegistrationTemp(parameters: [String: Any]) async throws -> BasicInfoModel
    func verifyRegistrationTemp(parameters: [String: Any]) async throws -> OTPModel
}

protocol RelationshipRepositoryProtocol: AnyObject {
    func getVoyagerRelationship() async throws -> SponsorRelationshipModel
    func followVoyager(parameters: [String: Any]) async throws -> FollowResponseModel
    func unfollowVoyager(parameters: [String: Any]) async throws -> FollowResponseModel
    func getBusinessRelationship() async throws -> BusinessVoyageModel
    func followBusiness(businessDockId: Int) async throws -> FollowBusinessUpdateResponse
    func unfollowBusiness(businessDockId: Int) async throws -> FollowBusinessUpdateResponse
}

protocol FeedbackRepositoryProtocol: AnyObject {
    func submitVoyagerFeedback(parameters: [String: Any]) async throws -> FeedbackResponse
    func submitCaptainFeedback(parameters: [String: Any]) async throws -> FeedbackResponse
    func submitComplain(parameters: [String: Any]) async throws -> TagChatMessage
}

protocol CaptainOperationsRepositoryProtocol: AnyObject {
    func getActiveVoyages() async throws -> CaptainActiveVoyagesResponse
    func acceptVoyage(parameters: [String: Any]) async throws -> AcceptVoyageResponse
    func cancelVoyage(voyageId: String) async throws -> VoyageValidationResponse
    func startVoyage(parameters: [String: Any]) async throws -> VoyageValidationResponse
    func completeVoyage(parameters: [String: Any]) async throws -> VoyageValidationResponse
}

protocol BusinessVoyageRepositoryProtocol: AnyObject {
    func getActiveVoyages() async throws -> VoyagerPaymentResponse
}

protocol TravelRepositoryProtocol: AnyObject {
    func getImmediatelyBookedVoyage() async throws -> TravelVoyageResponse
    func getFutureBookedVoyages(userId: String) async throws -> FutureVoyageResponse
    func cancelVoyage(voyageId: String) async throws -> VoyageValidationResponse
    func confirmVoyage(voyageId: String) async throws -> VoyageConfirmationResponse
    func confirmSponsorPayment(voyageId: String, paymentIntentId: String) async throws -> PaymentSuccessResponse
}

final class LiveBookingRepository: BookingRepositoryProtocol {
    private let network: AppNetworkRepositoryProtocol
    init(network: AppNetworkRepositoryProtocol) { self.network = network }

    func lookupVoyageCategories() async throws -> VoyageCategoryResponse {
        try await network.lookup_voyageCategories()
    }

    func findBoat(parameters: [String: Any]) async throws -> FindBoatResponse {
        try await network.voyage_findBoat(parameters: parameters)
    }

    func bookVoyage(parameters: [String: Any]) async throws -> VoyageBookingResponse {
        try await network.voyage_book(parameters: parameters)
    }

    func calculateFare(
        fromDockId: String,
        toDockId: String,
        durationHours: String,
        numberOfVoyagers: String,
        voyageCategoryId: String
    ) async throws -> VoyagerRateResponse {
        try await network.voyage_calculateFare(
            fromDockId: fromDockId,
            toDockId: toDockId,
            durationHours: durationHours,
            numberOfVoyagers: numberOfVoyagers,
            voyageCategoryId: voyageCategoryId
        )
    }
}

final class LiveVoyageRepository: VoyageRepositoryProtocol {
    private let network: AppNetworkRepositoryProtocol
    init(network: AppNetworkRepositoryProtocol) { self.network = network }

    func getActiveVoyageList() async throws -> VoyageData? {
        try await network.voyager_getActiveVoyageList()
    }

    func getPastVoyageList() async throws -> [VoyageData] {
        try await network.voyager_getPastVoyageList()
    }

    func getFutureVoyageList(userId: String) async throws -> [VoyageData] {
        try await network.voyager_getFutureVoyageList(userId: userId)
    }

    func cancelVoyage(voyageId: String) async throws -> VoyageValidationResponse {
        try await network.voyage_cancel(voyageId: voyageId)
    }

    func confirmVoyage(voyageId: String) async throws -> VoyageConfirmationResponse {
        try await network.voyage_confirm(voyageId: voyageId)
    }
}

final class LivePaymentRepository: PaymentRepositoryProtocol {
    private let network: AppNetworkRepositoryProtocol
    init(network: AppNetworkRepositoryProtocol) { self.network = network }

    func initiateVoyagePayment(voyagerId: String) async throws -> PaymentInitiationResponse {
        try await network.voyage_paymentInitiate(voyagerId: voyagerId)
    }

    func confirmVoyagePayment(voyageId: String, paymentIntentId: String) async throws -> PaymentSuccessResponse {
        try await network.voyage_paymentConfirm(voyageId: voyageId, paymentIntentId: paymentIntentId)
    }

    func initiateSponsorPayment(parameters: [String: Any]) async throws -> PaymentInitiationResponse {
        try await network.voyage_sponsorPaymentInitiate(parameters: parameters)
    }

    func confirmSponsorPayment(voyageId: String, paymentIntentId: String) async throws -> PaymentSuccessResponse {
        try await network.voyage_sponsorPaymentConfirm(voyageId: voyageId, paymentIntentId: paymentIntentId)
    }

    func getSponsorPayments(userId: String) async throws -> SponsorPaymentResponse {
        try await network.voyager_getSponsorPayments(userId: userId)
    }
}

final class LiveDashboardRepository: DashboardRepositoryProtocol {
    private let network: AppNetworkRepositoryProtocol
    init(network: AppNetworkRepositoryProtocol) { self.network = network }

    func getActiveDocks() async throws -> ActiveDocks {
        try await network.dock_getActive()
    }

    func getVoyagerActiveVoyage(voyagerUserId: String) async throws -> VoyageSession {
        try await network.voyagerDashboard_getActiveVoyage(voyagerUserId: voyagerUserId)
    }

    func getVoyagerPastVoyages(userId: String) async throws -> PastVoyageResponse {
        try await network.voyagerDashboard_getPastVoyages(userId: userId)
    }

    func getCaptainPastVoyages() async throws -> CaptainCompletedVoyagesResponse {
        try await network.captain_getPastVoyages()
    }

    func getFollowedVoyagers(userId: String) async throws -> AddSponsorsModel {
        try await network.voyagerDashboard_getFollowedVoyagers(userId: userId)
    }
}

final class LiveCaptainRepository: CaptainRepositoryProtocol {
    private let network: AppNetworkRepositoryProtocol
    init(network: AppNetworkRepositoryProtocol) { self.network = network }

    func setAvailability(userId: String, isAvailable: String) async throws -> DeviceTokenResponse {
        try await network.captainProfile_setAvailability(userId: userId, isAvailable: isAvailable)
    }

    func getActiveVoyages() async throws -> CaptainActiveVoyagesResponse {
        try await network.captain_getActiveVoyages()
    }

    func getPastVoyages() async throws -> CaptainCompletedVoyagesResponse {
        try await network.captain_getPastVoyages()
    }
}

final class LiveAccountRepository: AccountRepositoryProtocol {
    private let network: AppNetworkRepositoryProtocol
    init(network: AppNetworkRepositoryProtocol) { self.network = network }

    func register(parameters: [String: Any]) async throws -> CreatePasswordModel {
        try await network.account_register(parameters: parameters)
    }

    func updateRole(parameters: [String: Any]) async throws -> RoleSectionModel {
        try await network.account_updateRole(parameters: parameters)
    }

    func forgotPassword(email: String) async throws -> ResetPasswordModel {
        try await network.account_forgotPassword(email: email)
    }
}

final class LiveRegistrationRepository: RegistrationRepositoryProtocol {
    private let network: AppNetworkRepositoryProtocol
    init(network: AppNetworkRepositoryProtocol) { self.network = network }

    func saveVoyagerProfile(parameters: [String: Any]) async throws -> BusinessStepOneModel {
        try await network.voyagerProfile_save(parameters: parameters)
    }

    func saveBusinessProfile(parameters: [String: Any]) async throws -> BusinessStepOneModel {
        try await network.businessProfile_save(parameters: parameters)
    }

    func getBusinessProfile(userId: String) async throws -> GetBusinessFirstResponse {
        try await network.businessProfile_getByUserId(userId: userId)
    }

    func getVoyagerProfile(userId: String) async throws -> GetBusinessFirstResponse {
        try await network.voyagerProfile_getByUserId(userId: userId)
    }

    func saveBusinessInfo(parameters: [String: Any]) async throws -> BusinessStepTwoModel {
        try await network.businessInfo_save(parameters: parameters)
    }

    func getBusinessInfo(userId: String) async throws -> GetBusinessInfoResponse {
        try await network.businessInfo_getByUserId(userId: userId)
    }

    func saveBusinessAbout(parameters: [String: Any]) async throws -> BusinessStepThreeModel {
        try await network.businessInfo_saveAbout(parameters: parameters)
    }

    func saveCaptainProfile(parameters: [String: Any]) async throws -> CaptainRegStepOneModel {
        try await network.captainProfile_save(parameters: parameters)
    }

    func getCaptainProfile(userId: String) async throws -> CaptainProfileOneResponse {
        try await network.captainProfile_getByUserId(userId: userId)
    }

    func saveCaptainDocument(parameters: [String: Any]) async throws -> CaptainRegStepTwoModel {
        try await network.captainDocument_save(parameters: parameters)
    }

    func getCaptainDocument(userId: String) async throws -> CaptainDocumentResponse {
        try await network.captainDocument_getByUserId(userId: userId)
    }

    func saveCaptainBoat(parameters: [String: Any]) async throws -> CaptainRegStepThreeModel {
        try await network.captainBoat_save(parameters: parameters)
    }

    func getCaptainBoat(userId: String) async throws -> CaptainBoatResponse {
        try await network.captainBoat_getByUserId(userId: userId)
    }

    func addRegistrationTemp(parameters: [String: Any]) async throws -> BasicInfoModel {
        try await network.registrationTemp_add(parameters: parameters)
    }

    func verifyRegistrationTemp(parameters: [String: Any]) async throws -> OTPModel {
        try await network.registrationTemp_verify(parameters: parameters)
    }
}

final class LiveRelationshipRepository: RelationshipRepositoryProtocol {
    private let network: AppNetworkRepositoryProtocol
    init(network: AppNetworkRepositoryProtocol) { self.network = network }

    func getVoyagerRelationship() async throws -> SponsorRelationshipModel {
        try await network.voyager_getRelationship()
    }

    func followVoyager(parameters: [String: Any]) async throws -> FollowResponseModel {
        try await network.voyager_follow(parameters: parameters)
    }

    func unfollowVoyager(parameters: [String: Any]) async throws -> FollowResponseModel {
        try await network.voyager_unfollow(parameters: parameters)
    }

    func getBusinessRelationship() async throws -> BusinessVoyageModel {
        try await network.voyager_getBusinessRelationship()
    }

    func followBusiness(businessDockId: Int) async throws -> FollowBusinessUpdateResponse {
        try await network.voyager_followBusiness(businessDockId: businessDockId)
    }

    func unfollowBusiness(businessDockId: Int) async throws -> FollowBusinessUpdateResponse {
        try await network.voyager_unfollowBusiness(businessDockId: businessDockId)
    }
}

final class LiveFeedbackRepository: FeedbackRepositoryProtocol {
    private let network: AppNetworkRepositoryProtocol
    init(network: AppNetworkRepositoryProtocol) { self.network = network }

    func submitVoyagerFeedback(parameters: [String: Any]) async throws -> FeedbackResponse {
        try await network.voyage_voyagerFeedback(parameters: parameters)
    }

    func submitCaptainFeedback(parameters: [String: Any]) async throws -> FeedbackResponse {
        try await network.voyage_captainFeedback(parameters: parameters)
    }

    func submitComplain(parameters: [String: Any]) async throws -> TagChatMessage {
        try await network.voyager_complain(parameters: parameters)
    }
}

final class LiveCaptainOperationsRepository: CaptainOperationsRepositoryProtocol {
    private let network: AppNetworkRepositoryProtocol
    init(network: AppNetworkRepositoryProtocol) { self.network = network }

    func getActiveVoyages() async throws -> CaptainActiveVoyagesResponse {
        try await network.captain_getActiveVoyages()
    }

    func acceptVoyage(parameters: [String: Any]) async throws -> AcceptVoyageResponse {
        try await network.voyage_accept(parameters: parameters)
    }

    func cancelVoyage(voyageId: String) async throws -> VoyageValidationResponse {
        try await network.voyage_cancel(voyageId: voyageId)
    }

    func startVoyage(parameters: [String: Any]) async throws -> VoyageValidationResponse {
        try await network.voyage_start(parameters: parameters)
    }

    func completeVoyage(parameters: [String: Any]) async throws -> VoyageValidationResponse {
        try await network.voyage_complete(parameters: parameters)
    }
}

final class LiveBusinessVoyageRepository: BusinessVoyageRepositoryProtocol {
    private let network: AppNetworkRepositoryProtocol
    init(network: AppNetworkRepositoryProtocol) { self.network = network }

    func getActiveVoyages() async throws -> VoyagerPaymentResponse {
        try await network.business_getActiveVoyages()
    }
}

final class LiveTravelRepository: TravelRepositoryProtocol {
    private let network: AppNetworkRepositoryProtocol
    init(network: AppNetworkRepositoryProtocol) { self.network = network }

    func getImmediatelyBookedVoyage() async throws -> TravelVoyageResponse {
        try await network.voyager_getImmediatelyBookedVoyage()
    }

    func getFutureBookedVoyages(userId: String) async throws -> FutureVoyageResponse {
        try await network.voyager_getFutureBookedVoyages(userId: userId)
    }

    func cancelVoyage(voyageId: String) async throws -> VoyageValidationResponse {
        try await network.voyage_cancel(voyageId: voyageId)
    }

    func confirmVoyage(voyageId: String) async throws -> VoyageConfirmationResponse {
        try await network.voyage_confirm(voyageId: voyageId)
    }

    func confirmSponsorPayment(voyageId: String, paymentIntentId: String) async throws -> PaymentSuccessResponse {
        try await network.voyage_sponsorPaymentConfirm(voyageId: voyageId, paymentIntentId: paymentIntentId)
    }
}
