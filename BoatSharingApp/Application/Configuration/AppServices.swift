import Foundation
#if canImport(GoogleMaps)
import GoogleMaps
#endif
#if canImport(Stripe)
import Stripe
#endif

enum AppServices {
    private static let configureOnce: Void = {
        #if canImport(GoogleMaps)
        GMSServices.provideAPIKey(AppConfig.googleAPIKey)
        #endif
        #if canImport(Stripe)
        StripeAPI.defaultPublishableKey = AppConfig.stripePublishableKey
        #endif
    }()

    static func configure() {
        _ = configureOnce
    }
}
