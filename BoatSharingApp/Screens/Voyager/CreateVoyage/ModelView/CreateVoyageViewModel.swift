import Foundation
import SwiftUI
import Combine

protocol DateFormatting {
    func formatDate(_ date: Date) -> String
    func formatTime(_ date: Date) -> String
}

extension DateFormatterHelper: DateFormatting {}

@MainActor
class CreateVoyageViewModel: ObservableObject {
    struct State {
        let isTravelNow: Bool
        let showCalendar: Bool
        let selectedDate: Date?
        let showStartTimePicker: Bool
        let selectedStartTime: Date?
        let isSpendOnWater: Bool
        let showEndTimePicker: Bool
        let selectedEndTime: Date?
        let showToast: Bool
        let toastMessage: String
        let moveToNextScreen: Bool
        let route: Route?
    }
    enum Action {
        case onAppear
        case onDisappear
        case saveAndProceed(UIFlowState)
        case setTravelNow(Bool)
        case setSpendOnWater(Bool)
        case setSelectedDate(Date?)
        case setSelectedStartTime(Date?)
        case setSelectedEndTime(Date?)
        case setShowCalendar(Bool)
        case setShowStartTimePicker(Bool)
        case setShowEndTimePicker(Bool)
        case dismissToast
        case clearNavigation
    }
    enum Route {
        case proceedToRate
    }
    @Published var route: Route?
    var state: State {
        State(
            isTravelNow: isTravelNow,
            showCalendar: showCalendar,
            selectedDate: selectedDate,
            showStartTimePicker: showStartTimePicker,
            selectedStartTime: selectedStartTime,
            isSpendOnWater: isSpendOnWater,
            showEndTimePicker: showEndTimePicker,
            selectedEndTime: selectedEndTime,
            showToast: showToast,
            toastMessage: toastMessage,
            moveToNextScreen: moveToNextScreen,
            route: route
        )
    }
    func send(_ action: Action) {
        switch action {
        case .onAppear, .onDisappear:
            break
        case .saveAndProceed(let flowState):
            saveAndProceed(using: flowState)
        case .setTravelNow(let value):
            isTravelNow = value
        case .setSpendOnWater(let value):
            isSpendOnWater = value
        case .setSelectedDate(let value):
            selectedDate = value
        case .setSelectedStartTime(let value):
            selectedStartTime = value
        case .setSelectedEndTime(let value):
            selectedEndTime = value
        case .setShowCalendar(let value):
            showCalendar = value
        case .setShowStartTimePicker(let value):
            showStartTimePicker = value
        case .setShowEndTimePicker(let value):
            showEndTimePicker = value
        case .dismissToast:
            showToast = false
            toastMessage = ""
        case .clearNavigation:
            moveToNextScreen = false
            route = nil
        }
    }
    @Published var isTravelNow: Bool = false {
        didSet {
            if isTravelNow {
                selectedDate = Date()
                showCalendar = false
            } else {
                selectedDate = nil
            }
        }
    }
    @Published var showCalendar: Bool = false
    @Published var selectedDate: Date? = nil

    @Published var showStartTimePicker: Bool = false
    @Published var selectedStartTime: Date? = nil

    @Published var isSpendOnWater: Bool = false
    @Published var showEndTimePicker: Bool = false
    @Published var selectedEndTime: Date? = nil

    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    @Published var moveToNextScreen: Bool = false
    private let dateFormatter: DateFormatting

    init(dateFormatter: DateFormatting) {
        self.dateFormatter = dateFormatter
    }

    func calculateHours(from start: Date, to end: Date) -> Double {
        let interval = end.timeIntervalSince(start)
        return max(interval / 3600, 0)
    }

    func timeDifference(from start: Date, to end: Date) -> String {
        let interval = end.timeIntervalSince(start)
        if interval <= 0 {
            return "Invalid duration"
        }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        var parts: [String] = []
        if hours > 0 {
            parts.append("\(hours)h")
        }
        if minutes > 0 || hours == 0 {
            parts.append("\(minutes)m")
        }

        return parts.joined(separator: " ")
    }

    func saveAndProceed(using flowState: UIFlowState) {
        guard let date = selectedDate, let startTime = selectedStartTime else {
            showToast = true
            toastMessage = "Please select a date and start time."
            return
        }

        if isSpendOnWater {
            guard let endTime = selectedEndTime else {
                showToast = true
                toastMessage = "Please select end time."
                return
            }

            let estimatedHours = calculateHours(from: startTime, to: endTime)
            flowState.voyageDraft.startDateISO8601 = ISO8601DateFormatter().string(from: date)
            flowState.voyageDraft.startTime = dateFormatter.formatTime(startTime)
            flowState.voyageDraft.endTime = dateFormatter.formatTime(endTime)
            flowState.voyageDraft.estimatedHours = estimatedHours
        } else {
            flowState.voyageDraft.startDateISO8601 = ISO8601DateFormatter().string(from: date)
            flowState.voyageDraft.startTime = dateFormatter.formatTime(startTime)
            flowState.voyageDraft.endTime = dateFormatter.formatTime(startTime)
            flowState.voyageDraft.estimatedHours = 0
        }
        flowState.voyageDraft.isSpendOnWater = isSpendOnWater
        flowState.voyageDraft.isTravelNow = isTravelNow

        moveToNextScreen = true
        route = .proceedToRate
    }

    func formattedDate(_ date: Date?) -> String {
        guard let date else { return "Select Date" }
        return dateFormatter.formatDate(date)
    }

    func formattedTime(_ time: Date?, placeholder: String) -> String {
        guard let time else { return placeholder }
        return dateFormatter.formatTime(time)
    }
}


