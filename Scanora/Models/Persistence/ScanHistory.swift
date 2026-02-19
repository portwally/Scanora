import Foundation
import SwiftData

/// SwiftData model for tracking product scan history
@Model
final class ScanHistory {
    // MARK: - Identification
    @Attribute(.unique) var id: UUID
    var barcode: String

    // MARK: - Quick Access Info (denormalized for fast display)
    var productName: String
    var brand: String?
    var imageThumbnailURLString: String?
    var nutriScoreRaw: String?
    var novaGroupRaw: Int?

    // MARK: - Timestamps
    var scannedAt: Date

    // MARK: - Relationship to cached product
    var cachedProduct: CachedProduct?

    // MARK: - User Notes (future feature)
    var userNotes: String?
    var isFavorite: Bool

    // MARK: - Initialization

    init(from product: Product, cachedProduct: CachedProduct? = nil) {
        self.id = UUID()
        self.barcode = product.barcode
        self.productName = product.name
        self.brand = product.brand
        self.imageThumbnailURLString = product.imageThumbnailURL?.absoluteString
        self.nutriScoreRaw = product.nutriScore?.rawValue
        self.novaGroupRaw = product.novaGroup?.rawValue
        self.scannedAt = Date()
        self.cachedProduct = cachedProduct
        self.isFavorite = false
    }

    // MARK: - Computed Properties

    var imageThumbnailURL: URL? {
        imageThumbnailURLString.flatMap { URL(string: $0) }
    }

    var nutriScore: NutriScore? {
        nutriScoreRaw.flatMap { NutriScore(rawValue: $0) }
    }

    var novaGroup: NovaGroup? {
        novaGroupRaw.flatMap { NovaGroup(rawValue: $0) }
    }

    /// Convert to Product if cached data is available
    func toProduct() -> Product? {
        cachedProduct?.toDomain()
    }
}

// MARK: - ScanHistory Queries

extension ScanHistory {
    /// Predicate for recent scans (last 30 days)
    static var recentPredicate: Predicate<ScanHistory> {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return #Predicate<ScanHistory> { $0.scannedAt >= thirtyDaysAgo }
    }

    /// Predicate for favorites
    static var favoritesPredicate: Predicate<ScanHistory> {
        #Predicate<ScanHistory> { $0.isFavorite == true }
    }

    /// Sort descriptor for most recent first
    static var recentFirstSort: SortDescriptor<ScanHistory> {
        SortDescriptor(\.scannedAt, order: .reverse)
    }
}
