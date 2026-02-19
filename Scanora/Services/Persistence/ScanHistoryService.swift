import Foundation
import SwiftData

// MARK: - Protocol

@MainActor
protocol ScanHistoryServiceProtocol {
    func addScan(product: Product) async throws
    func fetchRecentScans(limit: Int) async throws -> [ScanHistory]
    func fetchAllScans() async throws -> [ScanHistory]
    func fetchFavorites() async throws -> [ScanHistory]
    func toggleFavorite(scanId: UUID) async throws
    func deleteScan(scanId: UUID) async throws
    func deleteAllHistory() async throws
    func searchHistory(query: String) async throws -> [ScanHistory]
}

// MARK: - Scan History Service

@MainActor
final class ScanHistoryService: ScanHistoryServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Add Scan

    func addScan(product: Product) async throws {
        // Find or create cached product
        let barcodeToFind = product.barcode
        let cacheDescriptor = FetchDescriptor<CachedProduct>(
            predicate: #Predicate { $0.barcode == barcodeToFind }
        )
        let cachedProduct = try modelContext.fetch(cacheDescriptor).first

        // Create history entry
        let history = ScanHistory(from: product, cachedProduct: cachedProduct)
        modelContext.insert(history)

        try modelContext.save()
    }

    // MARK: - Fetch

    func fetchRecentScans(limit: Int = 50) async throws -> [ScanHistory] {
        var descriptor = FetchDescriptor<ScanHistory>(
            sortBy: [ScanHistory.recentFirstSort]
        )
        descriptor.fetchLimit = limit

        return try modelContext.fetch(descriptor)
    }

    func fetchAllScans() async throws -> [ScanHistory] {
        let descriptor = FetchDescriptor<ScanHistory>(
            sortBy: [ScanHistory.recentFirstSort]
        )

        return try modelContext.fetch(descriptor)
    }

    func fetchFavorites() async throws -> [ScanHistory] {
        let descriptor = FetchDescriptor<ScanHistory>(
            predicate: ScanHistory.favoritesPredicate,
            sortBy: [ScanHistory.recentFirstSort]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Fetch scans for a specific date
    func fetchScans(for date: Date) async throws -> [ScanHistory] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<ScanHistory>(
            predicate: #Predicate { $0.scannedAt >= startOfDay && $0.scannedAt < endOfDay },
            sortBy: [ScanHistory.recentFirstSort]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Fetch scans grouped by date
    func fetchScansGroupedByDate() async throws -> [Date: [ScanHistory]] {
        let allScans = try await fetchAllScans()
        let calendar = Calendar.current

        var grouped: [Date: [ScanHistory]] = [:]

        for scan in allScans {
            let dateKey = calendar.startOfDay(for: scan.scannedAt)
            if grouped[dateKey] == nil {
                grouped[dateKey] = []
            }
            grouped[dateKey]?.append(scan)
        }

        return grouped
    }

    // MARK: - Update

    func toggleFavorite(scanId: UUID) async throws {
        let idToFind = scanId
        let descriptor = FetchDescriptor<ScanHistory>(
            predicate: #Predicate { $0.id == idToFind }
        )

        guard let scan = try modelContext.fetch(descriptor).first else {
            return
        }

        scan.isFavorite.toggle()
        try modelContext.save()
    }

    func updateNotes(scanId: UUID, notes: String?) async throws {
        let idToFind = scanId
        let descriptor = FetchDescriptor<ScanHistory>(
            predicate: #Predicate { $0.id == idToFind }
        )

        guard let scan = try modelContext.fetch(descriptor).first else {
            return
        }

        scan.userNotes = notes
        try modelContext.save()
    }

    // MARK: - Delete

    func deleteScan(scanId: UUID) async throws {
        let idToFind = scanId
        let descriptor = FetchDescriptor<ScanHistory>(
            predicate: #Predicate { $0.id == idToFind }
        )

        guard let scan = try modelContext.fetch(descriptor).first else {
            return
        }

        modelContext.delete(scan)
        try modelContext.save()
    }

    func deleteAllHistory() async throws {
        let descriptor = FetchDescriptor<ScanHistory>()
        let allScans = try modelContext.fetch(descriptor)

        for scan in allScans {
            modelContext.delete(scan)
        }

        try modelContext.save()
    }

    /// Delete scans older than specified days
    func deleteOldScans(olderThan days: Int) async throws -> Int {
        let expirationDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

        let descriptor = FetchDescriptor<ScanHistory>(
            predicate: #Predicate { $0.scannedAt < expirationDate && $0.isFavorite == false }
        )

        let oldScans = try modelContext.fetch(descriptor)
        let count = oldScans.count

        for scan in oldScans {
            modelContext.delete(scan)
        }

        if count > 0 {
            try modelContext.save()
        }

        return count
    }

    // MARK: - Search

    func searchHistory(query: String) async throws -> [ScanHistory] {
        let lowercasedQuery = query.lowercased()

        let descriptor = FetchDescriptor<ScanHistory>(
            sortBy: [ScanHistory.recentFirstSort]
        )

        let allScans = try modelContext.fetch(descriptor)

        return allScans.filter { scan in
            scan.productName.lowercased().contains(lowercasedQuery) ||
            scan.brand?.lowercased().contains(lowercasedQuery) == true ||
            scan.barcode.contains(lowercasedQuery)
        }
    }

    // MARK: - Statistics

    func getHistoryStats() async throws -> HistoryStats {
        let allScans = try await fetchAllScans()
        let favorites = try await fetchFavorites()

        let uniqueBarcodes = Set(allScans.map { $0.barcode })

        // Count by nutriScore
        var nutriScoreCounts: [NutriScore: Int] = [:]
        for scan in allScans {
            if let score = scan.nutriScore {
                nutriScoreCounts[score, default: 0] += 1
            }
        }

        return HistoryStats(
            totalScans: allScans.count,
            uniqueProducts: uniqueBarcodes.count,
            favoritesCount: favorites.count,
            nutriScoreCounts: nutriScoreCounts
        )
    }
}

// MARK: - History Stats

struct HistoryStats {
    let totalScans: Int
    let uniqueProducts: Int
    let favoritesCount: Int
    let nutriScoreCounts: [NutriScore: Int]

    var mostCommonNutriScore: NutriScore? {
        nutriScoreCounts.max(by: { $0.value < $1.value })?.key
    }
}
