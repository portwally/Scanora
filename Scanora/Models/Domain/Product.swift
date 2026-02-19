import Foundation

/// Clean domain model representing a food product
struct Product: Identifiable, Hashable, Sendable {
    // MARK: - Identification
    let id: String  // barcode
    let barcode: String

    // MARK: - Basic Info
    let name: String
    let genericName: String?
    let brand: String?
    let quantity: String?

    // MARK: - Origin & Manufacturing
    let manufacturer: String?
    let origin: String?
    let countries: [String]
    let stores: String?

    // MARK: - Categories
    let categories: [String]

    // MARK: - Ingredients
    let ingredientsText: String?
    let ingredients: [Ingredient]

    // MARK: - Allergens & Additives
    let allergens: Set<Allergen>
    let traces: Set<Allergen>
    let additives: [String]

    // MARK: - Health Scores
    let nutriScore: NutriScore?
    let novaGroup: NovaGroup?
    let ecoScore: EcoScore?
    let nutriments: Nutriments?

    // MARK: - Images
    let imageURL: URL?
    let imageThumbnailURL: URL?
    let ingredientsImageURL: URL?
    let nutritionImageURL: URL?

    // MARK: - Metadata
    let completeness: Double
    let lastModified: Date?

    // MARK: - Initialization from API DTO

    init(from dto: OFFProductDTO, preferredLanguage: String = Locale.current.language.languageCode?.identifier ?? "en") {
        self.barcode = dto.code ?? ""
        self.id = self.barcode

        // Select name based on preferred language
        self.name = Self.selectLocalizedValue(
            preferred: preferredLanguage,
            values: [
                "pt": dto.productNamePt,
                "en": dto.productNameEn,
                "es": dto.productNameEs,
                "fr": dto.productNameFr,
                "de": dto.productNameDe,
                "it": dto.productNameIt,
                "default": dto.productName
            ]
        ) ?? dto.productName ?? String(localized: "Unknown product")

        self.genericName = Self.selectLocalizedValue(
            preferred: preferredLanguage,
            values: [
                "pt": dto.genericNamePt,
                "en": dto.genericNameEn,
                "default": dto.genericName
            ]
        ) ?? dto.genericName

        self.brand = dto.brands
        self.quantity = dto.quantity
        self.manufacturer = dto.brandOwner
        self.origin = dto.origins
        self.stores = dto.stores

        // Parse countries
        self.countries = dto.countriesTags?.compactMap { tag in
            tag.replacingOccurrences(of: "en:", with: "")
               .replacingOccurrences(of: "-", with: " ")
               .capitalized
        } ?? []

        // Parse categories - prefer localized categories string, fallback to tags
        if let categoriesString = dto.categories, !categoriesString.isEmpty {
            self.categories = categoriesString
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .prefix(5)
                .map { String($0) }
        } else {
            self.categories = dto.categoriesTags?.compactMap { tag in
                tag.replacingOccurrences(of: "en:", with: "")
                   .replacingOccurrences(of: "pt:", with: "")
                   .replacingOccurrences(of: "de:", with: "")
                   .replacingOccurrences(of: "-", with: " ")
                   .capitalized
            }.prefix(5).map { $0 } ?? []
        }

        // Select ingredients text based on preferred language
        self.ingredientsText = Self.selectLocalizedValue(
            preferred: preferredLanguage,
            values: [
                "pt": dto.ingredientsTextPt,
                "en": dto.ingredientsTextEn,
                "es": dto.ingredientsTextEs,
                "fr": dto.ingredientsTextFr,
                "de": dto.ingredientsTextDe,
                "it": dto.ingredientsTextIt,
                "default": dto.ingredientsText
            ]
        ) ?? dto.ingredientsText

        self.ingredients = dto.ingredients?.map { Ingredient(from: $0) } ?? []

        // Parse allergens
        self.allergens = Set(dto.allergensTags?.compactMap { Allergen(from: $0) } ?? [])
        self.traces = Set(dto.tracesTags?.compactMap { Allergen(from: $0) } ?? [])

        // Clean additives tags
        self.additives = dto.additivesTags?.map { tag in
            tag.replacingOccurrences(of: "en:", with: "").uppercased()
        } ?? []

        // Health scores
        self.nutriScore = dto.nutriscoreGrade.flatMap { NutriScore(rawValue: $0.lowercased()) }
            ?? dto.nutritionGradeFr.flatMap { NutriScore(rawValue: $0.lowercased()) }
        self.novaGroup = dto.novaGroup.flatMap { NovaGroup(rawValue: $0) }
        self.ecoScore = (dto.ecoscoreGrade ?? dto.ecoscore).flatMap { EcoScore(rawValue: $0.lowercased()) }
        self.nutriments = dto.nutriments.map { Nutriments(from: $0) }

        // Images
        self.imageURL = (dto.imageFrontUrl ?? dto.imageUrl).flatMap { URL(string: $0) }
        self.imageThumbnailURL = (dto.imageFrontSmallUrl ?? dto.imageSmallUrl).flatMap { URL(string: $0) }
        self.ingredientsImageURL = dto.imageIngredientsUrl.flatMap { URL(string: $0) }
        self.nutritionImageURL = dto.imageNutritionUrl.flatMap { URL(string: $0) }

        // Metadata
        self.completeness = dto.completeness ?? 0
        self.lastModified = dto.lastModifiedT.map { Date(timeIntervalSince1970: TimeInterval($0)) }
    }

