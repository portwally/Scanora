import Foundation

/// Represents a single ingredient in a product
struct Ingredient: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let text: String
    let percent: Double?
    let percentMin: Double?
    let percentMax: Double?

    // Dietary flags
    let isVegan: Bool?
    let isVegetarian: Bool?
    let isFromPalmOil: Bool?

    init(
        id: String,
        text: String,
        percent: Double? = nil,
        percentMin: Double? = nil,
        percentMax: Double? = nil,
        isVegan: Bool? = nil,
        isVegetarian: Bool? = nil,
        isFromPalmOil: Bool? = nil
    ) {
        self.id = id
        self.text = text
        self.percent = percent
        self.percentMin = percentMin
        self.percentMax = percentMax
        self.isVegan = isVegan
        self.isVegetarian = isVegetarian
        self.isFromPalmOil = isFromPalmOil
    }

    /// Initialize from API DTO
    init(from dto: OFFIngredientDTO) {
        self.id = dto.id ?? UUID().uuidString
        self.text = dto.text?.trimmingCharacters(in: .whitespaces) ?? ""
        self.percent = dto.percent ?? dto.percentEstimate
        self.percentMin = dto.percentMin
        self.percentMax = dto.percentMax
        self.isVegan = Self.parseBooleanString(dto.vegan)
        self.isVegetarian = Self.parseBooleanString(dto.vegetarian)
        self.isFromPalmOil = Self.parseBooleanString(dto.fromPalmOil)
    }

    /// Parse OFF boolean string values ("yes", "no", "maybe", nil)
    private static func parseBooleanString(_ value: String?) -> Bool? {
        guard let value = value?.lowercased() else { return nil }
        switch value {
        case "yes": return true
        case "no": return false
        default: return nil
        }
    }

    // MARK: - Computed Properties

    /// Display percentage if available
    var percentDisplay: String? {
        if let percent = percent {
            return String(format: "%.0f%%", percent)
        }
        if let min = percentMin, let max = percentMax {
            return String(format: "%.0f-%.0f%%", min, max)
        }
        return nil
    }

    /// Clean ingredient name for display
    var displayName: String {
        // Remove language prefixes like "en:" or "pt:"
        let cleaned = text
            .replacingOccurrences(of: #"^\w{2}:"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespaces)

        // Capitalize first letter
        return cleaned.prefix(1).uppercased() + cleaned.dropFirst()
    }

    /// Check if this ingredient contains allergen-related keywords
    func containsAllergen(_ allergen: Allergen) -> Bool {
        let lowercased = text.lowercased()
        switch allergen {
        case .gluten:
            return lowercased.contains("wheat") || lowercased.contains("gluten") ||
                   lowercased.contains("barley") || lowercased.contains("rye") ||
                   lowercased.contains("oat") || lowercased.contains("spelt") ||
                   lowercased.contains("trigo") || lowercased.contains("cevada")
        case .milk:
            return lowercased.contains("milk") || lowercased.contains("cream") ||
                   lowercased.contains("butter") || lowercased.contains("cheese") ||
                   lowercased.contains("lactose") || lowercased.contains("whey") ||
                   lowercased.contains("leite") || lowercased.contains("nata")
        case .eggs:
            return lowercased.contains("egg") || lowercased.contains("ovo")
        case .fish:
            return lowercased.contains("fish") || lowercased.contains("anchov") ||
                   lowercased.contains("salmon") || lowercased.contains("tuna") ||
                   lowercased.contains("peixe") || lowercased.contains("atum")
        case .crustaceans:
            return lowercased.contains("shrimp") || lowercased.contains("crab") ||
                   lowercased.contains("lobster") || lowercased.contains("prawn") ||
                   lowercased.contains("camarao") || lowercased.contains("caranguejo")
        case .peanuts:
            return lowercased.contains("peanut") || lowercased.contains("groundnut") ||
                   lowercased.contains("amendoim")
        case .nuts:
            return lowercased.contains("almond") || lowercased.contains("hazelnut") ||
                   lowercased.contains("walnut") || lowercased.contains("cashew") ||
                   lowercased.contains("pistachio") || lowercased.contains("pecan") ||
                   lowercased.contains("amendoa") || lowercased.contains("noz")
        case .soybeans:
            return lowercased.contains("soy") || lowercased.contains("soja")
        case .celery:
            return lowercased.contains("celery") || lowercased.contains("aipo")
        case .mustard:
            return lowercased.contains("mustard") || lowercased.contains("mostarda")
        case .sesame:
            return lowercased.contains("sesame") || lowercased.contains("sesamo")
        case .sulphites:
            return lowercased.contains("sulphite") || lowercased.contains("sulfite") ||
                   lowercased.contains("sulphur") || lowercased.contains("sulfito")
        case .lupin:
            return lowercased.contains("lupin") || lowercased.contains("tremoco")
        case .molluscs:
            return lowercased.contains("mollusc") || lowercased.contains("squid") ||
                   lowercased.contains("octopus") || lowercased.contains("clam") ||
                   lowercased.contains("mussel") || lowercased.contains("lula")
        }
    }
}

// MARK: - Ingredient Analysis

extension Array where Element == Ingredient {
    /// Get all vegan-incompatible ingredients
    var nonVeganIngredients: [Ingredient] {
        filter { $0.isVegan == false }
    }

    /// Get all vegetarian-incompatible ingredients
    var nonVegetarianIngredients: [Ingredient] {
        filter { $0.isVegetarian == false }
    }

    /// Get all ingredients from palm oil
    var palmOilIngredients: [Ingredient] {
        filter { $0.isFromPalmOil == true }
    }

    /// Check if all ingredients are vegan
    var isFullyVegan: Bool {
        allSatisfy { $0.isVegan != false }
    }

    /// Check if all ingredients are vegetarian
    var isFullyVegetarian: Bool {
        allSatisfy { $0.isVegetarian != false }
    }

    /// Check if product is palm oil free
    var isPalmOilFree: Bool {
        allSatisfy { $0.isFromPalmOil != true }
    }
}
