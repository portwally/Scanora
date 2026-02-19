import Foundation
import SwiftData

// MARK: - Protocol

@MainActor
protocol ProductCacheServiceProtocol {
    func fetchProduct(barcode: String) async throws -> Product?
    func saveProduct(_ product: Product) async throws
    func deleteProduct(barcode: String) async throws
    func clearExpiredCache(olderThan days: Int) async throws -> Int
    func clearAllCache() async throws
}

// MARK: - Product Cache Service

@MainActor
final class ProductCacheService: ProductCacheServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch

    func fetchProduct(barcode: String) async throws -> Product? {
        let descriptor = FetchDescriptor<CachedProduct>(
            predicate: #Predicate { $0.barcode == barcode }
        )

        guard let cachedProduct = try modelContext.fetch(descriptor).first else {
            return nil
        }

        // Check if cache is still valid
        guard cachedProduct.isValid() else {
            // Cache expired, delete it
            modelContext.delete(cachedProduct)
            try modelContext.save()
            return nil
        }

        // Update last accessed timestamp
        cachedProduct.lastAccessedAt = Date()
        try modelContext.save()

        return cachedProduct.toDomain()
    }

    // MARK: - Save

    func saveProduct(_ product: Product) async throws {
        let descriptor = FetchDescriptor<CachedProduct>(
            predicate: #Predicate { $0.barcode == product.barcode }
        )

        if let existingProduct = try modelContext.fetch(descriptor).first {
            // Update existing cache
            existingProduct.update(from: product)
        } else {
            // Create new cache entry
            let cachedProduct = CachedProduct(from: product)
            modelContext.insert(cachedProduct)
        }

        try modelContext.save()
    }

    // MARK: - Delete

    func deleteProduct(barcode: String) async throws {
        let descriptor = FetchDescriptor<CachedProduct>(
            predicate: #Predicate { $0.barcode == barcode }
        )

        if let cachedProduct = try modelContext.fetch(descriptor).first {
            modelContext.delete(cachedProduct)
            try modelContext.save()
        }
    }

    // MARK: - Cache Management

    /// Clear cached products older than specified days
    /// Returns the number of deleted items
    func clearExpiredCache(olderThan days: Int = 7) async throws -> Int {
        let expirationDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

        let descriptor = FetchDescriptor<CachedProduct>(
            predicate: #Predicate { $0.cachedAt < expirationDate }
        )

        let expiredProducts = try modelContext.fetch(descriptor)
        let count = expiredProducts.count

        for product in expiredProducts {
            modelContext.delete(product)
        }

        if count > 0 {
            try modelContext.save()
        }

        return count
    }

    /// Clear all cached products
    func clearAllCache() async throws {
        let descriptor = FetchDescriptor<CachedProduct>()
        let allProducts = try modelContext.fetch(descriptor)

        for product in allProducts {
            modelContext.delete(product)
        }

        try modelContext.save()
    }

    /// Get cache statistics
    func getCacheStats() async throws -> CacheStats {
        let descriptor = FetchDescriptor<CachedProduct>()
        let allProducts = try modelContext.fetch(descriptor)

        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!

        let validCount = allProducts.filter { $0.isValid() }.count
        let expiredCount = allProducts.count - validCount
        let recentlyAccessedCount = allProducts.filter { $0.lastAccessedAt >= sevenDaysAgo }.count

        return CacheStats(
            totalCount: allProducts.count,
            validCount: validCount,
            expiredCount: expiredCount,
            recentlyAccessedCount: recentlyAccessedCount
        )
    }
}

// MARK: - Cache Stats

struct CacheStats {
    let totalCount: Int
    let validCount: Int
    let expiredCount: Int
    let recentlyAccessedCount: Int

    var formattedTotalSize: String {
        // Rough estimate: ~2KB per product
        let estimatedBytes = totalCount * 2048
        return ByteCountFormatter.string(fromByteCount: Int64(estimatedBytes), countStyle: .file)
    }
}
