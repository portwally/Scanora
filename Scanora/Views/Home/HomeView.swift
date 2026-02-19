import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var showScanner = false
    @State private var scannedProduct: Product?
    @State private var showProductDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Scan Button
                    scanButton

                    // Quick Stats
                    statsSection

                    // Recent Scans
                    if !viewModel.recentScans.isEmpty {
                        recentScansSection
                    }

                    // Favorites
                    if !viewModel.favorites.isEmpty {
                        favoritesSection
                    }

                    // Search Button
                    searchButton

                    // Shopping List Button
                    shoppingListButton
                }
                .padding()
            }
            .navigationTitle("Scanora")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .task {
                viewModel.setModelContext(modelContext)
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .fullScreenCover(isPresented: $showScanner) {
                ScannerContainerView(
                    onProductScanned: { product in
                        scannedProduct = product
                        showScanner = false
                        showProductDetail = true
                    },
                    onDismiss: {
                        showScanner = false
                    }
                )
            }
            .navigationDestination(isPresented: $showProductDetail) {
                if let product = scannedProduct {
                    ProductDetailView(product: product)
                }
            }
            .onChange(of: showProductDetail) { _, isShowing in
                if !isShowing {
                    // Refresh data when returning from product detail
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
        }
    }

    // MARK: - Scan Button

    private var scanButton: some View {
        Button(action: { showScanner = true }) {
            VStack(spacing: 12) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 48))
                Text("Scan Barcode")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                value: "\(viewModel.stats.totalScans)",
                label: String(localized: "Scans"),
                icon: "barcode"
            )
            StatCard(
                value: "\(viewModel.stats.favoritesCount)",
                label: String(localized: "Favorites"),
                icon: "star.fill"
            )
            StatCard(
                value: "\(viewModel.stats.todayCount)",
                label: String(localized: "Today"),
                icon: "calendar"
            )
        }
    }

    // MARK: - Recent Scans Section

    private var recentScansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Scans")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: HistoryListView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }

            List {
                ForEach(viewModel.recentScans) { scan in
                    NavigationLink(destination: productDetailDestination(for: scan)) {
                        ScanRowView(scan: scan)
                    }
                    .listRowBackground(Color(.systemGray6))
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteScan(viewModel.recentScans[index])
                    }
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .frame(height: CGFloat(viewModel.recentScans.count) * 60)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Favorites Section

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Favorites")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: HistoryListView(showFavoritesOnly: true)) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }

            List {
                ForEach(viewModel.favorites) { scan in
                    NavigationLink(destination: productDetailDestination(for: scan)) {
                        ScanRowView(scan: scan, showFavoriteIcon: false)
                    }
                    .listRowBackground(Color(.systemGray6))
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteScan(viewModel.favorites[index])
                    }
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .frame(height: CGFloat(viewModel.favorites.count) * 60)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Search Button

    private var searchButton: some View {
        NavigationLink(destination: SearchView()) {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("Search Products")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Shopping List Button

    private var shoppingListButton: some View {
        NavigationLink(destination: ShoppingListView()) {
            HStack {
                Image(systemName: "cart")
                Text(String(localized: "Shopping List"))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper

    @ViewBuilder
    private func productDetailDestination(for scan: ScanHistory) -> some View {
        if let cachedProduct = scan.cachedProduct {
            ProductDetailView(product: cachedProduct.toDomain())
        } else {
            MinimalProductView(scan: scan)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Scan Row View

struct ScanRowView: View {
    let scan: ScanHistory
    var showFavoriteIcon: Bool = true

    var body: some View {
        HStack {
            // Product image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray4))
                .frame(width: 44, height: 44)
                .overlay {
                    if let url = scan.imageThumbnailURL {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "cube.box")
                            .foregroundColor(.secondary)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(scan.productName)
                    .font(.subheadline)
                    .lineLimit(1)
                if let brand = scan.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if showFavoriteIcon && scan.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }

            Text(scan.scannedAt.formatted(.relative(presentation: .named)))
                .font(.caption)
                .foregroundColor(.secondary)

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Scanner Container View

struct ScannerContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ScannerViewModel()

    let onProductScanned: (Product) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(
                scannerService: viewModel.scannerService,
                onTap: { point in
                    viewModel.scannerService.focusAt(point: point, in: .zero)
                }
            )
            .ignoresSafeArea()

            // Scanning overlay
            ScannerOverlayView(isScanning: viewModel.isScanning)

            // Controls and status
            VStack {
                // Close button
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding()
                    Spacer()
                }

                Spacer()

                // Status message or loading indicator
                if viewModel.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                        Text(viewModel.statusMessage ?? "Loading...")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                } else if let message = viewModel.statusMessage {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }

                // Bottom controls
                HStack(spacing: 24) {
                    // Torch button
                    if viewModel.scannerService.hasTorch {
                        Button(action: { viewModel.toggleTorch() }) {
                            Image(systemName: viewModel.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }

                    Spacer()

                    // Manual entry button
                    Button(action: { viewModel.showManualEntry = true }) {
                        Image(systemName: "keyboard")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .task {
            viewModel.setModelContext(modelContext)
            await viewModel.setup()
        }
        .onChange(of: viewModel.scannedProduct) { _, product in
            if let product {
                onProductScanned(product)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            if viewModel.showContribute {
                Button("Add Product") {
                    viewModel.showError = false
                    // For now, just dismiss - contribute flow can be added later
                    onDismiss()
                }
                Button("Try Again", role: .cancel) {
                    viewModel.resumeScanning()
                }
            } else {
                Button("OK", role: .cancel) {
                    viewModel.dismissError()
                }
                if viewModel.errorSuggestion?.contains("Settings") == true {
                    Button("Open Settings") {
                        viewModel.openSettings()
                    }
                }
            }
        } message: {
            VStack {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
                if let suggestion = viewModel.errorSuggestion {
                    Text(suggestion)
                }
            }
        }
        .sheet(isPresented: $viewModel.showManualEntry) {
            ManualBarcodeEntryView { barcode in
                viewModel.submitManualBarcode(barcode)
            }
        }
    }
}

// MARK: - Minimal Product View (for scans without cached data)

struct MinimalProductView: View {
    @Environment(\.dismiss) private var dismiss
    let scan: ScanHistory

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Product image
                if let url = scan.imageThumbnailURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                }

                VStack(spacing: 8) {
                    Text(scan.productName)
                        .font(.title2.bold())

                    if let brand = scan.brand {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(scan.barcode)
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }

                // Nutri-Score if available
                if let nutriScore = scan.nutriScore {
                    NutriScoreBadge(score: nutriScore)
                }

                Spacer()

                Text("Full product details are no longer cached")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Product")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [CachedProduct.self, ScanHistory.self], inMemory: true)
}