    /// Select the best localized value based on preferred language
    private static func selectLocalizedValue(preferred: String, values: [String: String?]) -> String? {
        // Try preferred language first
        if let value = values[preferred], let unwrapped = value, !unwrapped.isEmpty {
            return unwrapped
        }

        // Fallback to English
        if preferred != "en", let value = values["en"], let unwrapped = value, !unwrapped.isEmpty {
            return unwrapped
        }

        // Fallback to default/unlocalized value
        if let value = values["default"], let unwrapped = value, !unwrapped.isEmpty {
            return unwrapped
        }

        // Try any available value
        for (_, value) in values where value != nil && !value!.isEmpty {
            return value
        }

        return nil
    }

    // MARK: - Manual Initialization (for testing/preview)

    init(
        barcode: String,
        name: String,
        genericName: String? = nil,
        brand: String? = nil,
        quantity: String? = nil,
        manufacturer: String? = nil,
        origin: String? = nil,
        countries: [String] = [],
        stores: String? = nil,
        categories: [String] = [],
        ingredientsText: String? = nil,
        ingredients: [Ingredient] = [],
        allergens: Set<Allergen> = [],
        traces: Set<Allergen> = [],
        additives: [String] = [],
        nutriScore: NutriScore? = nil,
        novaGroup: NovaGroup? = nil,
        ecoScore: EcoScore? = nil,
        nutriments: Nutriments? = nil,
        imageURL: URL? = nil,
        imageThumbnailURL: URL? = nil,
        ingredientsImageURL: URL? = nil,
        nutritionImageURL: URL? = nil,
        completeness: Double = 0,
        lastModified: Date? = nil
    ) {
        self.barcode = barcode
        self.id = barcode
        self.name = name
        self.genericName = genericName
        self.brand = brand
        self.quantity = quantity
        self.manufacturer = manufacturer
        self.origin = origin
        self.countries = countries
        self.stores = stores
        self.categories = categories
        self.ingredientsText = ingredientsText
        self.ingredients = ingredients
        self.allergens = allergens
        self.traces = traces
        self.additives = additives
        self.nutriScore = nutriScore
        self.novaGroup = novaGroup
        self.ecoScore = ecoScore
        self.nutriments = nutriments
        self.imageURL = imageURL
        self.imageThumbnailURL = imageThumbnailURL
        self.ingredientsImageURL = ingredientsImageURL
        self.nutritionImageURL = nutritionImageURL
        self.completeness = completeness
        self.lastModified = lastModified
    }
}

// MARK: - Computed Properties

extension Product {
    /// Check if product has any allergen warnings
    var hasAllergenWarnings: Bool {
        !allergens.isEmpty || !traces.isEmpty
    }

    /// All allergens and traces combined
    var allAllergenWarnings: Set<Allergen> {
        allergens.union(traces)
    }

    /// Display string for brand and quantity
    var brandAndQuantity: String? {
        [brand, quantity]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " - ")
            .nilIfEmpty
    }

    /// Display string for origin
    var originDisplay: String? {
        if let origin = origin, !origin.isEmpty {
            return origin
        }
        if !countries.isEmpty {
            return countries.joined(separator: ", ")
        }
        return nil
    }

    /// Check if the product data is considered complete
    var isComplete: Bool {
        completeness >= 0.7
    }

    /// Get a quality rating based on completeness
    var dataQuality: DataQuality {
        switch completeness {
        case 0.8...: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .fair
        default: return .poor
        }
    }

    enum DataQuality: String {
        case excellent, good, fair, poor

        var localizedName: String {
            switch self {
            case .excellent: return String(localized: "Excellent data quality")
            case .good: return String(localized: "Good data quality")
            case .fair: return String(localized: "Fair data quality")
            case .poor: return String(localized: "Poor data quality")
            }
        }
    }
}

// MARK: - String Extension

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

// MARK: - Preview Data

extension Product {
    static let preview = Product(
        barcode: "3017620422003",
        name: "Nutella",
        genericName: "Hazelnut spread with cocoa",
        brand: "Ferrero",
        quantity: "400g",
        manufacturer: "Ferrero",
        origin: "Italy",
        countries: ["France", "Germany", "Portugal"],
        categories: ["Spreads", "Breakfast", "Sweet spreads"],
        ingredientsText: "Sugar, palm oil, hazelnuts 13%, fat-reduced cocoa 7.4%, skimmed milk powder 6.6%, whey powder, emulsifier: lecithins (soya), vanillin.",
        allergens: [.milk, .nuts, .soybeans],
        traces: [.gluten],
        additives: ["E322"],
        nutriScore: .e,
        novaGroup: .ultraProcessed,
        ecoScore: .d,
        nutriments: Nutriments(
            energyKcal: 539,
            energyKj: 2252,
            fat: 30.9,
            saturatedFat: 10.6,
            carbohydrates: 57.5,
            sugars: 56.3,
            fiber: 3.4,
            proteins: 6.3,
            salt: 0.107
        ),
        imageURL: URL(string: "https://images.openfoodfacts.org/images/products/301/762/042/2003/front_en.200.jpg"),
        completeness: 0.9,
        lastModified: Date()
    )

    static let previewMinimal = Product(
        barcode: "1234567890123",
        name: "Unknown Product",
        completeness: 0.2
    )
}
