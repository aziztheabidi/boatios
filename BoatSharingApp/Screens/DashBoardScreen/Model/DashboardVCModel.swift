import Foundation
import SwiftUI
import SDWebImageSwiftUI

// Top-level response struct
struct ApiResponse: Codable {
    let status: Int
    let message: String
    let obj: BusinessDashboard
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj
    }
}

// Business Dashboard object
struct BusinessDashboard: Codable, Equatable {
    let logoPath: String
    let businessType: String
    let yearOfEstablishment: Int
    let description: String
    let imagesPath: [String]
    var location: String
    var businessHours: [BusinessHours]
    let isDock: Bool
    let name: String
    let shoreId: Int
    let zoneId: Int
    let islandId: Int
    let state: String
    let city: String
    let zipCode: String
    let address: String
    let latitude: Double
    let ShoreName: String
    let ZoneName: String
    let IslandName: String
    let longitude: Double
    let userId: String
    let changedOn: String
    let changedBy: String

    enum CodingKeys: String, CodingKey {
        case logoPath = "LogoPath"
        case businessType = "BusinessType"
        case yearOfEstablishment = "YearOfEstablishment"
        case description = "Description"
        case imagesPath = "ImagesPath"
        case location = "Location"
        case businessHours = "BusinessHours"
        case isDock = "IsDock"
        case name = "Name"
        case shoreId = "ShoreId"
        case zoneId = "ZoneId"
        case islandId = "IslandId"
        case state = "State"
        case city = "City"
        case zipCode = "ZipCode"
        case address = "Address"
        case latitude = "Latitude"
        case longitude = "Longitude"
        case userId = "UserId"
        case ShoreName = "ShoreName"
        case ZoneName = "ZoneName"
        case IslandName = "IslandName"
        case changedOn = "ChangedOn"
        case changedBy = "ChangedBy"
    }
    
    static func == (lhs: BusinessDashboard, rhs: BusinessDashboard) -> Bool {
        return lhs.logoPath == rhs.logoPath &&
               lhs.businessType == rhs.businessType &&
               lhs.yearOfEstablishment == rhs.yearOfEstablishment &&
               lhs.description == rhs.description &&
               lhs.imagesPath == rhs.imagesPath &&
               lhs.location == rhs.location &&
               lhs.businessHours == rhs.businessHours &&
               lhs.isDock == rhs.isDock &&
               lhs.name == rhs.name &&
               lhs.shoreId == rhs.shoreId &&
               lhs.zoneId == rhs.zoneId &&
               lhs.islandId == rhs.islandId &&
               lhs.state == rhs.state &&
               lhs.city == rhs.city &&
               lhs.zipCode == rhs.zipCode &&
               lhs.ShoreName == rhs.ShoreName &&
               lhs.IslandName == rhs.IslandName &&
               lhs.ZoneName == rhs.ZoneName &&
               lhs.address == rhs.address &&
               lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude &&
               lhs.userId == rhs.userId &&
               lhs.changedOn == rhs.changedOn &&
               lhs.changedBy == rhs.changedBy
    }
}

// Business hours for each day
struct BusinessHours: Codable, Equatable {
    let day: String
    var startTime: String
    var endTime: String

    enum CodingKeys: String, CodingKey {
        case day = "Day"
        case startTime = "StartTime"
        case endTime = "EndTimeTime"  // API returns "EndTimeTime" not "EndTime"
    }
    
    static func == (lhs: BusinessHours, rhs: BusinessHours) -> Bool {
        return lhs.day == rhs.day &&
               lhs.startTime == rhs.startTime &&
               lhs.endTime == rhs.endTime
    }
}

// API response struct for upload
struct UploadApiResponse: Codable {
    let status: Int
    let message: String
    let obj: String?

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj
    }
}

// DockItem.swift
struct DockDropdownResponse: Codable {
    let status: Int
    let message: String
    let obj: DockDropdownData

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
}

struct DockDropdownData: Codable {
    let shore: [DockItem]
    let zone: [DockItem]
    let island: [DockItem]

    enum CodingKeys: String, CodingKey {
        case shore = "Shore"
        case zone = "Zone"
        case island = "Island"
    }
}

struct DockItem: Codable, Identifiable {
    let parentId: Int
    let id: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case parentId = "ParentId"
        case id = "Id"
        case name = "Name"
    }
}
// delte image
struct DeleteImageResponse: Codable {
    let status: Int
    let message: String
    let obj: String

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
}
