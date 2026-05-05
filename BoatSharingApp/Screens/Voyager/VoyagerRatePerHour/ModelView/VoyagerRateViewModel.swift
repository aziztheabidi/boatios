import SwiftUI
import Combine

@MainActor
final class VoyagerRateViewModel: ObservableObject {

    private let networkRepository: AppNetworkRepositoryProtocol
    private let sessionPreferences: SessionPreferenceStoring

    init(networkRepository: AppNetworkRepositoryProtocol, sessionPreferences: SessionPreferenceStoring) {
        self.networkRepository = networkRepository
        self.sessionPreferences = sessionPreferences
    }

    var sessionUserId: String {
        sessionPreferences.userID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @Published var perHourRate: Double = 0.0
    @Published var totalFare: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isFindBoat: Bool = false
    @Published var isVoyageBooked: Bool = false
    @Published var bookedVoyageId: String = ""
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""

    func getVoyagerRate(using draft: VoyageDraft) {
        let fromDockId = draft.pickupDockID.trimmingCharacters(in: .whitespacesAndNewlines)
        let toDockId = draft.dropOffDockID.trimmingCharacters(in: .whitespacesAndNewlines)
        let estimatedHours = draft.estimatedHours.trimmingCharacters(in: .whitespacesAndNewlines)
        let numberOfVoyagers = draft.numberOfVoyagers.trimmingCharacters(in: .whitespacesAndNewlines)
        let voyageCategoryID = draft.voyageCategoryID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !fromDockId.isEmpty, !toDockId.isEmpty, !estimatedHours.isEmpty,
              !numberOfVoyagers.isEmpty, !voyageCategoryID.isEmpty else {
            errorMessage = "Missing required voyage data. Please reselect voyage details."
            return
        }
        isLoading = true
        Task {
            do {
                let response = try await networkRepository.voyage_calculateFare(
                    fromDockId: fromDockId,
                    toDockId: toDockId,
                    durationHours: estimatedHours,
                    numberOfVoyagers: numberOfVoyagers,
                    voyageCategoryId: voyageCategoryID
                )
                self.isLoading = false
                if response.status == 201, let obj = response.obj {
                    self.perHourRate = obj.perHourRate
                    self.totalFare = obj.totalFare
                } else {
                    self.errorMessage = response.message
                }
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func findBoat(
        voyagerUserId: String,
        pickupDockId: String,
        dropOffDockId: String,
        estimatedCost: String,
        numberOfVoyagers: String,
        isImmediately: Bool,
        bookingDate: String,
        isSplitPayment: Bool,
        voyageCategoryID: Int
    ) {
        let parameters: [String: Any] = [
            "VoyagerUserId": voyagerUserId, "PickupDockId": pickupDockId,
            "DropOffDockId": dropOffDockId, "NoOfVoyagers": numberOfVoyagers,
            "IsImmediately": isImmediately, "BookingDate": bookingDate,
            "IsSplitPayment": isSplitPayment, "EstimatedCost": estimatedCost,
            BackendContractCoding.QueryParameter.voyageCategoryId: voyageCategoryID
        ]
        Task {
            do {
                _ = try await networkRepository.voyage_findBoat(parameters: parameters)
                self.isFindBoat = true
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func bookVoyage(
        voyagerUserId: String,
        pickupDockId: String,
        dropOffDockId: String,
        numberOfVoyagers: String,
        isImmediately: Bool,
        bookingDate: String,
        startTime: String,
        endTime: String,
        isStayOnWater: Bool,
        isSplitPayment: Bool,
        perHourRate: Double,
        durationInHours: Double,
        numberOfSponsors: Int,
        estimatedCost: Double,
        individualAmount: Double,
        sponsors: [String],
        voyageCategoryID: Int
    ) {
        let sponsorsArray = sponsors.map { ["VoyagerUserId": $0] }
        let newdate = convertDateFormat(from: bookingDate)
        let starttime = convertTimeToFullFormat(from: startTime)
        let endtime = convertTimeToFullFormat(from: endTime)
        // `/Voyage/Book` expects both canonical and backend-variant sponsor keys.
        let parameters: [String: Any] = [
            "VoyagerUserId": voyagerUserId, "PickupDockId": pickupDockId,
            "DropOffDockId": dropOffDockId, "NoOfVoyagers": numberOfVoyagers,
            "IsImmediately": isImmediately, "IsSplitPayment": isSplitPayment,
            "BookingDate": newdate, "StartTime": starttime, "EndTime": endtime,
            "IsStayOnWater": isStayOnWater, "PerHourRate": perHourRate,
            "DurationInHours": durationInHours,
            BackendContractCoding.VoyageBookPayloadKey.noOfSponsors: numberOfSponsors,
            BackendContractCoding.VoyageBookPayloadKey.noOfSponsorsMisspelled: numberOfSponsors,
            "EstimatedCost": estimatedCost,
            BackendContractCoding.VoyageBookPayloadKey.individualAmountMisspelled: individualAmount,
            BackendContractCoding.VoyageBookPayloadKey.sponsors: sponsorsArray,
            BackendContractCoding.VoyageBookPayloadKey.sponsorsMisspelled: sponsorsArray,
            BackendContractCoding.QueryParameter.voyageCategoryId: voyageCategoryID
        ]
        Task {
            do {
                let response = try await networkRepository.voyage_book(parameters: parameters)
                self.bookedVoyageId = response.obj
                self.isVoyageBooked = true
            } catch let error as APIError {
                self.errorMessage = error.localizedDescription
                if case .serverError(let code, _) = error, code == 400 {
                    self.toastMessage = "You have a pending unconfirmed voyage request. Please confirm or cancel it first."
                    self.showToast = true
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func convertDateFormat(from input: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "d MMM yyyy"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd"
        outputFormatter.locale = Locale(identifier: "en_US_POSIX")
        return inputFormatter.date(from: input).map { outputFormatter.string(from: $0) } ?? "Invalid date"
    }

    func convertTimeToFullFormat(from input: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "HH:mm:ss"
        outputFormatter.locale = Locale(identifier: "en_US_POSIX")
        return inputFormatter.date(from: input).map { outputFormatter.string(from: $0) } ?? "Invalid time"
    }
}

