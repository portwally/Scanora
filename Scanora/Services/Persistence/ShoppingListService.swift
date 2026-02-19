import Foundation
import SwiftData

// MARK: - Protocol

protocol ShoppingListServiceProtocol {
    func fetchAllItems() async throws -> [ShoppingListItem]
    func fetchUncheckedItems() async throws -> [ShoppingListItem]
    func addItem(_ item: ShoppingListItem) async throws
    func addProduct(_ product: Product, quantity: Int, note: String?) async throws
    func toggleChecked(_ item: ShoppingListItem) async throws
    func updateQuantity(_ item: ShoppingListItem, quantity: Int) async throws
    func deleteItem(_ item: ShoppingListItem) async throws
    func clearCheckedItems() async throws
    func clearAllItems() async throws
    func isProductInList(barcode: String) async throws -> Bool
}

// MARK: - Implementation

@MainActor
final class ShoppingListService: ShoppingListServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch

    func fetchAllItems() async throws -> [ShoppingListItem] {
        let descriptor = FetchDescriptor<ShoppingListItem>(
            sortBy: [
                SortDescriptor(\.isChecked, order: .forward),
                SortDescriptor(\.addedAt, order: .reverse)
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchUncheckedItems() async throws -> [ShoppingListItem] {
        var descriptor = FetchDescriptor<ShoppingListItem>(
            predicate: ShoppingListItem.uncheckedPredicate,
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Add

    func addItem(_ item: ShoppingListItem) async throws {
        // Check if product already exists in list
        let barcode = item.barcode
        let existingDescriptor = FetchDescriptor<ShoppingListItem>(
            predicate: #Predicate { $0.barcode == barcode }
        )

        let existing = try modelContext.fetch(existingDescriptor)

        if let existingItem = existing.first {
            // Increment quantity instead of adding duplicate
            existingItem.quantity += item.quantity
            existingItem.isChecked = false // Uncheck if it was checked
        } else {
            modelContext.insert(item)
        }

        try modelContext.save()
    }

    func addProduct(_ product: Product, quantity: Int = 1, note: String? = nil) async throws {
        let item = ShoppingListItem(from: product, quantity: quantity, note: note)
        try await addItem(item)
    }

    // MARK: - Update

    func toggleChecked(_ item: ShoppingListItem) async throws {
        item.isChecked.toggle()
        try modelContext.save()
    }

    func updateQuantity(_ item: ShoppingListItem, quantity: Int) async throws {
        guard quantity > 0 else {
            try await deleteItem(item)
            return
        }
        item.quantity = quantity
        try modelContext.save()
    }

    func updateNote(_ item: ShoppingListItem, note: String?) async throws {
        item.note = note
        try modelContext.save()
    }

    // MARK: - Delete

    func deleteItem(_ item: ShoppingListItem) async throws {
        modelContext.delete(item)
        try modelContext.save()
    }

    func clearCheckedItems() async throws {
        let descriptor = FetchDescriptor<ShoppingListItem>(
            predicate: ShoppingListItem.checkedPredicate
        )
        let checkedItems = try modelContext.fetch(descriptor)

        for item in checkedItems {
            modelContext.delete(item)
        }

        try modelContext.save()
    }

    func clearAllItems() async throws {
        let descriptor = FetchDescriptor<ShoppingListItem>()
        let allItems = try modelContext.fetch(descriptor)

        for item in allItems {
            modelContext.delete(item)
        }

        try modelContext.save()
    }

    // MARK: - Query

    func isProductInList(barcode: String) async throws -> Bool {
        let descriptor = FetchDescriptor<ShoppingListItem>(
            predicate: #Predicate { $0.barcode == barcode }
        )
        let count = try modelContext.fetchCount(descriptor)
        return count > 0
    }

    func getItemCount() async throws -> Int {
        let descriptor = FetchDescriptor<ShoppingListItem>(
            predicate: ShoppingListItem.uncheckedPredicate
        )
        return try modelContext.fetchCount(descriptor)
    }
}
