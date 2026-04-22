import SwiftUI
import CoreLocation

// MARK: - Location protocol (preserved)

protocol CaptainLocationProviding {
    var currentCoordinate: CLLocationCoordinate2D? { get }
}

extension LocationManager: CaptainLocationProviding {
    var currentCoordinate: CLLocationCoordinate2D? { currentLocation }
}

// MARK: - ViewModel

@MainActor
final class CaptainActiveVoyageViewModel: ObservableObject {

    // MARK: - Section

    enum Section: String {
        case pending  = "Pending"
        case accepted = "Accepted"
        case started  = "Started"
    }

    // MARK: - State

    struct State {
        let selectedSection: Section
        let pendingVoyages: [CaptainVoyage]
        let acceptedVoyages: [CaptainVoyage]
        let startedVoyages: [CaptainVoyage]
        let isLoading: Bool
        let voyageErrorMessage: String?
        let showCompletePopup: Bool
        let showDeclineAlert: Bool
        let shouldNavigateToFeedback: Bool
        let shouldNavigateToLogin: Bool
    }

    var state: State {
        State(
            selectedSection: selectedSection,
            pendingVoyages: pendingVoyages,
            acceptedVoyages: acceptedVoyages,
            startedVoyages: startedVoyages,
            isLoading: isLoading,
            voyageErrorMessage: voyageErrorMessage,
            showCompletePopup: showCompletePopup,
            showDeclineAlert: showDeclineAlert,
            shouldNavigateToFeedback: shouldNavigateToFeedback,
            shouldNavigateToLogin: shouldNavigateToLogin
        )
    }

    // MARK: - Actions

