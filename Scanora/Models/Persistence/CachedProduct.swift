import Foundation
import SwiftData

/// SwiftData model for caching product data for offline access
@Model
final class CachedProduct {
    // MARK: - Identification
    @Attribute(.unique) var barcode: String

    // MARK: - Basic Info
    var name: String
    var genericName: String?
    var brand: String?
    var quantity: String?

    // MARK: - Origin & Manufacturing
    var manufacturer: String?
    var origin: String?
    var countries: [String]
    var stores: String?

    // MARK: - Categories
    var categories: [String]

    // MARK: - Ingredients (stored as JSON)
    var ingredientsText: String?
    var ingredientsData: Data?

    // MARK: - Allergens & Additives (stored as raw values)
    var allergensRaw: [String]
    var tracesRaw: [String]
    var additives: [String]

    // MARK: - Health Scores (stored as raw values)
    var nutriScoreRaw: String?
    var novaGroupRaw: Int?
    var ecoScoreRaw: String?
    var nutrimentsData: Data?

    // MARK: - Images
    var imageURLString: String?
    var imageThumbnailURLString: String?
    var ingredientsImageURLString: String?
    var nutritionImageURLString: String?

    // MARK: - Metadata
    var completeness: Double
    var productLastModified: Date?
    var cachedAt: Date
    var lastAccessedAt: Date

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \ScanHistory.cachedProduct)
    var scanHistory: [ScanHistory]?

    // MARK: - Initialization

    init(from product: Product) {
        self.barcode = product.barcode
        self.name = product.name
        self.genericName = product.genericName
        self.brand = product.brand
        self.quantity = product.quantity
        self.manufacturer = product.manufacturer
        self.origin = product.origin
        self.countries = product.countries
        self.stores = product.stores
        self.categories = product.categories
        self.ingredientsText = product.ingredientsText
        self.ingredientsData = try? JSONEncoder().encode(product.ingredients)
        self.allergensRaw = product.allergens.map { $0.rawValue }
        self.tracesRaw = product.traces.map { $0.rawValue }
        self.additives = product.additives
        self.nutriScoreRaw = product.nutriScore?.rawValue
        self.novaGroupRaw = product.novaGroup?.rawValue
        self.ecoScoreRaw = product.ecoScore?.rawValue
        self.nutrimentsData = try? JSONEncoder().encode(product.nutriments)
        self.imageURLString = product.imageURL?.absoluteString
        self.imageThumbnailURLString = product.imageThumbnailURL?.absoluteString
        self.ingredientsImageURLString = product.ingredientsImageURL?.absoluteString
        self.nutritionImageURLString = product.nutritionImageURL?.absoluteString
        self.completeness = product.completeness
        self.productLastModified = product.lastModified
        self.cachedAt = Date()
        self.lastAccessedAt = Date()
    }

    // MARK: - Convert to Domain Model

    func toDomain() -> Product {
        let ingredients: [Ingredient] = {
            guard let data = ingredientsData else { return [] }
            return (try? JSONDecoder().decode([Ingredient].self, from: data)) ?? []
        }()

        let nutriments: Nutriments? = {
            guard let data = nutrimentsData else { return nil }
            return try? JSONDecoder().decode(Nutriments.self, from: data)
        }()

        return Product(
            barcode: barcode,
            name: name,
            genericName: genericName,
            brand: brand,
            quantity: quantity,
            manufacturer: manufacturer,
            origin: origin,
            countries: countries,
            stores: stores,
            categories: categories,
            ingredientsText: ingredientsText,
            ingredients: ingredients,
            allergens: Set(allergensRaw.compactMap { Allergen(rawValue: $0) }),
            traces: Set(tracesRaw.compactMap { Allergen(rawValue: $0) }),
            additives: additives,
            nutriScore: nutriScoreRaw.flatMap { NutriScore(rawValue: $0) },
            novaGroup: novaGroupRaw.flatMap { NovaGroup(rawValue: $0) },
            ecoScore: ecoScoreRaw.flatMap { EcoScore(rawValue: $0) },
            nutriments: nutriments,
            imageURL: imageURLString.flatMap { URL(string: $0) },
            imageThumbnailURL: imageThumbnailURLString.flatMap { URL(string: $0) },
            ingredientsImageURL: ingredientsImageURLString.flatMap { URL(string: $0) },
            nutritionImageURL: nutritionImageURLString.flatMap { URL(string: $0) },
            completeness: completeness,
            lastModified: productLastModified
        )
    }

    // MARK: - Update from Product

    func update(from product: Product) {
        self.name = product.name
        self.genericName = product.genericName
        self.brand = product.brand
        self.quantity = product.quantity
        self.manufacturer = product.manufacturer
        self.origin = product.origin
        self.countries = product.countries
        self.stores = product.stores
        self.categories = product.categories
        self.ingredientsText = product.ingredientsText
        self.ingredientsData = try? JSONEncoder().encode(product.ingredients)
        self.allergensRaw = product.allergens.map { $0.rawValue }
        self.tracesRaw = product.traces.map { $0.rawValue }
        self.additives = product.additives
        self.nutriScoreRaw = product.nutriScore?.rawValue
        self.novaGroupRaw = product.novaGroup?.rawValue
        self.ecoScoreRaw = product.ecoScore?.rawValue
        self.nutrimentsData = try? JSONEncoder().encode(product.nutriments)
        self.imageURLString = product.imageURL?.absoluteString
        self.imageThumbnailURLString = product.imageThumbnailURL?.absoluteString
        self.ingredientsImageURLString = product.ingredientsImageURL?.absoluteString
        self.nutritionImageURLString = product.nutritionImageURL?.absoluteString
        self.completeness = product.completeness
        self.productLastModified = product.lastModified
        self.cachedAt = Date()
    }

    // MARK: - Cache Validity

    /// Check if the cached data is still valid (default TTL: 7 days)
    func isValid(ttl: TimeInterval = 7 * 24 * 60 * 60) -> Bool {
        Date().timeIntervalSince(cachedAt) < ttl
    }
}
