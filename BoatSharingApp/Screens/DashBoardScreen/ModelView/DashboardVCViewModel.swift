import SwiftUI

@MainActor
class DashboardVCViewModel: ObservableObject {
    struct State {
        let dashboard: BusinessDashboard?
        let errorMessage: String?
        let isDashboardLoading: Bool
        let isUploadLoading: Bool
        let isDeleteImageLoading: Bool
        let deleteSuccessMessage: String?
        let shoreItems: [DockItem]
        let zoneItems: [DockItem]
        let islandItems: [DockItem]
    }
    enum Action {
        case fetchDashboard
        case fetchLockedDocked
        case refreshAfterUpload
    }
    enum Route { case none }
    @Published var route: Route?
    var state: State {
        State(
            dashboard: dashboard,
            errorMessage: errorMessage,
            isDashboardLoading: isDashboardLoading,
            isUploadLoading: isUploadLoading,
            isDeleteImageLoading: isDeleteimageLoading,
            deleteSuccessMessage: DeleteSuccessMsg,
            shoreItems: shoreItems,
            zoneItems: zoneItems,
            islandItems: islandItems
        )
    }
    func send(_ action: Action) {
        switch action {
        case .fetchDashboard:
            GetBusinessDashboard()
        case .fetchLockedDocked:
            Getlockeddocked()
        case .refreshAfterUpload:
            refreshDashboardAfterUpload()
        }
    }
    private let businessRepository: BusinessRepositoryProtocol

    init(businessRepository: BusinessRepositoryProtocol) {
        self.businessRepository = businessRepository
    }

    @Published var dashboard: BusinessDashboard?
    @Published var errorMessage: String?
    @Published var isDashboardLoading: Bool = false
    @Published var isUploadLoading: Bool = false
    @Published var isDeleteimageLoading: Bool = false
    @Published var DeleteSuccessMsg: String?


    @Published var shoreItems: [DockItem] = []
    @Published var zoneItems: [DockItem] = []
    @Published var islandItems: [DockItem] = []

    func GetBusinessDashboard() {
        isDashboardLoading = true
        errorMessage = nil

        Task {
            do {
                let fetchedDashboard = try await businessRepository.getBusinessDashboard()
                self.dashboard = fetchedDashboard
                self.isDashboardLoading = false
            } catch {
                self.errorMessage = self.extractErrorMessage(error)
                self.isDashboardLoading = false
            }
        }
    }

    func Getlockeddocked() {
        Task {
            do {
                let dockData = try await businessRepository.getLockedDock()
                self.shoreItems = dockData.shore
                self.zoneItems = dockData.zone
                self.islandItems = dockData.island
                self.isDashboardLoading = false
            } catch {
                self.errorMessage = self.extractErrorMessage(error)
                self.isDashboardLoading = false
            }
        }
    }
    
    func uploadBusinessDashboard(location: String, businessHours: [BusinessHours], isDock: Bool, name: String, shoreId: Int, zoneId: Int, islandId: Int, zipCode: String, shoreLine: String, address: String, latitude: String, longitude: String) {
        guard let lat = Double(latitude), let lon = Double(longitude) else {
            self.errorMessage = "Invalid latitude or longitude"
            self.isUploadLoading = false
            return
        }
        
        // Convert BusinessHours array to dictionary format for JSON encoding
        // API expects "EndTimeTime" based on response format
        let businessHoursDict = businessHours.map { hour in
            [
                "Day": hour.day,
                "StartTime": hour.startTime,
                "EndTimeTime": hour.endTime  // API expects "EndTimeTime"
            ]
        }
        
        let parameters = [
            "Location": location,
            "BusinessHours": businessHoursDict,
            "IsDock": isDock,
            "Name": name,
            "ShoreId": shoreId,
            "ZoneId": zoneId,
            "IslandId": islandId,
            "ZipCode": zipCode,
            "ShoreLine": shoreLine,
            "Address": address,
            "Latitude": lat,
            "Longitude": lon
        ] as [String : Any]
        
        
        isUploadLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await businessRepository.saveBusinessDashboard(parameters: parameters)
                self.isUploadLoading = false
                self.GetBusinessDashboard()
            } catch {
                self.isUploadLoading = false
                self.errorMessage = self.extractErrorMessage(error)
                self.GetBusinessDashboard()
            }
        }
    }

    /// Refreshes dashboard immediately (used after related uploads complete).
    func refreshDashboardAfterUpload() {
        GetBusinessDashboard()
    }

    func DeleteImage(Path: String, completion: @escaping (Bool) -> Void) {
        isDeleteimageLoading = true
        errorMessage = nil
        DeleteSuccessMsg = nil
        
        Task {
            do {
                let successMessage = try await businessRepository.deleteImage(path: Path)
                self.isDeleteimageLoading = false
                self.DeleteSuccessMsg = successMessage
                completion(true)
            } catch {
                self.isDeleteimageLoading = false
                self.errorMessage = self.extractErrorMessage(error)
                completion(false)
            }
        }
    }

    
    
    
    
    
    private func extractErrorMessage(_ error: Error) -> String {
        return ErrorHandler.extractErrorMessage(from: error)
    }
}

