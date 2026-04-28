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
    let ephemeralKeyAndroid: String
    let paymentIntentId: String

    enum CodingKeys: String, CodingKey {
        case publishableKey = "PublishableKey"
        case customerId = "CustomerId"
        case ephemeralKey = "EphemeralKey"
        case clientSecret = "ClientSecret"
        case ephemeralKeyAndroid = "EphemeralKey_Secret"
        case paymentIntentId = "PaymentIntentId"
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
