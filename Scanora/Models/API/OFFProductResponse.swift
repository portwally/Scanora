import Foundation

// MARK: - Root Response

/// Root response from Open Food Facts API
struct OFFProductResponse: Codable, Sendable {
    let code: String
    let product: OFFProductDTO?
    let status: Int
    let statusVerbose: String

    enum CodingKeys: String, CodingKey {
        case code, product, status
        case statusVerbose = "status_verbose"
    }

    var isFound: Bool {
        status == 1 && product != nil
    }
}

/// Search response from Open Food Facts API
struct OFFSearchResponse: Codable, Sendable {
    let count: Int
    let page: Int
    let pageCount: Int
    let pageSize: Int
    let products: [OFFProductDTO]

    enum CodingKeys: String, CodingKey {
        case count, page, products
        case pageCount = "page_count"
        case pageSize = "page_size"
    }
}

// MARK: - Product DTO

/// Product data transfer object matching OFF API structure
struct OFFProductDTO: Codable, Sendable {
    // MARK: - Identification
    let code: String?
    let id: String?

    // MARK: - Product Names (localized)
    let productName: String?
    let productNamePt: String?
    let productNameEn: String?
    let productNameEs: String?
    let productNameFr: String?
    let productNameDe: String?
    let productNameIt: String?
    let genericName: String?
    let genericNamePt: String?
    let genericNameEn: String?

    // MARK: - Brand & Manufacturer
    let brands: String?
    let brandsTags: [String]?
    let brandOwner: String?
    let manufacturingPlaces: String?
    let origins: String?
    let originsTags: [String]?

    // MARK: - Categories
    let categories: String?
    let categoriesTags: [String]?
    let categoriesHierarchy: [String]?

    // MARK: - Ingredients (localized)
    let ingredientsText: String?
    let ingredientsTextPt: String?
    let ingredientsTextEn: String?
    let ingredientsTextEs: String?
    let ingredientsTextFr: String?
    let ingredientsTextDe: String?
    let ingredientsTextIt: String?
    let ingredients: [OFFIngredientDTO]?
    let ingredientsTags: [String]?
    let ingredientsAnalysisTags: [String]?

    // MARK: - Allergens & Traces
    let allergens: String?
    let allergensTags: [String]?
    let allergensHierarchy: [String]?
    let traces: String?
    let tracesTags: [String]?

    // MARK: - Additives
    let additivesN: Int?
    let additivesTags: [String]?
    let additivesOriginalTags: [String]?

    // MARK: - Nutrition & Health Scores
    let nutriscoreGrade: String?
    let nutriscoreScore: Int?
    let nutriscoreVersion: String?
    let novaGroup: Int?
    let nutritionGradeFr: String?
    let ecoscore: String?
    let ecoscoreGrade: String?

    // MARK: - Nutriments
    let nutriments: OFFNutrimentsDTO?

    // MARK: - Images
    let imageUrl: String?
    let imageSmallUrl: String?
    let imageFrontUrl: String?
    let imageFrontSmallUrl: String?
    let imageIngredientsUrl: String?
    let imageNutritionUrl: String?

    // MARK: - Packaging
    let packaging: String?
    let packagingTags: [String]?
    let packagings: [OFFPackagingDTO]?
    let quantity: String?

    // MARK: - Geographic Data
    let countries: String?
    let countriesTags: [String]?
    let purchasePlaces: String?
    let stores: String?

    // MARK: - Metadata
    let completeness: Double?
    let createdT: Int?
    let lastModifiedT: Int?

