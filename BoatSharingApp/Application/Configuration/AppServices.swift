import Foundation
import GoogleMaps
#if canImport(Stripe)
import Stripe
#endif

enum AppServices {
    private static var didConfigure = false

    static func configure() {
        guard !didConfigure else { return }
        didConfigure = true

        GMSServices.provideAPIKey(AppConfig.googleAPIKey)
        #if canImport(Stripe)
        StripeAPI.defaultPublishableKey = AppConfig.stripePublishableKey
        #endif
    }
}
