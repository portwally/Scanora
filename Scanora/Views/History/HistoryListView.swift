import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScanHistory.scannedAt, order: .reverse) private var scans: [ScanHistory]

    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false
    @State private var selectedScan: ScanHistory?

    var body: some View {
        NavigationStack {
            Group {
                if scans.isEmpty {
                    EmptyHistoryView()
                } else {
                    List {
                        ForEach(groupedScans.keys.sorted(by: >), id: \.self) { date in
                            Section {
                                ForEach(groupedScans[date] ?? []) { scan in
                                    HistoryRowView(scan: scan)
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
                                        .onTapGesture {
                                            selectedScan = scan
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
            .navigationTitle("History")
            .toolbar {
                if !scans.isEmpty {
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
            .sheet(item: $selectedScan) { scan in
                if let product = scan.toProduct() {
                    ProductDetailView(product: product) {
                        selectedScan = nil
                    }
                } else {
                    // Minimal product view if cached data is unavailable
                    MinimalProductView(scan: scan) {
                        selectedScan = nil
                    }
                }
            }
        }
    }

    // MARK: - Grouped Scans

    private var groupedScans: [Date: [ScanHistory]] {
        let calendar = Calendar.current

        var filtered = scans
        if !searchText.isEmpty {
            let lowercased = searchText.lowercased()
            filtered = scans.filter {
                $0.productName.lowercased().contains(lowercased) ||
                $0.brand?.lowercased().contains(lowercased) == true ||
                $0.barcode.contains(lowercased)
            }
        }

        return Dictionary(grouping: filtered) { scan in
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

// MARK: - Minimal Product View

struct MinimalProductView: View {
    let scan: ScanHistory
    var onDismiss: (() -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                AsyncImage(url: scan.imageThumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(height: 200)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                            }
                    }
                }

                Text(scan.productName)
                    .font(.title2.bold())

                if let brand = scan.brand {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let nutriScore = scan.nutriScore {
                    NutriScoreBadge(score: nutriScore)
                }

                HStack {
                    Image(systemName: "barcode")
                    Text(scan.barcode)
                        .font(.caption.monospacedDigit())
                }
                .foregroundColor(.secondary)

                Spacer()

                Text("Full product details are no longer cached")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss?()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HistoryListView()
        .modelContainer(for: [CachedProduct.self, ScanHistory.self], inMemory: true)
}
