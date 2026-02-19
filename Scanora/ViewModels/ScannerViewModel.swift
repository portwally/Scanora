import SwiftUI
import AVFoundation
import SwiftData

@MainActor
@Observable
final class ScannerViewModel {
    // MARK: - State
    var isScanning = false
    var isTorchOn = false
    var isLoading = false
    var scannedProduct: Product?
    var statusMessage: String?
    var showError = false
    var errorMessage: String?
    var errorSuggestion: String?
    var showManualEntry = false
    var showProductDetail = false
    var showContribute = false
    var lastScannedBarcode: String?

    // MARK: - Services
    let scannerService = BarcodeScannerService()
    private var api: OpenFoodFactsAPIProtocol
    private var cacheService: ProductCacheService?
    private var historyService: ScanHistoryService?

    // MARK: - State Management
    private var scanCooldown = false
    private var currentLookupTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        api: OpenFoodFactsAPIProtocol = OpenFoodFactsAPI()
    ) {
        self.api = api
        scannerService.delegate = self
    }

    func setModelContext(_ context: ModelContext) {
        self.cacheService = ProductCacheService(modelContext: context)
        self.historyService = ScanHistoryService(modelContext: context)
    }

    // MARK: - Setup

    func setup() async {
        let hasPermission = await scannerService.checkCameraPermission()

        guard hasPermission else {
            errorMessage = String(localized: "Scanora needs camera access to scan barcodes.")
            errorSuggestion = String(localized: "Go to Settings > Scanora > Camera to enable access.")
            showError = true
            return
        }

        do {
            try scannerService.configure()
            scannerService.startScanning()
            isScanning = true
        } catch let error as ScannerError {
            errorMessage = error.localizedDescription
            errorSuggestion = error.recoverySuggestion
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Scanner Control

    func startScanning() {
        scannerService.startScanning()
        isScanning = true
    }

    func stopScanning() {
        scannerService.stopScanning()
        isScanning = false
    }

    func resumeScanning() {
        scannedProduct = nil
        lastScannedBarcode = nil
        statusMessage = nil
        showProductDetail = false
        scannerService.startScanning()
        isScanning = true
    }

    func toggleTorch() {
        isTorchOn.toggle()
        scannerService.setTorch(on: isTorchOn)
    }

    // MARK: - Barcode Lookup

    func lookupBarcode(_ barcode: String) async {
        // Cancel any existing lookup
        currentLookupTask?.cancel()

        // Prevent duplicate lookups
        guard !scanCooldown else { return }
        guard barcode != lastScannedBarcode || scannedProduct == nil else { return }

        lastScannedBarcode = barcode
        scanCooldown = true
        isLoading = true
        statusMessage = String(localized: "Looking up product...")
        showError = false

        currentLookupTask = Task {
            defer {
                isLoading = false
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second cooldown
                    scanCooldown = false
                }
            }

            do {
                // Check cache first
                if let cachedProduct = try await cacheService?.fetchProduct(barcode: barcode) {
                    self.scannedProduct = cachedProduct
                    self.statusMessage = nil
                    self.showProductDetail = true
                    try await historyService?.addScan(product: cachedProduct)
                    return
                }

                // Fetch from API
                let product = try await api.fetchProduct(barcode: barcode)

                guard !Task.isCancelled else { return }

                self.scannedProduct = product
                self.statusMessage = nil
                self.showProductDetail = true

                // Cache the product
                try await cacheService?.saveProduct(product)

                // Add to history
                try await historyService?.addScan(product: product)

            } catch NetworkError.productNotFound {
                self.statusMessage = nil
                self.errorMessage = String(localized: "Product not found")
                self.errorSuggestion = String(localized: "This product isn't in the Open Food Facts database yet. Would you like to add it?")
                self.showError = true
                self.showContribute = true
            } catch let error as NetworkError {
                self.statusMessage = nil
                self.errorMessage = error.localizedDescription
                self.errorSuggestion = error.recoverySuggestion
                self.showError = true
            } catch {
                guard !Task.isCancelled else { return }
                self.statusMessage = nil
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }

        await currentLookupTask?.value
    }

    // MARK: - Manual Entry

    func submitManualBarcode(_ barcode: String) {
        showManualEntry = false
        let cleaned = barcode.filter { $0.isNumber }
        guard !cleaned.isEmpty else { return }

        Task {
            await lookupBarcode(cleaned)
        }
    }

    // MARK: - Error Handling

    func dismissError() {
        showError = false
        errorMessage = nil
        errorSuggestion = nil
        showContribute = false
        resumeScanning()
    }

    func openContributeFlow() {
        showError = false
        // The contribute view will be shown
    }

    // MARK: - Settings

    func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
}

// MARK: - BarcodeScannerDelegate

extension ScannerViewModel: BarcodeScannerDelegate {
    nonisolated func didDetectBarcode(_ barcode: String, type: AVMetadataObject.ObjectType) {
        Task { @MainActor in
            // Stop scanning while processing
            scannerService.stopScanning()
            isScanning = false

            await lookupBarcode(barcode)
        }
    }

    nonisolated func didFailWithError(_ error: ScannerError) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
            errorSuggestion = error.recoverySuggestion
            showError = true
        }
    }
}
