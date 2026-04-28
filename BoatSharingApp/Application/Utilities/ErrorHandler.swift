import Foundation
import Alamofire

/// Centralized error handling utilities
struct ErrorHandler {
    
    /// Extract user-friendly error message from various error types
    static func extractErrorMessage(from error: Error) -> String {
        // Check if it's our custom APIError
        if let apiError = error as? APIError {
            return apiError.errorDescription ?? "An unknown error occurred"
        }
        
        // Check if it's an AFError
        if let afError = error as? AFError {
            return extractMessageFromAFError(afError)
        }
        
        // Check if it's a DecodingError
        if let decodingError = error as? DecodingError {
            return extractMessageFromDecodingError(decodingError)
        }
        
        // Default fallback
        return error.localizedDescription
    }
    
    /// Extract message from Alamofire error
    private static func extractMessageFromAFError(_ error: AFError) -> String {
        switch error {
        case .sessionTaskFailed(let sessionError):
            let nsError = sessionError as NSError
            switch nsError.code {
            case NSURLErrorTimedOut:
                return "Request timed out. Please check your internet connection."
            case NSURLErrorNotConnectedToInternet:
                return "No internet connection available."
            case NSURLErrorNetworkConnectionLost:
                return "Network connection lost. Please try again."
            case NSURLErrorCannotConnectToHost:
                return "Cannot connect to server. Please try again later."
            default:
                return "Network error: \(sessionError.localizedDescription)"
            }
            
        case .responseValidationFailed(let reason):
            switch reason {
            case .unacceptableStatusCode(let code):
                return "Server error (Code: \(code)). Please try again."
            default:
                return "Invalid server response"
            }
            
        case .responseSerializationFailed(let reason):
            switch reason {
            case .decodingFailed(let error):
                return extractMessageFromDecodingError(error as? DecodingError)
            default:
                return "Failed to process server response"
            }
            
        default:
            return error.localizedDescription
        }
    }
    
    /// Extract message from DecodingError
    private static func extractMessageFromDecodingError(_ error: DecodingError?) -> String {
        guard let error = error else {
            return "Failed to decode response"
        }
        
        switch error {
        case .keyNotFound(let key, _):
            return "Missing required field: \(key.stringValue)"
        case .typeMismatch(let type, let context):
            return "Type mismatch for field '\(context.codingPath.last?.stringValue ?? "unknown")': expected \(type)"
        case .valueNotFound(let type, let context):
            return "Missing value for field '\(context.codingPath.last?.stringValue ?? "unknown")' of type \(type)"
        case .dataCorrupted(let context):
            return "Data corrupted: \(context.debugDescription)"
        @unknown default:
            return "Failed to decode response"
        }
    }
    
    /// Check if error is related to authentication
    static func isAuthenticationError(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized, .sessionExpired:
                return true
            default:
                return false
            }
        }
        
        if let afError = error as? AFError,
           case .responseValidationFailed(let reason) = afError,
           case .unacceptableStatusCode(let code) = reason {
            return code == 401
        }
        
        return false
    }
    
    /// Check if error is a network connectivity issue
    static func isNetworkError(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            switch apiError {
            case .noInternetConnection, .timeout:
                return true
            default:
                return false
            }
        }
        
        if let afError = error as? AFError,
           case .sessionTaskFailed(let sessionError) = afError {
            let nsError = sessionError as NSError
            return nsError.code == NSURLErrorTimedOut ||
                   nsError.code == NSURLErrorNotConnectedToInternet ||
                   nsError.code == NSURLErrorNetworkConnectionLost
        }
        
        return false
    }
}
