import SwiftUI

@MainActor
final class VoyagerRateViewModel: ObservableObject {

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    @Published var perHourRate: Double = 0.0
    @Published var totalFair: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isFindBoat: Bool = false
    @Published var isVoyageBooked: Bool = false
    @Published var BookedVoyageID: String = ""
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
        let endpoint = "/Voyage/CaculateFair?FromDockId=\(fromDockId)&ToDockId=\(toDockId)&DurationInHours=\(estimatedHours)&NoOfVoyagers=\(numberOfVoyagers)&VoyageCategoryid=\(voyageCategoryID)"
        Task {
            do {
                let response: VoyagerRateResponse = try await apiClient.request(
                    endpoint: endpoint,
                    method: .get,
                    parameters: nil,
                    requiresAuth: true
                )
                self.isLoading = false
                if response.status == 201, let obj = response.obj {
                    self.perHourRate = obj.perHourRate
                    self.totalFair = obj.totalFair
                } else {
                    self.errorMessage = response.message
                }
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func FindBoat_ApiCaAlling(VoyagerUserId: String, PickupDockId: String, DropOffDockId: String, EstimatedCost: String, NoOfVoyagers: String, IsImmediately: Bool, BookingDate: String, IsSplitPayment: Bool, voyageCategoryID: Int) {
        let parameters: [String: Any] = [
            "VoyagerUserId": VoyagerUserId, "PickupDockId": PickupDockId,
            "DropOffDockId": DropOffDockId, "NoOfVoyagers": NoOfVoyagers,
            "IsImmediately": IsImmediately, "BookingDate": BookingDate,
            "IsSplitPayment": IsSplitPayment, "EstimatedCost": EstimatedCost,
            "VoyageCategoryid": voyageCategoryID
        ]
        Task {
            do {
                let _: FindBoatResponse = try await apiClient.request(
                    endpoint: "/Voyage/FindBoat",
                    method: .post,
                    parameters: parameters,
                    requiresAuth: true
                )
                self.isFindBoat = true
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func BookVoyage_ApiCalling(
        VoyagerUserId: String, PickupDockId: String, DropOffDockId: String,
        NoOfVoyagers: String, IsImmediately: Bool, BookingDate: String,
        StartTime: String, EndTime: String, IsStayOnWater: Bool,
        IsSplitPayment: Bool, PerHourRate: Double, DurationInHours: Double,
        numberOfSponsors: Int, EstimatedCost: Double, IndvidualAmount: Double,
        sponsors: [String], voyageCategoryID: Int
    ) {
        let sponsorsArray = sponsors.map { ["VoyagerUserId": $0] }
        let newdate = convertDateFormat(from: BookingDate)
        let starttime = convertTimeToFullFormat(from: StartTime)
        let endtime = convertTimeToFullFormat(from: EndTime)
        // `/Voyage/Book` expects both canonical and legacy JSON keys for sponsor fields.
        let parameters: [String: Any] = [
            "VoyagerUserId": VoyagerUserId, "PickupDockId": PickupDockId,
            "DropOffDockId": DropOffDockId, "NoOfVoyagers": NoOfVoyagers,
            "IsImmediately": IsImmediately, "IsSplitPayment": IsSplitPayment,
            "BookingDate": newdate, "StartTime": starttime, "EndTime": endtime,
            "IsStayOnWater": IsStayOnWater, "PerHourRate": PerHourRate,
            "DurationInHours": DurationInHours,
            "NoOfSponsors": numberOfSponsors, "NoOfSponsers": numberOfSponsors,
            "EstimatedCost": EstimatedCost, "IndvidualAmount": IndvidualAmount,
            "Sponsors": sponsorsArray, "Sponsers": sponsorsArray,
            "VoyageCategoryid": voyageCategoryID
        ]
        Task {
            do {
                let response: VoyageBookingResponse = try await apiClient.request(
                    endpoint: "/Voyage/Book",
                    method: .post,
                    parameters: parameters,
                    requiresAuth: true
                )
                self.BookedVoyageID = response.obj
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
