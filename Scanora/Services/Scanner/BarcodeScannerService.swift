import AVFoundation
import UIKit

// MARK: - Scanner Delegate

protocol BarcodeScannerDelegate: AnyObject {
    func didDetectBarcode(_ barcode: String, type: AVMetadataObject.ObjectType)
    func didFailWithError(_ error: ScannerError)
}

// MARK: - Barcode Scanner Service

final class BarcodeScannerService: NSObject, @unchecked Sendable {
    weak var delegate: BarcodeScannerDelegate?

    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.scanora.scanner.session")
    private var isConfigured = false
    private var previewLayerInstance: AVCaptureVideoPreviewLayer?

    /// Supported barcode types for food products
    static let supportedBarcodeTypes: [AVMetadataObject.ObjectType] = [
        .ean13,     // European Article Number (13 digits) - most common in EU
        .ean8,      // EAN-8 (8 digits) - smaller packages
        .upce,      // UPC-E (compressed UPC)
        // Note: UPC-A (12 digits) is decoded as EAN-13 with leading zero
    ]

    // MARK: - Preview Layer

    var previewLayer: AVCaptureVideoPreviewLayer {
        if let existing = previewLayerInstance {
            return existing
        }
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        previewLayerInstance = layer
        return layer
    }

    // MARK: - State

    var isRunning: Bool {
        captureSession.isRunning
    }

    // MARK: - Camera Permission

    func checkCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied:
            return false
        case .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func getCameraPermissionStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    // MARK: - Configuration

    func configure() throws {
        guard !isConfigured else { return }

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        // Set session preset for optimal barcode scanning
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }

        // Configure video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw ScannerError.cameraUnavailable
        }

        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoDevice)
        } catch {
            throw ScannerError.configurationFailed
        }

        guard captureSession.canAddInput(videoInput) else {
            throw ScannerError.configurationFailed
        }
        captureSession.addInput(videoInput)

        // Configure metadata output for barcodes
        let metadataOutput = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(metadataOutput) else {
            throw ScannerError.configurationFailed
        }
        captureSession.addOutput(metadataOutput)

        // Set delegate and barcode types
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = Self.supportedBarcodeTypes

        // Optimize camera for barcode scanning
        try optimizeForBarcodeScanning(device: videoDevice)

        isConfigured = true
    }

    private func optimizeForBarcodeScanning(device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        // Enable auto-focus for near objects (barcodes)
        if device.isAutoFocusRangeRestrictionSupported {
            device.autoFocusRangeRestriction = .near
        }

        // Use continuous auto-focus
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }

        // Enable auto-exposure
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }

        // Improve low-light performance
        if device.isLowLightBoostSupported {
            device.automaticallyEnablesLowLightBoostWhenAvailable = true
        }
    }

    // MARK: - Scanning Control

    func startScanning() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            if !self.isConfigured {
                do {
                    try self.configure()
                } catch let error as ScannerError {
                    DispatchQueue.main.async {
                        self.delegate?.didFailWithError(error)
                    }
                    return
                } catch {
                    DispatchQueue.main.async {
                        self.delegate?.didFailWithError(.configurationFailed)
                    }
                    return
                }
            }

            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    func stopScanning() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }

    func pauseScanning() {
        stopScanning()
    }

    func resumeScanning() {
        startScanning()
    }

    // MARK: - Torch Control

    var hasTorch: Bool {
        guard let device = AVCaptureDevice.default(for: .video) else { return false }
        return device.hasTorch
    }

    var isTorchOn: Bool {
        guard let device = AVCaptureDevice.default(for: .video) else { return false }
        return device.torchMode == .on
    }

    func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else {
            return
        }

        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            // Torch control failed, ignore
        }
    }

    func toggleTorch() {
        setTorch(on: !isTorchOn)
    }

    // MARK: - Focus

    func focusAt(point: CGPoint, in previewBounds: CGRect) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        // Convert point to device coordinates
        let focusPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)

        do {
            try device.lockForConfiguration()

            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
            }

            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }

            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = focusPoint
            }

            if device.isExposureModeSupported(.autoExpose) {
                device.exposureMode = .autoExpose
            }

            device.unlockForConfiguration()
        } catch {
            // Focus control failed, ignore
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeScannerService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let barcode = metadataObject.stringValue,
              !barcode.isEmpty else {
            return
        }

        // Normalize the barcode
        let normalizedBarcode = normalizeBarcode(barcode, type: metadataObject.type)

        // Validate the barcode
        guard BarcodeValidator.isValid(normalizedBarcode) else {
            return
        }

        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Notify delegate
        delegate?.didDetectBarcode(normalizedBarcode, type: metadataObject.type)
    }

    private func normalizeBarcode(_ barcode: String, type: AVMetadataObject.ObjectType) -> String {
        switch type {
        case .upce:
            // Expand UPC-E to UPC-A, then normalize to EAN-13
            if let upcA = BarcodeValidator.expandUPCE(barcode) {
                return BarcodeValidator.normalizeToEAN13(upcA)
            }
            return barcode
        case .ean8:
            // Keep EAN-8 as is (valid format)
            return barcode
        default:
            return barcode
        }
    }
}

// MARK: - Camera Preview View (SwiftUI)

import SwiftUI

struct CameraPreviewView: UIViewRepresentable {
    let scannerService: BarcodeScannerService
    var onTap: ((CGPoint) -> Void)?

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView(scannerService: scannerService)
        view.onTap = onTap
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.updatePreviewLayer()
    }
}

final class CameraPreviewUIView: UIView {
    let scannerService: BarcodeScannerService
    var onTap: ((CGPoint) -> Void)?

    init(scannerService: BarcodeScannerService) {
        self.scannerService = scannerService
        super.init(frame: .zero)
        setupPreviewLayer()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPreviewLayer() {
        let previewLayer = scannerService.previewLayer
        previewLayer.frame = bounds
        layer.addSublayer(previewLayer)
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        onTap?(point)
        scannerService.focusAt(point: point, in: bounds)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePreviewLayer()
    }

    func updatePreviewLayer() {
        scannerService.previewLayer.frame = bounds
    }
}
