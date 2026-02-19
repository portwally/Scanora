import Foundation

/// Network and API errors for the application
enum NetworkError: LocalizedError, Sendable {
    case invalidBarcode
    case productNotFound
    case networkUnavailable
    case rateLimitExceeded
    case invalidResponse
    case invalidURL
    case decodingFailed(Error)
    case httpError(Int)
    case serverError(Int)
    case timeout
    case cancelled
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidBarcode:
            return String(localized: "error.invalid_barcode")
        case .productNotFound:
            return String(localized: "error.product_not_found")
        case .networkUnavailable:
            return String(localized: "error.network_unavailable")
        case .rateLimitExceeded:
            return String(localized: "error.rate_limit")
        case .invalidResponse:
            return String(localized: "error.invalid_response")
        case .invalidURL:
            return String(localized: "error.invalid_url")
        case .decodingFailed:
            return String(localized: "error.decoding_failed")
        case .httpError(let code):
            return String(localized: "error.http_error \(code)")
        case .serverError:
            return String(localized: "error.server_error")
        case .timeout:
            return String(localized: "error.timeout")
        case .cancelled:
            return String(localized: "error.cancelled")
        case .unknown:
            return String(localized: "error.unknown")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .productNotFound:
            return String(localized: "error.suggestion.product_not_found")
        case .networkUnavailable:
            return String(localized: "error.suggestion.network_unavailable")
        case .rateLimitExceeded:
            return String(localized: "error.suggestion.rate_limit")
        case .timeout:
            return String(localized: "error.suggestion.timeout")
        case .serverError:
            return String(localized: "error.suggestion.server_error")
        default:
            return nil
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .timeout, .serverError, .rateLimitExceeded:
            return true
        default:
            return false
        }
    }

    var showContributeOption: Bool {
        switch self {
        case .productNotFound:
            return true
        default:
            return false
        }
    }
}

// MARK: - Scanner Errors

enum ScannerError: LocalizedError, Sendable {
    case cameraUnavailable
    case cameraAccessDenied
    case cameraAccessRestricted
    case configurationFailed
    case torchUnavailable

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return String(localized: "error.camera_unavailable")
        case .cameraAccessDenied:
            return String(localized: "error.camera_denied")
        case .cameraAccessRestricted:
            return String(localized: "error.camera_restricted")
        case .configurationFailed:
            return String(localized: "error.camera_config_failed")
        case .torchUnavailable:
            return String(localized: "error.torch_unavailable")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .cameraAccessDenied, .cameraAccessRestricted:
            return String(localized: "error.suggestion.camera_access")
        default:
            return nil
        }
    }
}

// MARK: - Persistence Errors

enum PersistenceError: LocalizedError, Sendable {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case migrationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return String(localized: "error.save_failed")
        case .fetchFailed:
            return String(localized: "error.fetch_failed")
        case .deleteFailed:
            return String(localized: "error.delete_failed")
        case .migrationFailed:
            return String(localized: "error.migration_failed")
        }
    }
}
