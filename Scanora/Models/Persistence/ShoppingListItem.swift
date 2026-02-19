import Foundation
import SwiftData

/// A product added to the shopping list
@Model
final class ShoppingListItem {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID
    var barcode: String
    var productName: String
    var brand: String?
    var imageURL: String?
    var quantity: Int
    var isChecked: Bool
    var addedAt: Date
    var note: String?

    // MARK: - Initialization

    init(
        barcode: String,
        productName: String,
        brand: String? = nil,
        imageURL: String? = nil,
        quantity: Int = 1,
        note: String? = nil
    ) {
        self.id = UUID()
        self.barcode = barcode
        self.productName = productName
        self.brand = brand
        self.imageURL = imageURL
        self.quantity = quantity
        self.isChecked = false
        self.addedAt = Date()
        self.note = note
    }

    // MARK: - Convenience Init from Product

    convenience init(from product: Product, quantity: Int = 1, note: String? = nil) {
        self.init(
            barcode: product.barcode,
            productName: product.name,
            brand: product.brand,
            imageURL: product.imageURL?.absoluteString,
            quantity: quantity,
            note: note
        )
    }

    // MARK: - Convenience Init from ScanHistory

    convenience init(from scan: ScanHistory, quantity: Int = 1, note: String? = nil) {
        self.init(
            barcode: scan.barcode,
            productName: scan.productName,
            brand: scan.brand,
            imageURL: scan.imageURL,
            quantity: quantity,
            note: note
        )
    }
}

// MARK: - Predicates

extension ShoppingListItem {
    static var uncheckedPredicate: Predicate<ShoppingListItem> {
        #Predicate<ShoppingListItem> { !$0.isChecked }
    }

    static var checkedPredicate: Predicate<ShoppingListItem> {
        #Predicate<ShoppingListItem> { $0.isChecked }
    }
}
