import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScanHistory.scannedAt, order: .reverse) private var scans: [ScanHistory]

    var showFavoritesOnly: Bool = false

    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Group {
            if filteredScans.isEmpty {
                if showFavoritesOnly {
                    ContentUnavailableView {
                        Label("No Favorites", systemImage: "star")
                    } description: {
                        Text("Swipe right on scans to add them to favorites")
                    }
                } else {
                    EmptyHistoryView()
                }
            } else {
                List {
                    ForEach(groupedScans.keys.sorted(by: >), id: \.self) { date in
                        Section {
                            ForEach(groupedScans[date] ?? []) { scan in
                                NavigationLink(destination: productDetailDestination(for: scan)) {
                                    HistoryRowView(scan: scan)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteScan(scan)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        toggleFavorite(scan)
                                    } label: {
                                        Label(
                                            scan.isFavorite ? "Unfavorite" : "Favorite",
                                            systemImage: scan.isFavorite ? "star.slash" : "star"
                                        )
                                    }
                                    .tint(.yellow)
                                }
                            }
                        } header: {
                            Text(formatSectionDate(date))
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search history")
            }
        }
        .navigationTitle(showFavoritesOnly ? "Favorites" : "History")
        .toolbar {
            if !filteredScans.isEmpty && !showFavoritesOnly {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Clear All History", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog(
            "Clear History",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                clearAllHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all your scan history. This action cannot be undone.")
        }
    }

    // MARK: - Product Detail Destination

    @ViewBuilder
    private func productDetailDestination(for scan: ScanHistory) -> some View {
        if let cachedProduct = scan.cachedProduct {
            ProductDetailView(product: cachedProduct.toDomain())
        } else {
            MinimalProductView(scan: scan)
        }
    }

    // MARK: - Filtered Scans

    private var filteredScans: [ScanHistory] {
        var filtered = scans

        // Filter favorites if needed
        if showFavoritesOnly {
            filtered = filtered.filter { $0.isFavorite }
        }

        // Apply search filter
        if !searchText.isEmpty {
            let lowercased = searchText.lowercased()
            filtered = filtered.filter {
                $0.productName.lowercased().contains(lowercased) ||
                $0.brand?.lowercased().contains(lowercased) == true ||
                $0.barcode.contains(lowercased)
            }
        }

        return filtered
    }

    // MARK: - Grouped Scans

    private var groupedScans: [Date: [ScanHistory]] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredScans) { scan in
            calendar.startOfDay(for: scan.scannedAt)
        }
    }

    // MARK: - Actions

    private func deleteScan(_ scan: ScanHistory) {
        modelContext.delete(scan)
        try? modelContext.save()
    }

    private func toggleFavorite(_ scan: ScanHistory) {
        scan.isFavorite.toggle()
        try? modelContext.save()
    }

    private func clearAllHistory() {
        for scan in scans {
            modelContext.delete(scan)
        }
        try? modelContext.save()
    }

    // MARK: - Helpers

    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return String(localized: "Today")
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "Yesterday")
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - History Row View

struct HistoryRowView: View {
    let scan: ScanHistory

    var body: some View {
        HStack(spacing: 12) {
            // Product thumbnail
            AsyncImage(url: scan.imageThumbnailURL) { phase in
                switch phase {
                case .empty, .failure:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 50, height: 50)

            // Product info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(scan.productName)
                        .font(.subheadline)
                        .lineLimit(1)

                    if scan.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }

                if let brand = scan.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    if let nutriScore = scan.nutriScore {
                        NutriScoreBadgeCompact(score: nutriScore)
                    }

                    Text(formatTime(scan.scannedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Empty History View

struct EmptyHistoryView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Scans Yet", systemImage: "clock.arrow.circlepath")
        } description: {
            Text("Products you scan will appear here")
        }
    }
}

// MARK: - Preview

#Preview {
    HistoryListView()
        .modelContainer(for: [CachedProduct.self, ScanHistory.self], inMemory: true)
}
