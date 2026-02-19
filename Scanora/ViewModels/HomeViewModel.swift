import SwiftUI
import SwiftData

// MARK: - Home Stats

struct HomeStats {
    let totalScans: Int
    let favoritesCount: Int
    let todayCount: Int

    static let empty = HomeStats(totalScans: 0, favoritesCount: 0, todayCount: 0)
}

// MARK: - Home View Model

@MainActor
@Observable
final class HomeViewModel {
    private var modelContext: ModelContext?

    var recentScans: [ScanHistory] = []
    var favorites: [ScanHistory] = []
    var stats = HomeStats.empty
    var isLoading = false

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Load Data

    func loadData() async {
        guard let modelContext else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch recent scans (limit 5)
            var recentDescriptor = FetchDescriptor<ScanHistory>(
                sortBy: [SortDescriptor(\.scannedAt, order: .reverse)]
            )
            recentDescriptor.fetchLimit = 5
            recentScans = try modelContext.fetch(recentDescriptor)

            // Fetch favorites (limit 3)
            var favoritesDescriptor = FetchDescriptor<ScanHistory>(
                predicate: #Predicate { $0.isFavorite == true },
                sortBy: [SortDescriptor(\.scannedAt, order: .reverse)]
            )
            favoritesDescriptor.fetchLimit = 3
            favorites = try modelContext.fetch(favoritesDescriptor)

            // Calculate stats
            let allScansDescriptor = FetchDescriptor<ScanHistory>()
            let allScans = try modelContext.fetch(allScansDescriptor)

            let today = Calendar.current.startOfDay(for: Date())
            let todayScans = allScans.filter {
                Calendar.current.isDate($0.scannedAt, inSameDayAs: today)
            }

            let favCount = allScans.filter { $0.isFavorite }.count

            stats = HomeStats(
                totalScans: allScans.count,
                favoritesCount: favCount,
                todayCount: todayScans.count
            )

        } catch {
            print("Failed to load home data: \(error)")
        }
    }

    // MARK: - Refresh

    func refresh() async {
        await loadData()
    }
}
