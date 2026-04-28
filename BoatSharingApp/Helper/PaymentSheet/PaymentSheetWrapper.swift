//
//  PaymentSheet.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 21/04/2025.
//

import SwiftUI

#if canImport(Stripe) && canImport(StripePaymentSheet)
import Stripe
import StripePaymentSheet
#else
/// Stub types used when Stripe frameworks are not linked (e.g. selective local builds).
enum StripeAPI {
    static var defaultPublishableKey: String = ""
}

enum PaymentSheetResult {
    case completed
    case canceled
    case failed(Error)
}

struct PaymentSheet {
    struct Configuration {
        var merchantDisplayName: String = ""
        var allowsDelayedPaymentMethods: Bool = false
        var returnURL: String?
        var defaultBillingDetails = BillingDetails()
    }

    struct BillingDetails {
        var name: String?
    }

    init(paymentIntentClientSecret: String, configuration: Configuration) {}

    func present(from controller: UIViewController, completion: @escaping (PaymentSheetResult) -> Void) {
        completion(.failed(NSError(domain: "StripeDisabled", code: -1, userInfo: [NSLocalizedDescriptionKey: "Stripe is disabled for this build"])))
    }
}
#endif

struct PaymentSheetWrapper: UIViewControllerRepresentable {
    let paymentSheet: PaymentSheet
    let onCompletion: (PaymentSheetResult) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        Task { @MainActor in
            paymentSheet.present(from: controller) { result in
                onCompletion(result)
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

