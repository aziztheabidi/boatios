import Foundation

struct AppConfig {
    private init() {}

    static var googleAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_API_KEY") as? String,
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fatalError("Missing GOOGLE_API_KEY")
        }
        return key
    }

    static var stripePublishableKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "STRIPE_PUBLISHABLE_KEY") as? String,
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fatalError("Missing STRIPE_PUBLISHABLE_KEY")
        }
        return key
    }
}

/// Centralized configuration for the entire application
struct AppConfiguration {

    private init() {}
    
    // MARK: - API Configuration
    struct API {
        static let baseURL = "https://boatitapi.com/api"
        static let imageBaseURL = "https://boatitapi.com/"
        static let timeout: TimeInterval = 30.0
        
        // Endpoints
        struct Endpoints {
            static let login = "/Account/Login"
            static let register = "/Account/Register"
            static let refreshToken = "/Account/RefreshToken"
            static let updateDeviceToken = "/Account/UpdateDeviceToken"
            static let forgotPassword = "/Account/ForgotPassword"
            static let resetPassword = "/Account/ResetPassword"
            
            // Dashboard
            static let dashboardData = "/Dashboard/GetData"
            
            // Voyager
            static let voyagerActiveVoyage = "/VoyagerDashboard/GetActiveVoyage"
            static let voyagerPastVoyages = "/VoyagerDashboard/GetPastVoyages"
            static let voyagerFutureVoyages = "/Voyager/GetFutureBookedVoyagesByUserId"
            static let voyagerRelationship = "/Voyager/GetRelationship"
            
            // Captain
            static let captainActiveVoyages = "/Captain/GetActiveVoyages"
            static let captainPastVoyages = "/Captain/GetPastVoyages"
            static let captainProfile = "/CaptainProfile/GetByUserId"
            static let captainAvailability = "/CaptainProfile/Availability"
            
            // Business
            static let businessActiveVoyages = "/Business/GetActiveVoyages"
            static let businessProfile = "/BusinessProfile/GetByUserId"
            
            // Dock
            static let docksPublic = "/Dock/GetAllPublic"
            static let docksActive = "/Dock/GetActive"
            
            // Voyage
            static let voyageCalculateFare = "/Voyage/CaculateFair"
            // Canonical name (API path kept as backend contract)
            static let voyageCalculateFair = voyageCalculateFare
            static let voyageFindBoat = "/Voyage/FindBoat"
            static let voyageBook = "/Voyage/Book"
            static let voyageCancel = "/Voyage/Cancel"
            static let voyageStart = "/Voyage/Start"
            static let voyageComplete = "/Voyage/Complete"
            /// Backend route uses legacy spelling `Sponser`.
            static let sponsorPaymentConfirmation = "/Voyage/SponserPaymentConfirmation"
            /// Backend route uses legacy spelling `Sponser`.
            static let sponsorPaymentInitiate = "/Voyage/SponserPaymentInitiate"
            /// Backend route uses legacy spelling `Sponser`.
            static let voyagerSponsorPaymentsByUserId = "/Voyager/GetSponserPaymentsByUserId"
            static let businessSaveMedia = "/BusinessInfo/SaveMedia"
        }
    }
    
    // MARK: - Web URLs
    struct Web {
        static let privacyPolicy = "https://www.boatit.com/legal/privacy-policy"
    }
    
    // MARK: - App Settings
    struct Settings {
        static let appName = "BoatIT"
        static let minimumPasswordLength = 6
        static let otpLength = 4
        static let sessionTimeoutMinutes = 30
    }
    
    // MARK: - Keychain Keys
    struct KeychainKeys {
        static let accessToken = "AccessToken"
        static let refreshToken = "RefreshToken"
        static let deviceToken = "DeviceToken"
        static let fcmToken = "FCMToken"
    }

    // MARK: - Preferences Keys (UserDefaults)
    struct PreferenceKeys {
        static let userID = "UserID"
        static let username = "Username"
        static let userRole = "UserRole"
        static let userEmail = "UserEmail"
        static let missingStep = "MissingStep"
        static let isLoggedIn = "isLoggedIn"
        static let fromBusinessDetail = "fromBusinessDetail"
        static let captainStatus = "Captain_status"
    }
    
    // MARK: - User Roles
    enum UserRole: String {
        case voyager = "Voyager"
        case captain = "Captain"
        case business = "Business"
        case admin = "Admin"
        
        var displayName: String {
            return rawValue
        }

        static func normalize(_ rawRole: String) -> String {
            let trimmed = rawRole.trimmingCharacters(in: .whitespacesAndNewlines)
            switch trimmed.lowercased() {
            case "bussiness", "business":
                return UserRole.business.rawValue
            case "captain":
                return UserRole.captain.rawValue
            case "voyager":
                return UserRole.voyager.rawValue
            case "admin":
                return UserRole.admin.rawValue
            default:
                return trimmed
            }
        }
    }
}
