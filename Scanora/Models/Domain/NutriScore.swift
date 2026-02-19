import SwiftUI

// MARK: - NutriScore

/// Nutri-Score is a nutrition label that converts the nutritional value of products
/// into a simple code consisting of 5 letters (A to E), each with its own color.
enum NutriScore: String, CaseIterable, Codable, Sendable {
    case a, b, c, d, e

    var color: Color {
        switch self {
        case .a: return Color(red: 0.03, green: 0.51, blue: 0.16)  // Dark green #038141
        case .b: return Color(red: 0.53, green: 0.75, blue: 0.24)  // Light green #85BB2F
        case .c: return Color(red: 0.98, green: 0.78, blue: 0.04)  // Yellow #FECB02
        case .d: return Color(red: 0.93, green: 0.51, blue: 0.12)  // Orange #EE8100
        case .e: return Color(red: 0.87, green: 0.24, blue: 0.17)  // Red #E63E11
        }
    }

    var grade: String {
        rawValue.uppercased()
    }

    var localizedDescription: LocalizedStringKey {
        switch self {
        case .a: return "nutriscore.description.a"
        case .b: return "nutriscore.description.b"
        case .c: return "nutriscore.description.c"
        case .d: return "nutriscore.description.d"
        case .e: return "nutriscore.description.e"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .a: return String(localized: "Nutri-Score A: Excellent nutritional quality")
        case .b: return String(localized: "Nutri-Score B: Good nutritional quality")
        case .c: return String(localized: "Nutri-Score C: Average nutritional quality")
        case .d: return String(localized: "Nutri-Score D: Poor nutritional quality")
        case .e: return String(localized: "Nutri-Score E: Very poor nutritional quality")
        }
    }
}

// MARK: - NovaGroup

/// NOVA is a food classification system which assigns a group to food products
/// based on how much processing they have been through.
enum NovaGroup: Int, CaseIterable, Codable, Sendable {
    case unprocessed = 1
    case processedIngredients = 2
    case processed = 3
    case ultraProcessed = 4

    var localizedName: LocalizedStringKey {
        switch self {
        case .unprocessed: return "nova.group.1"
        case .processedIngredients: return "nova.group.2"
        case .processed: return "nova.group.3"
        case .ultraProcessed: return "nova.group.4"
        }
    }

    var localizedDescription: LocalizedStringKey {
        switch self {
        case .unprocessed: return "nova.description.1"
        case .processedIngredients: return "nova.description.2"
        case .processed: return "nova.description.3"
        case .ultraProcessed: return "nova.description.4"
        }
    }

    var color: Color {
        switch self {
        case .unprocessed: return .green
        case .processedIngredients: return .yellow
        case .processed: return .orange
        case .ultraProcessed: return .red
        }
    }

    var icon: String {
        switch self {
        case .unprocessed: return "leaf.fill"
        case .processedIngredients: return "carrot.fill"
        case .processed: return "frying.pan.fill"
        case .ultraProcessed: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - EcoScore

/// Eco-Score is an environmental score from A to E that makes it easy to compare
/// the environmental impact of food products.
enum EcoScore: String, CaseIterable, Codable, Sendable {
    case a, b, c, d, e

    var color: Color {
        switch self {
        case .a: return Color(red: 0.0, green: 0.55, blue: 0.27)   // Dark green
        case .b: return Color(red: 0.18, green: 0.73, blue: 0.42)  // Green
        case .c: return Color(red: 1.0, green: 0.84, blue: 0.0)    // Yellow
        case .d: return Color(red: 1.0, green: 0.6, blue: 0.0)     // Orange
        case .e: return Color(red: 0.87, green: 0.24, blue: 0.17)  // Red
        }
    }

    var grade: String {
        rawValue.uppercased()
    }

    var localizedDescription: LocalizedStringKey {
        switch self {
        case .a: return "ecoscore.description.a"
        case .b: return "ecoscore.description.b"
        case .c: return "ecoscore.description.c"
        case .d: return "ecoscore.description.d"
        case .e: return "ecoscore.description.e"
        }
    }
}
