

//
//  Untitled.swift
//  BoatSharingApp
//
//  Created by Mac User on 02/03/2025.
//
struct BusinessStepTwoModel: Decodable {
    let Status: Int
    let Message: String
    let obj: String
}

// BusinessInfo GET Response Model
struct GetBusinessInfoResponse: Decodable {
    let status: Int
    let message: String
    let obj: GetBusinessInfoProfile?
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj
    }
}

struct GetBusinessInfoProfile: Decodable, Equatable {
    let name: String
    let type: String
    let address: String
    let phoneNumber: String
    let yearOfEstablishment: Int
    let time: String
    let userId: String
    let changedOn: String
    let changedBy: String
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case type = "Type"
        case address = "Address"
        case phoneNumber = "PhoneNumber"
        case yearOfEstablishment = "YearOfEstablishment"
        case time = "Time"
        case userId = "UserId"
        case changedOn = "ChangedOn"
        case changedBy = "ChangedBy"
    }
    
    static func == (lhs: GetBusinessInfoProfile, rhs: GetBusinessInfoProfile) -> Bool {
        return lhs.name == rhs.name &&
               lhs.type == rhs.type &&
               lhs.address == rhs.address &&
               lhs.phoneNumber == rhs.phoneNumber &&
               lhs.yearOfEstablishment == rhs.yearOfEstablishment &&
               lhs.time == rhs.time &&
               lhs.userId == rhs.userId &&
               lhs.changedOn == rhs.changedOn &&
               lhs.changedBy == rhs.changedBy
    }
}

