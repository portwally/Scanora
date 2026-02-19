import Foundation

// MARK: - Protocol

protocol OpenFoodFactsAPIProtocol: Sendable {
    func fetchProduct(barcode: String) async throws -> Product
    func searchProducts(query: String, page: Int) async throws -> [Product]
}

// MARK: - Open Food Facts API Client

final class OpenFoodFactsAPI: OpenFoodFactsAPIProtocol, Sendable {
    private let networkService: NetworkServiceProtocol
    private let rateLimiter: RateLimiter
    private let preferredLanguage: String

    /// Default rate limit: 100 requests per minute
    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        requestsPerMinute: Int = 100,
        preferredLanguage: String? = nil
    ) {
        self.networkService = networkService
        self.rateLimiter = RateLimiter(requestsPerMinute: requestsPerMinute)
        self.preferredLanguage = preferredLanguage ?? Locale.current.language.languageCode?.identifier ?? "en"
    }

    // MARK: - Product Lookup

    func fetchProduct(barcode: String) async throws -> Product {
        // Validate barcode format
        guard BarcodeValidator.isValid(barcode) else {
            throw NetworkError.invalidBarcode
        }

        // Wait for rate limit
        try await rateLimiter.waitForPermission()

        // Fetch from API
        let endpoint = OpenFoodFactsEndpoint.product(
            barcode: barcode,
            fields: OpenFoodFactsEndpoint.detailedFields,
            language: preferredLanguage
        ).endpoint

        let response: OFFProductResponse = try await networkService.fetch(endpoint)

        guard response.isFound, let productDTO = response.product else {
            throw NetworkError.productNotFound
        }

        return Product(from: productDTO, preferredLanguage: preferredLanguage)
    }

    // MARK: - Product Search

    func searchProducts(query: String, page: Int = 1) async throws -> [Product] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        // Wait for rate limit
        try await rateLimiter.waitForPermission()

        let endpoint = OpenFoodFactsEndpoint.search(
            query: trimmedQuery,
            page: page,
            pageSize: 24,
            language: preferredLanguage
        ).endpoint

        let response: OFFSearchResponse = try await networkService.fetch(endpoint)

        return response.products.map { Product(from: $0, preferredLanguage: preferredLanguage) }
    }
}

// MARK: - Barcode Validator

enum BarcodeValidator {
    /// Validate barcode format (EAN-13, EAN-8, UPC-A, UPC-E)
    static func isValid(_ barcode: String) -> Bool {
        let cleaned = barcode.filter { $0.isNumber }

        switch cleaned.count {
        case 8:
            return isValidEAN8(cleaned)
        case 12:
            return isValidUPCA(cleaned)
        case 13:
            return isValidEAN13(cleaned)
        default:
            return false
        }
    }

    /// Validate EAN-13 checksum
    static func isValidEAN13(_ barcode: String) -> Bool {
        guard barcode.count == 13 else { return false }

        let digits = barcode.compactMap { $0.wholeNumberValue }
        guard digits.count == 13 else { return false }

        var sum = 0
        for (index, digit) in digits.enumerated() {
            sum += digit * (index % 2 == 0 ? 1 : 3)
        }

        return sum % 10 == 0
    }

    /// Validate EAN-8 checksum
    static func isValidEAN8(_ barcode: String) -> Bool {
        guard barcode.count == 8 else { return false }

        let digits = barcode.compactMap { $0.wholeNumberValue }
        guard digits.count == 8 else { return false }

        var sum = 0
        for (index, digit) in digits.enumerated() {
            sum += digit * (index % 2 == 0 ? 3 : 1)
        }

        return sum % 10 == 0
    }

    /// Validate UPC-A checksum (12 digits)
    static func isValidUPCA(_ barcode: String) -> Bool {
        // UPC-A can be validated as EAN-13 with leading zero
        return isValidEAN13("0" + barcode)
    }

    /// Normalize barcode to EAN-13 format
    static func normalizeToEAN13(_ barcode: String) -> String {
        let cleaned = barcode.filter { $0.isNumber }

        switch cleaned.count {
        case 8:
            // EAN-8 to EAN-13: pad with zeros
            return "00000" + cleaned
        case 12:
            // UPC-A to EAN-13: add leading zero
            return "0" + cleaned
        case 13:
            return cleaned
        default:
            return cleaned
        }
    }

    /// Expand UPC-E (8 digits) to UPC-A (12 digits)
    static func expandUPCE(_ upce: String) -> String? {
        guard upce.count == 8 else { return nil }

        let chars = Array(upce)
        guard let lastDigit = chars[6].wholeNumberValue else { return nil }

        let numberSystem = String(chars[0])
        let manufacturer: String
        let product: String

        switch lastDigit {
        case 0, 1, 2:
            manufacturer = String(chars[1...2]) + String(chars[6]) + "00"
            product = "00" + String(chars[3...5])
        case 3:
            manufacturer = String(chars[1...3]) + "00"
            product = "000" + String(chars[4...5])
        case 4:
            manufacturer = String(chars[1...4]) + "0"
            product = "0000" + String(chars[5])
        default:
            manufacturer = String(chars[1...5])
            product = "0000" + String(chars[6])
        }

        let checkDigit = String(chars[7])
        return numberSystem + manufacturer + product + checkDigit
    }
}

// MARK: - API Extensions for Contribution

extension OpenFoodFactsAPI {
    /// Check if a product exists in the database
    func productExists(barcode: String) async throws -> Bool {
        do {
            let endpoint = OpenFoodFactsEndpoint.product(
                barcode: barcode,
                fields: ["code"],
                language: nil
            ).endpoint

            let response: OFFProductResponse = try await networkService.fetch(endpoint)
            return response.isFound
        } catch NetworkError.productNotFound {
            return false
        }
    }
}
