import SwiftUI
import SwiftData

struct ProductDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let product: Product
    var onDismiss: (() -> Void)?

    @State private var selectedSection: DetailSection?
    @State private var addedToList = false
    @State private var showingAddedFeedback = false

    enum DetailSection: String, CaseIterable, Identifiable {
        case overview
        case nutrition
        case ingredients
        case allergens
        case origin

        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .overview: return "Overview"
            case .nutrition: return "Nutrition"
            case .ingredients: return "Ingredients"
            case .allergens: return "Allergens"
            case .origin: return "Origin"
            }
        }

        var icon: String {
            switch self {
            case .overview: return "info.circle"
            case .nutrition: return "chart.bar"
            case .ingredients: return "list.bullet"
            case .allergens: return "exclamationmark.triangle"
            case .origin: return "globe"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Product header
                ProductHeaderView(product: product)

                // Health scores
                HealthScoresRow(
                    nutriScore: product.nutriScore,
                    novaGroup: product.novaGroup,
                    ecoScore: product.ecoScore
                )

                // Add to shopping list button
                Button {
                    addToShoppingList()
                } label: {
                    HStack {
                        Image(systemName: addedToList ? "checkmark.circle.fill" : "cart.badge.plus")
                        Text(addedToList ? String(localized: "Added to List") : String(localized: "Add to Shopping List"))
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(addedToList ? Color.green : Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(addedToList)
                .padding(.horizontal, 16)

                // Allergen warning (if any)
                if product.hasAllergenWarnings {
                    AllergenWarningView(
                        allergens: product.allergens,
                        traces: product.traces
                    )
                    .padding(.horizontal)
                }

                // Section picker
                Picker("Section", selection: $selectedSection) {
                    ForEach(visibleSections) { section in
                        Label(section.title, systemImage: section.icon)
                            .tag(section as DetailSection?)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Section content
                Group {
                    switch selectedSection {
                    case .overview, .none:
                        OverviewSection(product: product)
                    case .nutrition:
                        NutritionSection(nutriments: product.nutriments)
                    case .ingredients:
                        IngredientsSection(
                            text: product.ingredientsText,
                            ingredients: product.ingredients
                        )
                    case .allergens:
                        AllergensSection(
                            allergens: product.allergens,
                            traces: product.traces
                        )
                    case .origin:
                        OriginSection(product: product)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    if let onDismiss {
                        onDismiss()
                    } else {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            selectedSection = .overview
        }
    }

    private var visibleSections: [DetailSection] {
        var sections: [DetailSection] = [.overview]

        if product.nutriments?.hasData == true {
            sections.append(.nutrition)
        }

        if product.ingredientsText != nil || !product.ingredients.isEmpty {
            sections.append(.ingredients)
        }

        if product.hasAllergenWarnings {
            sections.append(.allergens)
        }

        if product.origin != nil || !product.countries.isEmpty {
            sections.append(.origin)
        }

        return sections
    }

    // MARK: - Shopping List

    private func addToShoppingList() {
        let service = ShoppingListService(modelContext: modelContext)

        Task {
            do {
                try await service.addProduct(product, quantity: 1, note: nil)
                withAnimation {
                    addedToList = true
                }
            } catch {
                print("Failed to add to shopping list: \(error)")
            }
        }
    }
}

// MARK: - Product Header View

struct ProductHeaderView: View {
    let product: Product

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Product image
            AsyncImage(url: product.imageURL) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .overlay {
                            ProgressView()
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                case .failure:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 100, height: 100)

            // Product info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .lineLimit(2)

                if let brand = product.brand {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let quantity = product.quantity {
                    Text(quantity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let genericName = product.genericName {
                    Text(genericName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Barcode
                HStack(spacing: 4) {
                    Image(systemName: "barcode")
                        .font(.caption2)
                    Text(product.barcode)
                        .font(.caption.monospacedDigit())
                }
                .foregroundColor(.secondary)
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Overview Section

struct OverviewSection: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Categories
            if !product.categories.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Categories"))
                        .font(.subheadline.bold())

                    FlowLayout(spacing: 8) {
                        ForEach(product.categories, id: \.self) { category in
                            Text(CategoryTranslator.translate(category))
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Data quality
            DataQualityView(completeness: product.completeness)
        }
    }
}

// MARK: - Nutrition Section

struct NutritionSection: View {
    let nutriments: Nutriments?

    var body: some View {
        if let nutriments = nutriments, nutriments.hasData {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "Nutritional Information"))
                    .font(.subheadline.bold())

                Text(String(localized: "Per 100g"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                NutritionTable(nutriments: nutriments)
            }
        } else {
            Text(String(localized: "No nutritional information available"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Nutrition Table

struct NutritionTable: View {
    let nutriments: Nutriments

    var body: some View {
        VStack(spacing: 0) {
            NutritionRow(label: String(localized: "Energy"), value: nutriments.energyDisplay ?? "-")
            NutritionRow(label: String(localized: "Fat"), value: nutriments.formatValue(nutriments.fat))
            NutritionRow(label: String(localized: "  of which saturates"), value: nutriments.formatValue(nutriments.saturatedFat), isIndented: true)
            NutritionRow(label: String(localized: "Carbohydrates"), value: nutriments.formatValue(nutriments.carbohydrates))
            NutritionRow(label: String(localized: "  of which sugars"), value: nutriments.formatValue(nutriments.sugars), isIndented: true)
            NutritionRow(label: String(localized: "Fiber"), value: nutriments.formatValue(nutriments.fiber))
            NutritionRow(label: String(localized: "Proteins"), value: nutriments.formatValue(nutriments.proteins))
            NutritionRow(label: String(localized: "Salt"), value: nutriments.formatValue(nutriments.salt))
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

struct NutritionRow: View {
    let label: String
    let value: String
    var isIndented: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(isIndented ? .caption : .subheadline)
                .foregroundColor(isIndented ? .secondary : .primary)
            Spacer()
            Text(value)
                .font(isIndented ? .caption : .subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - Ingredients Section

struct IngredientsSection: View {
    let text: String?
    let ingredients: [Ingredient]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let text = text, !text.isEmpty {
                Text("Ingredients")
                    .font(.subheadline.bold())

                Text(text)
                    .font(.body)
                    .foregroundColor(.secondary)
            } else if !ingredients.isEmpty {
                Text("Ingredients")
                    .font(.subheadline.bold())

                ForEach(ingredients) { ingredient in
                    HStack {
                        Text(ingredient.displayName)
                            .font(.subheadline)
                        Spacer()
                        if let percent = ingredient.percentDisplay {
                            Text(percent)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("No ingredients information available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Allergens Section

struct AllergensSection: View {
    let allergens: Set<Allergen>
    let traces: Set<Allergen>

    var body: some View {
        AllergenListView(allergens: allergens, traces: traces)
    }
}

// MARK: - Origin Section

struct OriginSection: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let origin = product.origin {
                InfoRow(label: "Origin", value: origin)
            }

            if !product.countries.isEmpty {
                InfoRow(label: "Countries", value: product.countries.joined(separator: ", "))
            }

            if let manufacturer = product.manufacturer {
                InfoRow(label: "Manufacturer", value: manufacturer)
            }

            if let stores = product.stores {
                InfoRow(label: "Stores", value: stores)
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
        }
    }
}

// MARK: - Data Quality View

struct DataQualityView: View {
    let completeness: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Data Quality"))
                .font(.subheadline.bold())

            HStack(spacing: 8) {
                ProgressView(value: completeness)
                    .tint(qualityColor)

                Text("\(Int(completeness * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(qualityDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var qualityColor: Color {
        switch completeness {
        case 0.8...: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }

    private var qualityDescription: String {
        switch completeness {
        case 0.8...: return String(localized: "Excellent - complete product information")
        case 0.6..<0.8: return String(localized: "Good - most information available")
        case 0.4..<0.6: return String(localized: "Fair - some information missing")
        default: return String(localized: "Poor - limited information available")
        }
    }
}

// MARK: - Preview

#Preview {
    ProductDetailView(product: .preview)
}

#Preview("Minimal Product") {
    ProductDetailView(product: .previewMinimal)
}
