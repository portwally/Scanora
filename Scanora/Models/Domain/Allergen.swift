import SwiftUI

/// The 14 allergens that must be declared according to EU regulation (EU 1169/2011)
enum Allergen: String, CaseIterable, Codable, Identifiable, Sendable {
    case gluten
    case crustaceans
    case eggs
    case fish
    case peanuts
    case soybeans
    case milk
    case nuts
    case celery
    case mustard
    case sesame
    case sulphites
    case lupin
    case molluscs

    var id: String { rawValue }

    var localizedName: LocalizedStringKey {
        switch self {
        case .gluten: return "allergen.gluten"
        case .crustaceans: return "allergen.crustaceans"
        case .eggs: return "allergen.eggs"
        case .fish: return "allergen.fish"
        case .peanuts: return "allergen.peanuts"
        case .soybeans: return "allergen.soybeans"
        case .milk: return "allergen.milk"
        case .nuts: return "allergen.nuts"
        case .celery: return "allergen.celery"
        case .mustard: return "allergen.mustard"
        case .sesame: return "allergen.sesame"
        case .sulphites: return "allergen.sulphites"
        case .lupin: return "allergen.lupin"
        case .molluscs: return "allergen.molluscs"
        }
    }

    var icon: String {
        switch self {
        case .gluten: return "wheat"
        case .crustaceans: return "shrimp"
        case .eggs: return "egg"
        case .fish: return "fish"
        case .peanuts: return "peanut"
        case .soybeans: return "soybean"
        case .milk: return "milk"
        case .nuts: return "nut"
        case .celery: return "celery"
        case .mustard: return "mustard"
        case .sesame: return "sesame"
        case .sulphites: return "sulphites"
        case .lupin: return "lupin"
        case .molluscs: return "shellfish"
        }
    }

    var sfSymbol: String {
        switch self {
        case .gluten: return "leaf.fill"
        case .crustaceans: return "allergens"
        case .eggs: return "oval.fill"
        case .fish: return "fish.fill"
        case .peanuts: return "allergens"
        case .soybeans: return "allergens"
        case .milk: return "drop.fill"
        case .nuts: return "allergens"
        case .celery: return "leaf.fill"
        case .mustard: return "allergens"
        case .sesame: return "circle.dotted"
        case .sulphites: return "flask.fill"
        case .lupin: return "leaf.fill"
        case .molluscs: return "allergens"
        }
    }

    var color: Color {
        switch self {
        case .gluten: return .brown
        case .crustaceans: return .orange
        case .eggs: return .yellow
        case .fish: return .blue
        case .peanuts: return .brown
        case .soybeans: return .green
        case .milk: return .white
        case .nuts: return .brown
        case .celery: return .green
        case .mustard: return .yellow
        case .sesame: return .brown
        case .sulphites: return .purple
        case .lupin: return .purple
        case .molluscs: return .gray
        }
    }

