import Foundation

// MARK: - HTTP Method

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - API Endpoint

struct APIEndpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]?
    let baseURL: URL
    let headers: [String: String]

    var url: URL? {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems?.isEmpty == false ? queryItems : nil
        return components?.url
    }

    init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        baseURL: URL,
        headers: [String: String] = [:]
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.baseURL = baseURL
        self.headers = headers
    }
}

// MARK: - Open Food Facts Endpoints

enum OpenFoodFactsEndpoint {
    /// World (default) API base URL
    static let worldBaseURL = URL(string: "https://world.openfoodfacts.org")!

    /// Get localized base URL for a specific language
    static func localizedBaseURL(language: String) -> URL {
        URL(string: "https://\(language).openfoodfacts.org")!
    }

    /// Default headers required by Open Food Facts API
    static var defaultHeaders: [String: String] {
        [
            "User-Agent": "Scanora/1.0 iOS (https://github.com/scanora-app; contact@scanora.app)",
            "Accept": "application/json"
        ]
    }

    // MARK: - Endpoints

    /// Fetch a product by barcode
    case product(barcode: String, fields: [String]? = nil, language: String? = nil)

    /// Search products by query
    case search(query: String, page: Int = 1, pageSize: Int = 24, language: String? = nil)

    /// Contribute a new product
    case contribute(barcode: String)

    /// Upload product image
    case uploadImage(barcode: String, imageField: String)

    var endpoint: APIEndpoint {
        switch self {
        case .product(let barcode, let fields, let language):
            let baseURL = language.map { Self.localizedBaseURL(language: $0) } ?? Self.worldBaseURL

            var queryItems: [URLQueryItem] = []
            if let fields = fields, !fields.isEmpty {
                queryItems.append(URLQueryItem(name: "fields", value: fields.joined(separator: ",")))
            }

            return APIEndpoint(
                path: "/api/v2/product/\(barcode).json",
                method: .get,
                queryItems: queryItems.isEmpty ? nil : queryItems,
                baseURL: baseURL,
                headers: Self.defaultHeaders
            )

        case .search(let query, let page, let pageSize, let language):
            let baseURL = language.map { Self.localizedBaseURL(language: $0) } ?? Self.worldBaseURL

            let queryItems = [
                URLQueryItem(name: "search_terms", value: query),
                URLQueryItem(name: "json", value: "1"),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "page_size", value: String(pageSize)),
                URLQueryItem(name: "sort_by", value: "popularity")
            ]

            return APIEndpoint(
                path: "/cgi/search.pl",
                method: .get,
                queryItems: queryItems,
                baseURL: baseURL,
                headers: Self.defaultHeaders
            )

        case .contribute(let barcode):
            return APIEndpoint(
                path: "/cgi/product_jqm2.pl",
                method: .post,
                queryItems: [URLQueryItem(name: "code", value: barcode)],
                baseURL: Self.worldBaseURL,
                headers: Self.defaultHeaders
            )

        case .uploadImage(let barcode, let imageField):
            return APIEndpoint(
                path: "/cgi/product_image_upload.pl",
                method: .post,
                queryItems: [
                    URLQueryItem(name: "code", value: barcode),
                    URLQueryItem(name: "imagefield", value: imageField)
                ],
                baseURL: Self.worldBaseURL,
                headers: Self.defaultHeaders
            )
        }
    }
}

// MARK: - Common Fields

extension OpenFoodFactsEndpoint {
    /// Essential fields for product display
    static let essentialFields = [
        "code",
        "product_name", "product_name_pt", "product_name_en",
        "generic_name", "generic_name_pt", "generic_name_en",
        "brands", "quantity",
        "image_front_url", "image_front_small_url",
        "nutriscore_grade", "nova_group",
        "allergens_tags", "traces_tags"
    ]

    /// Full fields for detailed product view
    static let detailedFields = essentialFields + [
        "ingredients_text", "ingredients_text_pt", "ingredients_text_en",
        "ingredients",
        "additives_tags",
        "nutriments",
        "origins", "countries_tags",
        "categories_tags",
        "image_ingredients_url", "image_nutrition_url",
        "ecoscore_grade",
        "completeness",
        "last_modified_t"
    ]
}
