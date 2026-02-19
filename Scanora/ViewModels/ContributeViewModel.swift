import SwiftUI
import PhotosUI
import Vision

@MainActor
@Observable
final class ContributeViewModel {
    // MARK: - Product Info
    var barcode: String
    var productName: String = ""
    var brand: String = ""
    var quantity: String = ""
    var categories: String = ""
    var ingredientsText: String = ""
    var labels: String = ""
    var origins: String = ""
    var stores: String = ""

    // MARK: - Images
    var frontImage: UIImage?
    var ingredientsImage: UIImage?
    var nutritionImage: UIImage?

    // MARK: - State
    var isSubmitting = false
    var showError = false
    var errorMessage: String?
    var showSuccess = false
    var currentImagePicker: ImageType?
    var showOCRResult = false
    var ocrText: String = ""

    enum ImageType: String, Identifiable {
        case front, ingredients, nutrition
        var id: String { rawValue }
    }

    // MARK: - Services
    private let contributionAPI = ProductContributionAPI()

    // MARK: - Initialization

    init(barcode: String) {
        self.barcode = barcode
    }

    // MARK: - Validation

    var isValid: Bool {
        !productName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var hasAnyImage: Bool {
        frontImage != nil || ingredientsImage != nil || nutritionImage != nil
    }

    // MARK: - Submit

    func submit() async {
        guard isValid else {
            errorMessage = String(localized: "Please enter a product name")
            showError = true
            return
        }

        isSubmitting = true

        do {
            var contribution = ProductContribution(
                barcode: barcode,
                productName: productName.trimmingCharacters(in: .whitespaces),
                brand: brand.nilIfEmpty,
                quantity: quantity.nilIfEmpty,
                categories: categories.nilIfEmpty,
                ingredientsText: ingredientsText.nilIfEmpty,
                labels: labels.nilIfEmpty,
                origins: origins.nilIfEmpty,
                stores: stores.nilIfEmpty
            )

            // Compress and add images
            if let image = frontImage {
                contribution.frontImageData = image.resized().compressedForUpload()
            }
            if let image = ingredientsImage {
                contribution.ingredientsImageData = image.resized().compressedForUpload()
            }
            if let image = nutritionImage {
                contribution.nutritionImageData = image.resized().compressedForUpload()
            }

            try await contributionAPI.submitProduct(contribution)

            isSubmitting = false
            showSuccess = true

        } catch {
            isSubmitting = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Image Selection

    func setImage(_ image: UIImage, for type: ImageType) {
        switch type {
        case .front:
            frontImage = image
        case .ingredients:
            ingredientsImage = image
            // Auto-extract text from ingredients image
            Task {
                await extractText(from: image, for: .ingredients)
            }
        case .nutrition:
            nutritionImage = image
        }
    }

    func removeImage(for type: ImageType) {
        switch type {
        case .front:
            frontImage = nil
        case .ingredients:
            ingredientsImage = nil
        case .nutrition:
            nutritionImage = nil
        }
    }

    // MARK: - OCR Text Extraction

    func extractText(from image: UIImage, for type: ImageType) async {
        guard let cgImage = image.cgImage else { return }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["pt-PT", "en-US", "es-ES", "fr-FR", "de-DE", "it-IT"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])

            guard let observations = request.results else { return }

            let recognizedText = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")

            if type == .ingredients && !recognizedText.isEmpty {
                // Clean up the text a bit
                let cleanedText = cleanIngredientsText(recognizedText)

                await MainActor.run {
                    self.ocrText = cleanedText
                    self.showOCRResult = true
                }
            }

        } catch {
            // OCR failed silently - user can still type manually
            print("OCR failed: \(error)")
        }
    }

    private func cleanIngredientsText(_ text: String) -> String {
        // Basic cleanup of OCR text
        var cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)

        // Try to find "ingredients:" or similar markers and start from there
        let markers = ["ingredients:", "ingredientes:", "ingrédients:", "zutaten:", "ingredienti:"]
        for marker in markers {
            if let range = cleaned.lowercased().range(of: marker) {
                cleaned = String(cleaned[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                break
            }
        }

        return cleaned
    }

    func useOCRText() {
        ingredientsText = ocrText
        showOCRResult = false
    }

    func discardOCRText() {
        ocrText = ""
        showOCRResult = false
    }
}

// MARK: - String Extension

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }
}
