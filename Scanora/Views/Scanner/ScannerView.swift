import SwiftUI
import SwiftData

struct ScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ScannerViewModel()
    @State private var showContributeView = false

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
                        .accessibilityLabel(viewModel.isTorchOn ? "Turn off flashlight" : "Turn on flashlight")
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
                    .accessibilityLabel("Enter barcode manually")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .task {
            viewModel.setModelContext(modelContext)
            await viewModel.setup()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            if viewModel.showContribute {
                Button("Add Product") {
                    viewModel.showError = false
                    showContributeView = true
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
        .sheet(isPresented: $showContributeView) {
            if let barcode = viewModel.lastScannedBarcode {
                ContributeProductView(barcode: barcode) {
                    viewModel.resumeScanning()
                }
            }
        }
        .sheet(isPresented: $viewModel.showProductDetail) {
            if let product = viewModel.scannedProduct {
                ProductDetailView(product: product) {
                    viewModel.resumeScanning()
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

// MARK: - Manual Barcode Entry

struct ManualBarcodeEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var barcode = ""
    @FocusState private var isFocused: Bool

    let onSubmit: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Enter the barcode number manually")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("Barcode", text: $barcode)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2.monospacedDigit())
                    .multilineTextAlignment(.center)
                    .focused($isFocused)

                Text("Usually 8 or 13 digits")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button(action: submit) {
                    Text("Look Up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidBarcode)

                Spacer()
            }
            .padding()
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.medium])
    }

    private var isValidBarcode: Bool {
        let cleaned = barcode.filter { $0.isNumber }
        return cleaned.count == 8 || cleaned.count == 12 || cleaned.count == 13
    }

    private func submit() {
        guard isValidBarcode else { return }
        dismiss()
        onSubmit(barcode)
    }
}

// MARK: - Preview

#Preview {
    ScannerView()
        .modelContainer(for: [CachedProduct.self, ScanHistory.self], inMemory: true)
}
