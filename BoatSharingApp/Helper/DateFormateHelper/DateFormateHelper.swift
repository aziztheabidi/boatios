//
//  DateFormateHelper.swift
//  BoatSharingApp
//
//  Created by Mac User on 28/05/2025.
//

import Foundation

struct DateFormatterHelper {
    private let timeFormatter: DateFormatter
    private let dateFormatter: DateFormatter

    init() {
        timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
    }

    func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
