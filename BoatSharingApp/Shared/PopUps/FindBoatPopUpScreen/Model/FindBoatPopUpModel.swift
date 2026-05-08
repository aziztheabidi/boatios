//
//  FindBoatPopUpModel.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 16/06/2025.
//

import Foundation

// MARK: - Voyage Category Response
struct VoyageCategoryResponse: Codable {
    let status: Int
    let message: String
    let categories: [VoyageCategory]

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case categories = "obj"
    }
}

// MARK: - Voyage Category
struct VoyageCategory: Codable, Identifiable {
    let parentId: Int
    let id: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case parentId = "ParentId"
        case id = "Id"
        case name = "Name"
    }
}
