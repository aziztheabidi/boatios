import SwiftUI
import Combine

@MainActor
final class VoyagerFeedbackViewModel: ObservableObject {
    struct State {
        var selectedRating: Int?
        var remarks: String
        var isFeedbackLoading: Bool
        var isShowingToast: Bool
        var toastMessage: String
    }

    enum Action {
        case selectRating(Int)
        case updateRemarks(String)
        case submit(voyageId: String, source: FeedbackSource)
        case navigateLater(FeedbackSource)
    }

    enum FeedbackSource {
        case voyager
        case captain

        init(from rawValue: String) {
            self = rawValue.lowercased() == "captain" ? .captain : .voyager
        }
    }

    // MARK: - Published state

    @Published var errorMessage: String?
    @Published var isFeedbackLoading: Bool = false
    @Published var isFeedbackSuccess: Bool = false
    @Published var selectedRating: Int?
    @Published var remarks: String = ""
    @Published var toastMessage: String = ""
    @Published var isShowingToast: Bool = false
    enum StackDestination: Hashable {
        case voyagerHome
        case captainHome
    }

    @Published var stackDestination: StackDestination?

    var state: State {
        State(
            selectedRating: selectedRating,
            remarks: remarks,
            isFeedbackLoading: isFeedbackLoading,
            isShowingToast: isShowingToast,
            toastMessage: toastMessage
        )
    }

    // MARK: - Dependencies

    private let networkRepository: AppNetworkRepositoryProtocol
    private var toastHideCancellable: AnyCancellable?

    init(networkRepository: AppNetworkRepositoryProtocol) {
        self.networkRepository = networkRepository
    }

    // MARK: - Send

    func send(_ action: Action) {
        switch action {
        case .selectRating(let index):       selectedRating = index
        case .updateRemarks(let text):       remarks = text
        case .submit(let voyageId, let src): submitFeedback(voyageId: voyageId, source: src)
        case .navigateLater(let src):        routeToHome(for: src)
        }
    }

    // MARK: - Private network

    private func submitFeedback(voyageId: String, source: FeedbackSource) {
        guard let rating = selectedRating,
              !remarks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showErrorToast("Please submit feedback and rating first")
            return
        }
        switch source {
        case .voyager: submitVoyagerFeedback(voyageId: voyageId, rating: rating, review: remarks)
        case .captain: submitCaptainFeedback(voyageId: voyageId, rating: rating, review: remarks)
        }
    }

    private func submitVoyagerFeedback(voyageId: String, rating: Int, review: String) {
        isFeedbackLoading = true
        errorMessage = nil
        Task {
            do {
                let response = try await networkRepository.voyage_voyagerFeedback(
                    parameters: ["Id": voyageId, "Rating": rating, "Review": review]
                )
                isFeedbackLoading = false
                if response.status == 201 {
                    isFeedbackSuccess = true
                    routeToHome(for: .voyager)
                } else {
                    showErrorToast(response.message)
                }
            } catch {
                isFeedbackLoading = false
                showErrorToast(ErrorHandler.extractErrorMessage(from: error))
            }
        }
    }

    private func submitCaptainFeedback(voyageId: String, rating: Int, review: String) {
        isFeedbackLoading = true
        errorMessage = nil
        Task {
            do {
                let response = try await networkRepository.voyage_captainFeedback(
                    parameters: ["Id": voyageId, "Rating": rating, "Review": review]
                )
                isFeedbackLoading = false
                if response.status == 200 {
                    isFeedbackSuccess = true
                    routeToHome(for: .captain)
                } else {
                    showErrorToast(response.message)
                }
            } catch {
                isFeedbackLoading = false
                showErrorToast(ErrorHandler.extractErrorMessage(from: error))
            }
        }
    }

    // MARK: - Helpers

    private func routeToHome(for source: FeedbackSource) {
        switch source {
        case .voyager:
            stackDestination = .voyagerHome
        case .captain:
            stackDestination = .captainHome
        }
    }

    private func showErrorToast(_ message: String) {
        errorMessage = message
        toastMessage = message
        isShowingToast = true
        scheduleToastHide()
    }

    private func scheduleToastHide() {
        toastHideCancellable?.cancel()
        toastHideCancellable = Just(())
            .delay(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.isShowingToast = false }
    }
}