    enum Action {
        case onAppear
        case onDisappear
        case retry
        case selectSection(Section)
        case accept(CaptainVoyage)
        case prepareStartFlow(CaptainVoyage)
        case handleTrackRidePin(String)
        case clearTrackRideSelection
        case requestCompleteVoyage(String)
        case cancelCompletePrompt
        case confirmCompleteVoyage
        case requestDeclineVoyage(String)
        case confirmDeclineVoyage
        case handleSessionExpiredAcknowledged
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:                           onAppearLoad()
        case .onDisappear:                        hasLoaded = false
        case .retry:                              fetchActiveVoyages()
        case .selectSection(let s):               selectedSection = s
        case .accept(let v):                      performAccept(v)
        case .prepareStartFlow(let v):            prepareStartFlow(for: v)
        case .handleTrackRidePin(let pin):        handleTrackRidePin(pin)
        case .clearTrackRideSelection:            trackRideSession = nil
        case .requestCompleteVoyage(let id):      selectedVoyageIdForCompletion = id; showCompletePopup = true
        case .cancelCompletePrompt:               showCompletePopup = false
        case .confirmCompleteVoyage:              confirmCompleteVoyage()
        case .requestDeclineVoyage(let id):       declineVoyageId = id; showDeclineAlert = true
        case .confirmDeclineVoyage:               confirmDeclineVoyage()
        case .handleSessionExpiredAcknowledged:   shouldNavigateToLogin = true; route = .login
        }
    }

    // MARK: - Route

    enum Route { case feedback(voyageId: String); case login }
    @Published var route: Route?

    // MARK: - Track-ride session

    struct CaptainTrackRideSession: Identifiable, Equatable {
        let id: String
        let details: VoyageBookingDetails
        let currentUserId: String

        init(details: VoyageBookingDetails, currentUserId: String) {
            self.id = details.voyageID
            self.details = details
            self.currentUserId = currentUserId
        }
    }

    // MARK: - Published state

    @Published var pendingVoyages: [CaptainVoyage] = []
    @Published var acceptedVoyages: [CaptainVoyage] = []
    @Published var startedVoyages: [CaptainVoyage] = []
    @Published var isLoading: Bool = false
    @Published var isAcceptLoading: Bool = false
    @Published var voyageErrorMessage: String?
    @Published var isTokenExpired: Bool = false
    @Published var selectedVoyageIdForCompletion: String = ""
    @Published var trackRideSession: CaptainTrackRideSession?
    @Published var showCompletePopup: Bool = false
    @Published var showDeclineAlert: Bool = false
    @Published var shouldNavigateToFeedback: Bool = false
    @Published var feedbackVoyageId: String = ""
    @Published var shouldNavigateToLogin: Bool = false
    @Published var voyageIdForStart: String = ""
    @Published var declineVoyageId: String = ""
    @Published var selectedSection: Section = .pending
    @Published var VoyageAccepted: Bool = false
    @Published var VoyageCompleted: Bool = false

    // MARK: - Dependencies

    private let networkRepository: AppNetworkRepositoryProtocol
    private let identityProvider: SessionPreferenceStoring
    private let locationProvider: CaptainLocationProviding
    private var hasLoaded = false

    init(
        networkRepository: AppNetworkRepositoryProtocol,
        identityProvider: SessionPreferenceStoring,
        locationProvider: CaptainLocationProviding? = nil
    ) {
        self.networkRepository = networkRepository
        self.identityProvider = identityProvider
        self.locationProvider = locationProvider ?? LocationManager(sessionPreferences: identityProvider)
    }

    // MARK: - Derived

    private var requiredCaptainUserId: String? {
        let id = identityProvider.userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else {
            voyageErrorMessage = "Missing captain user id for voyage actions."
            return nil
        }
        return id
    }

    // MARK: - Private lifecycle

    private func onAppearLoad() {
        guard !hasLoaded else { return }
        hasLoaded = true
        fetchActiveVoyages()
    }

    // MARK: - Private action handlers

    private func confirmCompleteVoyage() {
        guard !selectedVoyageIdForCompletion.isEmpty else { return }
        let id = selectedVoyageIdForCompletion
        showCompletePopup = false
        performVoyageComplete(voyageId: id)
    }

    private func confirmDeclineVoyage() {
        guard !declineVoyageId.isEmpty else { return }
        let id = declineVoyageId
        showDeclineAlert = false
        performVoyageCancel(voyageId: id)
    }

    private func prepareStartFlow(for voyage: CaptainVoyage) {
        feedbackVoyageId = voyage.id
        buildTrackRideSession(for: voyage)
        voyageIdForStart = trackRideSession != nil ? voyage.id : ""
    }

    private func handleTrackRidePin(_ pin: String) {
        guard !voyageIdForStart.isEmpty else { return }
        let id = voyageIdForStart
        trackRideSession = nil
        performVoyageStart(voyageId: id, otp: pin)
    }

    private func performAccept(_ voyage: CaptainVoyage) {
        guard let captainId = requiredCaptainUserId else { return }
        let coordinate = locationProvider.currentCoordinate
        performVoyageAccept(
            voyageId: voyage.id,
            captainId: captainId,
            latitude: coordinate?.latitude ?? 0.0,
            longitude: coordinate?.longitude ?? 0.0
        )
    }

    private func buildTrackRideSession(for voyage: CaptainVoyage) {
        guard let userId = requiredCaptainUserId else { return }
        let peerId = voyage.voyagerUserId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !peerId.isEmpty else { voyageErrorMessage = "Missing voyager account for this voyage."; return }
        let details = VoyageBookingDetails(
            voyageID: voyage.id,
            voyagerName: voyage.voyagerName,
            voyagerCount: voyage.noOfVoyager,
            pickupDock: voyage.pickupDock,
            dropOffDock: voyage.dropOffDock,
            amountToPay: voyage.amountToPay,
            duration: voyage.duration ?? "",
            waterStay: voyage.waterStay,
            bookingDateTime: voyage.bookingDateTime,
            voyagerPhone: voyage.voyagerPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            chatPeerUserId: peerId
        )
        trackRideSession = CaptainTrackRideSession(details: details, currentUserId: userId)
    }

    // MARK: - Private network

    private func fetchActiveVoyages() {
        isLoading = true
        voyageErrorMessage = nil
        Task {
            do {
                let response = try await networkRepository.captain_getActiveVoyages()
                self.isLoading = false
                self.pendingVoyages  = response.obj.pending
                self.acceptedVoyages = response.obj.accepted
                self.startedVoyages  = response.obj.started
            } catch let error as APIError {
                self.isLoading = false
                if case .unauthorized = error { self.isTokenExpired = true }
                else { self.voyageErrorMessage = ErrorHandler.extractErrorMessage(from: error) }
            } catch {
                self.isLoading = false
                self.voyageErrorMessage = error.localizedDescription
            }
        }
    }

    private func performVoyageAccept(voyageId: String, captainId: String, latitude: Double, longitude: Double) {
        isAcceptLoading = true
        let params: [String: Any] = [
            "Id": voyageId, "CaptainUserId": captainId,
            "CaptainBookingLatitude": latitude, "CaptainBookingLongitude": longitude
        ]
        Task {
            do {
                _ = try await networkRepository.voyage_accept(parameters: params)
                self.isAcceptLoading = false
                self.VoyageAccepted = true
                self.fetchActiveVoyages()
            } catch {
                self.isAcceptLoading = false
                self.voyageErrorMessage = ErrorHandler.extractErrorMessage(from: error)
                self.fetchActiveVoyages()
            }
        }
    }

    private func performVoyageCancel(voyageId: String) {
        isLoading = true
        Task {
            do {
                _ = try await networkRepository.voyage_cancel(voyageId: voyageId)
                self.isLoading = false
                self.fetchActiveVoyages()
            } catch {
                self.isLoading = false
                self.voyageErrorMessage = ErrorHandler.extractErrorMessage(from: error)
                self.fetchActiveVoyages()
            }
        }
    }

    private func performVoyageStart(voyageId: String, otp: String) {
        isLoading = true
        Task {
            do {
                _ = try await networkRepository.voyage_start(parameters: ["Id": voyageId, "OTP": otp])
                self.isLoading = false
                self.fetchActiveVoyages()
            } catch {
                self.isLoading = false
                self.voyageErrorMessage = ErrorHandler.extractErrorMessage(from: error)
                self.fetchActiveVoyages()
            }
        }
    }

    private func performVoyageComplete(voyageId: String) {
        isLoading = true
        Task {
            do {
                _ = try await networkRepository.voyage_complete(parameters: ["Id": voyageId])
                self.isLoading = false
                self.VoyageCompleted = true
                self.shouldNavigateToFeedback = true
                self.route = .feedback(voyageId: voyageId)
                self.fetchActiveVoyages()
            } catch {
                self.isLoading = false
                self.voyageErrorMessage = ErrorHandler.extractErrorMessage(from: error)
                self.fetchActiveVoyages()
            }
        }
    }

    // MARK: - Public action helpers

    func getCaptainActiveVoyages() { fetchActiveVoyages() }
    func acceptVoyage(voyageId: String, captainId: String, captainBookingLatitude: Double, captainBookingLongitude: Double) {
        performVoyageAccept(voyageId: voyageId, captainId: captainId, latitude: captainBookingLatitude, longitude: captainBookingLongitude)
    }
    func accept(_ voyage: CaptainVoyage) { send(.accept(voyage)) }
    func prepareTrackRide(for voyage: CaptainVoyage) { buildTrackRideSession(for: voyage) }
    func clearTrackRideSelection() { send(.clearTrackRideSelection) }
    func VoyageCancel(Voyageid: String) { performVoyageCancel(voyageId: Voyageid) }
    func VoyageStart(Voyageid: String, OTP: String) { performVoyageStart(voyageId: Voyageid, otp: OTP) }
    func VoyageComplete(Voyageid: String) { performVoyageComplete(voyageId: Voyageid) }
    func onAppearLoad() { send(.onAppear) }
    func onDisappearReset() { send(.onDisappear) }
    func requestCompleteVoyage(_ id: String) { send(.requestCompleteVoyage(id)) }
    func cancelCompletePrompt() { send(.cancelCompletePrompt) }
    func confirmCompleteVoyagePublic() { send(.confirmCompleteVoyage) }
    func requestDeclineVoyage(_ id: String) { send(.requestDeclineVoyage(id)) }
    func confirmDeclineVoyage() { send(.confirmDeclineVoyage) }
    func handleTrackRidePin(_ pin: String) { send(.handleTrackRidePin(pin)) }
    func handleSessionExpiredAcknowledged() { send(.handleSessionExpiredAcknowledged) }
}