    enum CodingKeys: String, CodingKey {
        case code, id, brands, origins, categories, allergens, traces, packaging, countries, quantity, stores
        case productName = "product_name"
        case productNamePt = "product_name_pt"
        case productNameEn = "product_name_en"
        case productNameEs = "product_name_es"
        case productNameFr = "product_name_fr"
        case productNameDe = "product_name_de"
        case productNameIt = "product_name_it"
        case genericName = "generic_name"
        case genericNamePt = "generic_name_pt"
        case genericNameEn = "generic_name_en"
        case brandsTags = "brands_tags"
        case brandOwner = "brand_owner"
        case manufacturingPlaces = "manufacturing_places"
        case originsTags = "origins_tags"
        case categoriesTags = "categories_tags"
        case categoriesHierarchy = "categories_hierarchy"
        case ingredientsText = "ingredients_text"
        case ingredientsTextPt = "ingredients_text_pt"
        case ingredientsTextEn = "ingredients_text_en"
        case ingredientsTextEs = "ingredients_text_es"
        case ingredientsTextFr = "ingredients_text_fr"
        case ingredientsTextDe = "ingredients_text_de"
        case ingredientsTextIt = "ingredients_text_it"
        case ingredients
        case ingredientsTags = "ingredients_tags"
        case ingredientsAnalysisTags = "ingredients_analysis_tags"
        case allergensTags = "allergens_tags"
        case allergensHierarchy = "allergens_hierarchy"
        case tracesTags = "traces_tags"
        case additivesN = "additives_n"
        case additivesTags = "additives_tags"
        case additivesOriginalTags = "additives_original_tags"
        case nutriscoreGrade = "nutriscore_grade"
        case nutriscoreScore = "nutriscore_score"
        case nutriscoreVersion = "nutriscore_version"
        case novaGroup = "nova_group"
        case nutritionGradeFr = "nutrition_grade_fr"
        case ecoscore
        case ecoscoreGrade = "ecoscore_grade"
        case nutriments
        case imageUrl = "image_url"
        case imageSmallUrl = "image_small_url"
        case imageFrontUrl = "image_front_url"
        case imageFrontSmallUrl = "image_front_small_url"
        case imageIngredientsUrl = "image_ingredients_url"
        case imageNutritionUrl = "image_nutrition_url"
        case packagingTags = "packaging_tags"
        case packagings
        case countriesTags = "countries_tags"
        case purchasePlaces = "purchase_places"
        case completeness
        case createdT = "created_t"
        case lastModifiedT = "last_modified_t"
    }
}

// MARK: - Ingredient DTO

struct OFFIngredientDTO: Codable, Sendable {
    let id: String?
    let text: String?
    let percentEstimate: Double?
    let percentMin: Double?
    let percentMax: Double?
    let percent: Double?
    let vegan: String?
    let vegetarian: String?
    let fromPalmOil: String?

    enum CodingKeys: String, CodingKey {
        case id, text, vegan, vegetarian, percent
        case percentEstimate = "percent_estimate"
        case percentMin = "percent_min"
        case percentMax = "percent_max"
        case fromPalmOil = "from_palm_oil"
    }
}

// MARK: - Nutriments DTO

struct OFFNutrimentsDTO: Codable, Sendable {
    // Energy
    let energy: Double?
    let energyKcal: Double?
    let energyKcal100g: Double?
    let energyKj: Double?
    let energyKj100g: Double?
    let energyUnit: String?
    let energyValue: Double?

    // Macronutrients
    let fat: Double?
    let fat100g: Double?
    let fatUnit: String?
    let saturatedFat: Double?
    let saturatedFat100g: Double?
    let saturatedFatUnit: String?
    let carbohydrates: Double?
    let carbohydrates100g: Double?
    let carbohydratesUnit: String?
    let sugars: Double?
    let sugars100g: Double?
    let sugarsUnit: String?
    let fiber: Double?
    let fiber100g: Double?
    let fiberUnit: String?
    let proteins: Double?
    let proteins100g: Double?
    let proteinsUnit: String?

    // Salt & Sodium
    let salt: Double?
    let salt100g: Double?
    let saltUnit: String?
    let sodium: Double?
    let sodium100g: Double?
    let sodiumUnit: String?

    enum CodingKeys: String, CodingKey {
        case energy, fat, carbohydrates, sugars, fiber, proteins, salt, sodium
        case energyKcal = "energy-kcal"
        case energyKcal100g = "energy-kcal_100g"
        case energyKj = "energy-kj"
        case energyKj100g = "energy-kj_100g"
        case energyUnit = "energy_unit"
        case energyValue = "energy_value"
        case fat100g = "fat_100g"
        case fatUnit = "fat_unit"
        case saturatedFat = "saturated-fat"
        case saturatedFat100g = "saturated-fat_100g"
        case saturatedFatUnit = "saturated-fat_unit"
        case carbohydrates100g = "carbohydrates_100g"
        case carbohydratesUnit = "carbohydrates_unit"
        case sugars100g = "sugars_100g"
        case sugarsUnit = "sugars_unit"
        case fiber100g = "fiber_100g"
        case fiberUnit = "fiber_unit"
        case proteins100g = "proteins_100g"
        case proteinsUnit = "proteins_unit"
        case salt100g = "salt_100g"
        case saltUnit = "salt_unit"
        case sodium100g = "sodium_100g"
        case sodiumUnit = "sodium_unit"
    }
}

// MARK: - Packaging DTO

struct OFFPackagingDTO: Codable, Sendable {
    let material: String?
    let shape: String?
    let quantity: String?
    let quantityPerUnit: String?
    let recycling: String?
    let weightMeasured: Double?

    enum CodingKeys: String, CodingKey {
        case material, shape, quantity, recycling
        case quantityPerUnit = "quantity_per_unit"
        case weightMeasured = "weight_measured"
    }
}
