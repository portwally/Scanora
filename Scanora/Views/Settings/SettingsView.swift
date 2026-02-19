import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("preferredLanguage") private var preferredLanguage = "auto"
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("autoTorch") private var autoTorch = false

    @State private var cacheStats: CacheStats?
    @State private var showingClearCacheConfirmation = false
    @State private var showingClearHistoryConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Language Section
                Section {
                    Picker("Language", selection: $preferredLanguage) {
                        Text("System Default").tag("auto")
                        Divider()
                        Text("English").tag("en")
                        Text("Portugues").tag("pt")
                        Text("Espanol").tag("es")
                        Text("Francais").tag("fr")
                        Text("Deutsch").tag("de")
                        Text("Italiano").tag("it")
                    }
                } header: {
                    Text("Language")
                } footer: {
                    Text("This affects product information display. Restart may be required.")
                }

                // Scanner Section
                Section {
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                    Toggle("Auto Torch in Low Light", isOn: $autoTorch)
                } header: {
                    Text("Scanner")
                }

                // Cache Section
                Section {
                    HStack {
                        Text("Cached Products")
                        Spacer()
                        Text("\(cacheStats?.totalCount ?? 0)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Cache Size")
                        Spacer()
                        Text(cacheStats?.formattedTotalSize ?? "-")
                            .foregroundColor(.secondary)
                    }

                    Button(role: .destructive) {
                        showingClearCacheConfirmation = true
                    } label: {
                        Text("Clear Cache")
                    }
                } header: {
                    Text("Cache")
                } footer: {
                    Text("Clearing cache will remove offline product data. Products will be re-downloaded when scanned.")
                }

                // Data Section
                Section {
                    Button(role: .destructive) {
                        showingClearHistoryConfirmation = true
                    } label: {
                        Text("Clear Scan History")
                    }
                } header: {
                    Text("Data")
                }

                // About Section
                Section {
                    Link(destination: URL(string: "https://world.openfoodfacts.org")!) {
                        HStack {
                            Text("Open Food Facts")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Scanora uses Open Food Facts, a free and open database of food products from around the world.")
                }
            }
            .navigationTitle("Settings")
            .task {
                await loadCacheStats()
            }
            .confirmationDialog(
                "Clear Cache",
                isPresented: $showingClearCacheConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear Cache", role: .destructive) {
                    Task { await clearCache() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all cached product data. Products will need to be re-downloaded when scanned.")
            }
            .confirmationDialog(
                "Clear History",
                isPresented: $showingClearHistoryConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear History", role: .destructive) {
                    Task { await clearHistory() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all your scan history. This action cannot be undone.")
            }
        }
    }

    // MARK: - Actions

    private func loadCacheStats() async {
        let cacheService = ProductCacheService(modelContext: modelContext)
        cacheStats = try? await cacheService.getCacheStats()
    }

    private func clearCache() async {
        let cacheService = ProductCacheService(modelContext: modelContext)
        try? await cacheService.clearAllCache()
        await loadCacheStats()
    }

    private func clearHistory() async {
        let historyService = ScanHistoryService(modelContext: modelContext)
        try? await historyService.deleteAllHistory()
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: [CachedProduct.self, ScanHistory.self], inMemory: true)
}
