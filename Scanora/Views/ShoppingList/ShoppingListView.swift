import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ShoppingListViewModel()
    @State private var showingClearConfirmation = false

    var body: some View {
        Group {
            if viewModel.items.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .navigationTitle(String(localized: "Shopping List"))
        .toolbar {
            if !viewModel.checkedItems.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingClearConfirmation = true
                    } label: {
                        Text(String(localized: "Clear Checked"))
                            .font(.subheadline)
                    }
                }
            }
        }
        .confirmationDialog(
            String(localized: "Clear Checked Items"),
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Clear Checked"), role: .destructive) {
                viewModel.clearCheckedItems()
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "This will remove all checked items from your shopping list."))
        }
        .task {
            viewModel.setModelContext(modelContext)
            await viewModel.loadItems()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "No Items"), systemImage: "cart")
        } description: {
            Text(String(localized: "Add products to your shopping list from the product detail screen."))
        }
    }

    // MARK: - List Content

    private var listContent: some View {
        List {
            // Unchecked items
            if !viewModel.uncheckedItems.isEmpty {
                Section {
                    ForEach(viewModel.uncheckedItems) { item in
                        ShoppingListRowView(
                            item: item,
                            onToggle: { viewModel.toggleChecked(item) },
                            onQuantityChange: { viewModel.updateQuantity(item, quantity: $0) }
                        )
                    }
                    .onDelete { offsets in
                        viewModel.deleteItems(at: offsets, from: .unchecked)
                    }
                } header: {
                    Text(String(localized: "To Buy"))
                }
            }

            // Checked items
            if !viewModel.checkedItems.isEmpty {
                Section {
                    ForEach(viewModel.checkedItems) { item in
                        ShoppingListRowView(
                            item: item,
                            onToggle: { viewModel.toggleChecked(item) },
                            onQuantityChange: { viewModel.updateQuantity(item, quantity: $0) }
                        )
                    }
                    .onDelete { offsets in
                        viewModel.deleteItems(at: offsets, from: .checked)
                    }
                } header: {
                    Text(String(localized: "Purchased"))
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Shopping List Row

struct ShoppingListRowView: View {
    let item: ShoppingListItem
    let onToggle: () -> Void
    let onQuantityChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.isChecked ? .green : .gray)
            }
            .buttonStyle(.plain)

            // Product image
            if let imageURLString = item.imageURL, let imageURL = URL(string: imageURLString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        Image(systemName: "photo")
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Product info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.productName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(item.isChecked)
                    .foregroundColor(item.isChecked ? .secondary : .primary)
                    .lineLimit(2)

                if let brand = item.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            // Quantity stepper
            HStack(spacing: 8) {
                Button {
                    if item.quantity > 1 {
                        onQuantityChange(item.quantity - 1)
                    }
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.title3)
                        .foregroundColor(item.quantity > 1 ? .blue : .gray)
                }
                .buttonStyle(.plain)
                .disabled(item.quantity <= 1)

                Text("\(item.quantity)")
                    .font(.subheadline.monospacedDigit())
                    .frame(minWidth: 20)

                Button {
                    onQuantityChange(item.quantity + 1)
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ShoppingListView()
    }
    .modelContainer(for: [ShoppingListItem.self], inMemory: true)
}
