import SwiftUI
import SwiftData

@MainActor
@Observable
final class ShoppingListViewModel {
    private var modelContext: ModelContext?

    var items: [ShoppingListItem] = []
    var isLoading = false

    var uncheckedItems: [ShoppingListItem] {
        items.filter { !$0.isChecked }
    }

    var checkedItems: [ShoppingListItem] {
        items.filter { $0.isChecked }
    }

    var uncheckedCount: Int {
        uncheckedItems.count
    }

    var totalCount: Int {
        items.count
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Load Data

    func loadItems() async {
        guard let modelContext else { return }

        isLoading = true
        defer { isLoading = false }

        let service = ShoppingListService(modelContext: modelContext)

        do {
            items = try await service.fetchAllItems()
        } catch {
            print("Failed to load shopping list: \(error)")
        }
    }

    // MARK: - Actions

    func toggleChecked(_ item: ShoppingListItem) {
        guard let modelContext else { return }

        let service = ShoppingListService(modelContext: modelContext)

        Task {
            do {
                try await service.toggleChecked(item)
                await loadItems()
            } catch {
                print("Failed to toggle item: \(error)")
            }
        }
    }

    func updateQuantity(_ item: ShoppingListItem, quantity: Int) {
        guard let modelContext else { return }

        let service = ShoppingListService(modelContext: modelContext)

        Task {
            do {
                try await service.updateQuantity(item, quantity: quantity)
                await loadItems()
            } catch {
                print("Failed to update quantity: \(error)")
            }
        }
    }

    func deleteItem(_ item: ShoppingListItem) {
        guard let modelContext else { return }

        let service = ShoppingListService(modelContext: modelContext)

        Task {
            do {
                try await service.deleteItem(item)
                await loadItems()
            } catch {
                print("Failed to delete item: \(error)")
            }
        }
    }

    func deleteItems(at offsets: IndexSet, from section: ShoppingListSection) {
        let sectionItems = section == .unchecked ? uncheckedItems : checkedItems
        for index in offsets {
            let item = sectionItems[index]
            deleteItem(item)
        }
    }

    func clearCheckedItems() {
        guard let modelContext else { return }

        let service = ShoppingListService(modelContext: modelContext)

        Task {
            do {
                try await service.clearCheckedItems()
                await loadItems()
            } catch {
                print("Failed to clear checked items: \(error)")
            }
        }
    }

    func clearAllItems() {
        guard let modelContext else { return }

        let service = ShoppingListService(modelContext: modelContext)

        Task {
            do {
                try await service.clearAllItems()
                await loadItems()
            } catch {
                print("Failed to clear all items: \(error)")
            }
        }
    }

    enum ShoppingListSection {
        case unchecked, checked
    }
}
