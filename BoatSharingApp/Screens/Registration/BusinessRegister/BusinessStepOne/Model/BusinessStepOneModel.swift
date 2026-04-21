//
//  BusinessStepOneModel.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 25/02/2025.
//

import Foundation

struct BusinessStepOneModel: Decodable {
    let Status: Int
    let Message: String
    let obj: String
}
// BusinessProfile model
struct GetBusinessFirstProfile: Decodable, Equatable {
    let phoneNumber: String
    let firstName: String
    let lastName: String
    let address: String
    let dateOfBirth: String
    let stripeEmail: String
    let userId: String
    let changedOn: String
    let changedBy: String
    
    
    
   
    

    // Equatable conformance: Compare all properties for equality
    static func == (lhs: GetBusinessFirstProfile, rhs: GetBusinessFirstProfile) -> Bool {
        return lhs.phoneNumber == rhs.phoneNumber &&
               lhs.firstName == rhs.firstName &&
               lhs.lastName == rhs.lastName &&
               lhs.address == rhs.address &&
               lhs.dateOfBirth == rhs.dateOfBirth &&
               lhs.stripeEmail == rhs.stripeEmail &&
               lhs.userId == rhs.userId &&
               lhs.changedOn == rhs.changedOn &&
               lhs.changedBy == rhs.changedBy
    }
    
    enum CodingKeys: String, CodingKey {
        case phoneNumber = "PhoneNumber"
        case firstName = "FirstName"
        case lastName = "LastName"
        case address = "Address"
        case dateOfBirth = "DateOfBirth"
        case stripeEmail = "StripeEmail"
        case userId = "UserId"
        case changedOn = "ChangedOn"
        case changedBy = "ChangedBy"
    }
    
    
}

// API Response model
struct GetBusinessFirstResponse: Decodable {
    var status: Int
    var message: String
    var obj: GetBusinessFirstProfile
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
       
    }
    
    
}
