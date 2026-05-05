import Foundation
#if canImport(GoogleMaps)
import GoogleMaps
#endif
#if canImport(Stripe)
import Stripe
#endif

enum AppServices {
    private static var didConfigure = false

    static func configure() {
        guard !didConfigure else { return }
        didConfigure = true

        #if canImport(GoogleMaps)
        GMSServices.provideAPIKey(AppConfig.googleAPIKey)
        #endif
        #if canImport(Stripe)
        StripeAPI.defaultPublishableKey = AppConfig.stripePublishableKey
        #endif
    }
}