    /// Initialize from Open Food Facts API tag format
    /// Examples: "en:milk", "en:gluten", "pt:leite"
    init?(from tag: String) {
        let cleaned = tag
            .components(separatedBy: ":")
            .last?
            .lowercased()
            .trimmingCharacters(in: .whitespaces) ?? tag.lowercased()

        switch cleaned {
        // English
        case "gluten", "wheat", "cereals-containing-gluten":
            self = .gluten
        case "milk", "lactose", "dairy", "milk-and-milk-products":
            self = .milk
        case "eggs", "egg":
            self = .eggs
        case "fish", "fishes":
            self = .fish
        case "crustaceans", "shellfish", "shrimp", "crab", "lobster":
            self = .crustaceans
        case "molluscs", "mollusks", "squid", "octopus", "clams", "mussels", "oysters":
            self = .molluscs
        case "nuts", "tree-nuts", "almonds", "hazelnuts", "walnuts", "cashews", "pecans", "pistachios", "macadamia":
            self = .nuts
        case "peanuts", "peanut", "groundnuts":
            self = .peanuts
        case "soybeans", "soya", "soy":
            self = .soybeans
        case "celery":
            self = .celery
        case "mustard":
            self = .mustard
        case "sesame-seeds", "sesame":
            self = .sesame
        case "sulphur-dioxide-and-sulphites", "sulphites", "sulfites", "sulphur-dioxide":
            self = .sulphites
        case "lupin", "lupine", "lupins":
            self = .lupin

        // Portuguese
        case "glutem", "trigo":
            self = .gluten
        case "leite", "lactose", "lacticinios":
            self = .milk
        case "ovos", "ovo":
            self = .eggs
        case "peixe", "peixes":
            self = .fish
        case "crustaceos", "camarao", "caranguejo", "lagosta":
            self = .crustaceans
        case "moluscos", "lulas", "polvo", "ameijoas", "mexilhoes", "ostras":
            self = .molluscs
        case "frutos-de-casca-rija", "amendoas", "avelas", "nozes", "cajus", "pistachios":
            self = .nuts
        case "amendoins", "amendoim":
            self = .peanuts
        case "soja":
            self = .soybeans
        case "aipo":
            self = .celery
        case "mostarda":
            self = .mustard
        case "sesamo":
            self = .sesame
        case "sulfitos", "dioxido-de-enxofre":
            self = .sulphites
        case "tremoco", "tremocos":
            self = .lupin

        // Spanish
        case "huevos", "huevo":
            self = .eggs
        case "pescado", "pescados":
            self = .fish
        case "mariscos":
            self = .crustaceans
        case "cacahuetes", "cacahuete", "mani":
            self = .peanuts
        case "almendras", "avellanas", "nueces":
            self = .nuts
        case "ajonjoli":
            self = .sesame

        // French
        case "lait", "produits-laitiers":
            self = .milk
        case "oeufs", "oeuf":
            self = .eggs
        case "poisson", "poissons":
            self = .fish
        case "crustaces":
            self = .crustaceans
        case "mollusques":
            self = .molluscs
        case "fruits-a-coque", "amandes", "noisettes", "noix":
            self = .nuts
        case "arachides", "arachide":
            self = .peanuts
        case "celeri":
            self = .celery
        case "moutarde":
            self = .mustard

        // German
        case "milch", "milchprodukte":
            self = .milk
        case "eier", "ei":
            self = .eggs
        case "fisch", "fische":
            self = .fish
        case "krebstiere":
            self = .crustaceans
        case "weichtiere":
            self = .molluscs
        case "schalenfruchte", "mandeln", "haselnusse", "walnusse":
            self = .nuts
        case "erdnusse", "erdnuss":
            self = .peanuts
        case "sellerie":
            self = .celery
        case "senf":
            self = .mustard
        case "schwefeldioxid", "sulphite":
            self = .sulphites
        case "lupinen":
            self = .lupin

        // Italian
        case "latte", "latticini":
            self = .milk
        case "uova", "uovo":
            self = .eggs
        case "pesce", "pesci":
            self = .fish
        case "crostacei":
            self = .crustaceans
        case "molluschi":
            self = .molluscs
        case "frutta-a-guscio", "mandorle", "nocciole", "noci":
            self = .nuts
        case "arachidi":
            self = .peanuts
        case "sedano":
            self = .celery
        case "senape":
            self = .mustard

        default:
            return nil
        }
    }
}

// MARK: - Allergen Set Extension

extension Set where Element == Allergen {
    /// Check if this set contains any major allergens
    var containsMajorAllergens: Bool {
        !self.isEmpty
    }

    /// Get allergens sorted by severity/commonality
    var sortedBySeverity: [Allergen] {
        // Most common allergens first
        let priority: [Allergen] = [
            .milk, .gluten, .eggs, .peanuts, .nuts,
            .fish, .crustaceans, .soybeans, .sesame,
            .celery, .mustard, .sulphites, .lupin, .molluscs
        ]

        return self.sorted { allergen1, allergen2 in
            let index1 = priority.firstIndex(of: allergen1) ?? Int.max
            let index2 = priority.firstIndex(of: allergen2) ?? Int.max
            return index1 < index2
        }
    }
}
