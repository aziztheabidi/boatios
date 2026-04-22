import Foundation

/// Exact spellings required by backend HTTP/JSON contracts. Keep these at the boundary and out of feature code.
enum BackendContractCoding {

    enum QueryParameter {
        /// Backend query string uses this casing (`id` not `Id`).
        static let voyageCategoryId = "VoyageCategoryid"
    }

    enum VoyageBookPayloadKey {
        static let noOfSponsors = "NoOfSponsors"
        static let noOfSponsorsMisspelled = "NoOfSponsers"
        static let sponsors = "Sponsors"
        static let sponsorsMisspelled = "Sponsers"
        /// Backend field name (missing "i").
        static let individualAmountMisspelled = "IndvidualAmount"
    }

    enum SponsorPaymentInitiateKey {
        static let sponsorUserIdBackendVariant = "SponserUserId"
        static let sponsorUserIdCanonical = "SponsorUserId"
    }
}
