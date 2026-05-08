import Foundation

enum AppError: LocalizedError {
    case business(message: String)
    case emptyPayload
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .business(let message):
            return message.isEmpty ? "Request failed." : message
        case .emptyPayload:
            return "Invalid response from server."
        case .networkError(let message):
            return message.isEmpty ? "A network error occurred." : message
        }
    }
}

struct APIResponseValidator {
    static func requireSuccess<T>(_ response: BaseResponse<T>) throws -> T where T: Codable {
        guard response.isSuccess else {
            throw AppError.business(message: response.Message)
        }
        guard let payload = response.obj else {
            throw AppError.emptyPayload
        }
        return payload
    }
}
