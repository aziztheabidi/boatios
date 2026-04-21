//
//  NewRequestPopUpModel.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 17/04/2025.
//

import Foundation

struct PaymentInitiationResponse: Codable {
    let status: Int
    let message: String
    let obj: PaymentInitiationData
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
    
}


struct PaymentInitiationData: Codable, Equatable {
    let publishableKey: String
    let customerId: String
    let ephemeralKey: String
    let clientSecret: String
    let ephemeralKey_android: String
    let PaymentIntentId: String

    enum CodingKeys: String, CodingKey {
        case publishableKey = "PublishableKey"
        case customerId = "CustomerId"
        case ephemeralKey = "EphemeralKey"
        case clientSecret = "ClientSecret"
        case ephemeralKey_android = "EphemeralKey_Secret"
        case PaymentIntentId = "PaymentIntentId"
        
    }
}
struct PaymentSuccessResponse: Codable {
    let status: Int
    let message: String
    let obj: String
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
        case obj = "obj"
    }
    
}
