//
//  VoyagerFeedbackModel.swift
//  BoatSharingApp
//
//  Created by Mac User on 20/05/2025.
//

import Foundation

struct FeedbackResponse: Codable {
    let status: Int
    let message: String
    let obj: String

    enum CodingKeys: String, CodingKey {
        case status  = "Status"
        case message = "Message"
        case obj
    }
}
