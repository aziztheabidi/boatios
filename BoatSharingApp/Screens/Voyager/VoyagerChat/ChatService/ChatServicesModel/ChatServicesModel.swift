//
//  ChatServicesModel.swift
//  BoatSharingApp
//
//  Created by Mac User on 25/05/2025.
//

// Message.swift
import Foundation

struct ChatServicesModel: Identifiable {
    let id: String
    let text: String
    let senderId: String
    let timestamp: Date
}

struct TagChatMessage: Codable {
    let status: Int
    let message: String
    let obj: String?

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
}


