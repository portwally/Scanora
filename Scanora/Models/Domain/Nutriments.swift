import Foundation

/// Nutritional information for a product, typically per 100g/100ml
struct Nutriments: Codable, Sendable, Hashable {
    // MARK: - Energy
    let energyKcal: Double?
    let energyKj: Double?

    // MARK: - Macronutrients
    let fat: Double?
    let saturatedFat: Double?
    let carbohydrates: Double?
    let sugars: Double?
    let fiber: Double?
    let proteins: Double?

    // MARK: - Salt & Sodium
    let salt: Double?
    let sodium: Double?

    // MARK: - Units (for display)
    let energyUnit: String
    let macroUnit: String

    init(
        energyKcal: Double? = nil,
        energyKj: Double? = nil,
        fat: Double? = nil,
        saturatedFat: Double? = nil,
        carbohydrates: Double? = nil,
        sugars: Double? = nil,
        fiber: Double? = nil,
        proteins: Double? = nil,
        salt: Double? = nil,
        sodium: Double? = nil,
        energyUnit: String = "kcal",
        macroUnit: String = "g"
    ) {
        self.energyKcal = energyKcal
        self.energyKj = energyKj
        self.fat = fat
        self.saturatedFat = saturatedFat
        self.carbohydrates = carbohydrates
        self.sugars = sugars
        self.fiber = fiber
        self.proteins = proteins
        self.salt = salt
        self.sodium = sodium
        self.energyUnit = energyUnit
        self.macroUnit = macroUnit
    }

    /// Initialize from API DTO
    init(from dto: OFFNutrimentsDTO) {
        self.energyKcal = dto.energyKcal100g ?? dto.energyKcal
        self.energyKj = dto.energyKj100g ?? dto.energyKj
        self.fat = dto.fat100g ?? dto.fat
        self.saturatedFat = dto.saturatedFat100g ?? dto.saturatedFat
        self.carbohydrates = dto.carbohydrates100g ?? dto.carbohydrates
        self.sugars = dto.sugars100g ?? dto.sugars
        self.fiber = dto.fiber100g ?? dto.fiber
        self.proteins = dto.proteins100g ?? dto.proteins
        self.salt = dto.salt100g ?? dto.salt
        self.sodium = dto.sodium100g ?? dto.sodium
        self.energyUnit = dto.energyUnit ?? "kcal"
        self.macroUnit = "g"
    }

    // MARK: - Computed Properties

    /// Check if we have enough data to display a nutrition table
    var hasData: Bool {
        energyKcal != nil || fat != nil || carbohydrates != nil || proteins != nil
    }

    /// Get energy display string
    var energyDisplay: String? {
        if let kcal = energyKcal {
            if let kj = energyKj {
                return String(format: "%.0f kcal / %.0f kJ", kcal, kj)
            }
            return String(format: "%.0f kcal", kcal)
        }
        if let kj = energyKj {
            return String(format: "%.0f kJ", kj)
        }
        return nil
    }

    /// Format a nutriment value for display
    func formatValue(_ value: Double?, unit: String = "g") -> String {
        guard let value = value else { return "-" }
        if value < 0.1 {
            return String(format: "<0.1 %@", unit)
        } else if value < 10 {
            return String(format: "%.1f %@", value, unit)
        } else {
            return String(format: "%.0f %@", value, unit)
        }
    }
}

// MARK: - Daily Value Percentages (EU Reference Intakes)

extension Nutriments {
    /// EU Reference Intakes for adults
    enum ReferenceIntake {
        static let energyKcal: Double = 2000
        static let fat: Double = 70
        static let saturatedFat: Double = 20
        static let carbohydrates: Double = 260
        static let sugars: Double = 90
        static let fiber: Double = 25
        static let proteins: Double = 50
        static let salt: Double = 6
    }

    /// Calculate percentage of daily reference intake
    func percentageOfDailyIntake(_ value: Double?, reference: Double) -> Int? {
        guard let value = value else { return nil }
        return Int(round((value / reference) * 100))
    }

    var energyPercentage: Int? {
        percentageOfDailyIntake(energyKcal, reference: ReferenceIntake.energyKcal)
    }

    var fatPercentage: Int? {
        percentageOfDailyIntake(fat, reference: ReferenceIntake.fat)
    }

    var saturatedFatPercentage: Int? {
        percentageOfDailyIntake(saturatedFat, reference: ReferenceIntake.saturatedFat)
    }

    var carbohydratesPercentage: Int? {
        percentageOfDailyIntake(carbohydrates, reference: ReferenceIntake.carbohydrates)
    }

    var sugarsPercentage: Int? {
        percentageOfDailyIntake(sugars, reference: ReferenceIntake.sugars)
    }

    var fiberPercentage: Int? {
        percentageOfDailyIntake(fiber, reference: ReferenceIntake.fiber)
    }

    var proteinsPercentage: Int? {
        percentageOfDailyIntake(proteins, reference: ReferenceIntake.proteins)
    }

    var saltPercentage: Int? {
        percentageOfDailyIntake(salt, reference: ReferenceIntake.salt)
    }
}

// MARK: - Traffic Light Rating

extension Nutriments {
    /// Traffic light rating for a nutriment (UK-style)
    enum TrafficLight: String {
        case low    // Green
        case medium // Amber
        case high   // Red

        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
    }

    /// Fat traffic light (per 100g)
    var fatRating: TrafficLight? {
        guard let fat = fat else { return nil }
        if fat <= 3 { return .low }
        if fat <= 17.5 { return .medium }
        return .high
    }

    /// Saturated fat traffic light (per 100g)
    var saturatedFatRating: TrafficLight? {
        guard let saturatedFat = saturatedFat else { return nil }
        if saturatedFat <= 1.5 { return .low }
        if saturatedFat <= 5 { return .medium }
        return .high
    }

    /// Sugars traffic light (per 100g)
    var sugarsRating: TrafficLight? {
        guard let sugars = sugars else { return nil }
        if sugars <= 5 { return .low }
        if sugars <= 22.5 { return .medium }
        return .high
    }

    /// Salt traffic light (per 100g)
    var saltRating: TrafficLight? {
        guard let salt = salt else { return nil }
        if salt <= 0.3 { return .low }
        if salt <= 1.5 { return .medium }
        return .high
    }
}
