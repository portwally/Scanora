import Foundation
import UIKit

// MARK: - Product Contribution Data

struct ProductContribution: Sendable {
    let barcode: String
    var productName: String
    var brand: String?
    var quantity: String?
    var categories: String?
    var ingredientsText: String?
    var labels: String?  // e.g., "organic, vegan"
    var origins: String?
    var stores: String?

    // Images (converted to Data for sending)
    var frontImageData: Data?
    var ingredientsImageData: Data?
    var nutritionImageData: Data?
}

// MARK: - Contribution Response

struct ContributionResponse: Codable {
    let status: Int
    let statusVerbose: String?
    let imageId: String?

    enum CodingKeys: String, CodingKey {
        case status
        case statusVerbose = "status_verbose"
        case imageId = "imageid"
    }

    var isSuccess: Bool {
        status == 1
    }
}

// MARK: - Contribution Error

enum ContributionError: LocalizedError {
    case invalidBarcode
    case missingRequiredFields
    case uploadFailed(String)
    case imageUploadFailed(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidBarcode:
            return String(localized: "Invalid barcode format")
        case .missingRequiredFields:
            return String(localized: "Product name is required")
        case .uploadFailed(let message):
            return String(localized: "Upload failed: \(message)")
        case .imageUploadFailed(let message):
            return String(localized: "Image upload failed: \(message)")
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Product Contribution API

final class ProductContributionAPI: @unchecked Sendable {
    private let session: URLSession
    private let baseURL = URL(string: "https://world.openfoodfacts.org")!

    private let userAgent = "Scanora/1.0 iOS (https://github.com/scanora-app; contact@scanora.app)"

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Submit Product

    /// Submit a new product to Open Food Facts
    func submitProduct(_ contribution: ProductContribution) async throws {
        // Validate required fields
        guard BarcodeValidator.isValid(contribution.barcode) else {
            throw ContributionError.invalidBarcode
        }

        guard !contribution.productName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ContributionError.missingRequiredFields
        }

        // Submit product data
        try await submitProductData(contribution)

        // Upload images if available
        if let frontImage = contribution.frontImageData {
            try await uploadImage(frontImage, barcode: contribution.barcode, imageField: "front")
        }

        if let ingredientsImage = contribution.ingredientsImageData {
            try await uploadImage(ingredientsImage, barcode: contribution.barcode, imageField: "ingredients")
        }

        if let nutritionImage = contribution.nutritionImageData {
            try await uploadImage(nutritionImage, barcode: contribution.barcode, imageField: "nutrition")
        }
    }

    // MARK: - Submit Product Data

    private func submitProductData(_ contribution: ProductContribution) async throws {
        var url = baseURL.appendingPathComponent("/cgi/product_jqm2.pl")

        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "code", value: contribution.barcode),
            URLQueryItem(name: "product_name", value: contribution.productName)
        ]

        // Add optional fields
        if let brand = contribution.brand, !brand.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "brands", value: brand))
        }
        if let quantity = contribution.quantity, !quantity.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "quantity", value: quantity))
        }
        if let categories = contribution.categories, !categories.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "categories", value: categories))
        }
        if let ingredients = contribution.ingredientsText, !ingredients.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "ingredients_text", value: ingredients))
        }
        if let labels = contribution.labels, !labels.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "labels", value: labels))
        }
        if let origins = contribution.origins, !origins.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "origins", value: origins))
        }
        if let stores = contribution.stores, !stores.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "stores", value: stores))
        }

        guard let requestURL = components.url else {
            throw ContributionError.uploadFailed("Invalid URL")
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ContributionError.uploadFailed("Invalid response")
            }

            guard httpResponse.statusCode == 200 else {
                throw ContributionError.uploadFailed("Server returned status \(httpResponse.statusCode)")
            }

            // Parse response to check status
            if let responseString = String(data: data, encoding: .utf8) {
                if responseString.contains("\"status\":0") {
                    throw ContributionError.uploadFailed("Server rejected the submission")
                }
            }

        } catch let error as ContributionError {
            throw error
        } catch {
            throw ContributionError.networkError(error)
        }
    }

    // MARK: - Upload Image

    private func uploadImage(_ imageData: Data, barcode: String, imageField: String) async throws {
        let url = baseURL.appendingPathComponent("/cgi/product_image_upload.pl")

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add barcode field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"code\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(barcode)\r\n".data(using: .utf8)!)

        // Add image field type
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"imagefield\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(imageField)\r\n".data(using: .utf8)!)

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"imgupload_\(imageField)\"; filename=\"\(imageField).jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ContributionError.imageUploadFailed("Invalid response")
            }

            guard httpResponse.statusCode == 200 else {
                throw ContributionError.imageUploadFailed("Server returned status \(httpResponse.statusCode)")
            }

            // Check response for success
            if let responseDict = try? JSONDecoder().decode(ContributionResponse.self, from: data) {
                if !responseDict.isSuccess {
                    throw ContributionError.imageUploadFailed(responseDict.statusVerbose ?? "Unknown error")
                }
            }

        } catch let error as ContributionError {
            throw error
        } catch {
            throw ContributionError.networkError(error)
        }
    }
}

// MARK: - Image Compression Helper

extension UIImage {
    /// Compress image for upload (max 1MB, JPEG quality 0.8)
    func compressedForUpload(maxSizeKB: Int = 1024) -> Data? {
        var compression: CGFloat = 0.8
        var data = self.jpegData(compressionQuality: compression)

        while let imageData = data, imageData.count > maxSizeKB * 1024 && compression > 0.1 {
            compression -= 0.1
            data = self.jpegData(compressionQuality: compression)
        }

        return data
    }

    /// Resize image to max dimension while maintaining aspect ratio
    func resized(maxDimension: CGFloat = 1200) -> UIImage {
        let size = self.size
        let maxDim = max(size.width, size.height)

        if maxDim <= maxDimension {
            return self
        }

        let scale = maxDimension / maxDim
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
