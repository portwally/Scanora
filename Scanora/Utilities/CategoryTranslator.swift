import Foundation

/// Translates common Open Food Facts category names to the user's language
enum CategoryTranslator {

    /// Common food categories with translations
    /// Keys are lowercase English category names
    private static let translations: [String: [String: String]] = [
        // Snacks & Sweets
        "snacks": ["de": "Snacks", "es": "Aperitivos", "fr": "Snacks", "it": "Snack", "nl": "Snacks", "pl": "Przekąski", "pt": "Petiscos"],
        "salty snacks": ["de": "Salzige Snacks", "es": "Aperitivos salados", "fr": "Snacks salés", "it": "Snack salati", "nl": "Hartige snacks", "pl": "Słone przekąski", "pt": "Petiscos salgados"],
        "sweet snacks": ["de": "Süße Snacks", "es": "Aperitivos dulces", "fr": "Snacks sucrés", "it": "Snack dolci", "nl": "Zoete snacks", "pl": "Słodkie przekąski", "pt": "Petiscos doces"],
        "appetizers": ["de": "Vorspeisen", "es": "Aperitivos", "fr": "Apéritifs", "it": "Antipasti", "nl": "Voorgerechten", "pl": "Przystawki", "pt": "Aperitivos"],
        "chips": ["de": "Chips", "es": "Patatas fritas", "fr": "Chips", "it": "Patatine", "nl": "Chips", "pl": "Chipsy", "pt": "Batatas fritas"],
        "crisps": ["de": "Chips", "es": "Patatas fritas", "fr": "Chips", "it": "Patatine", "nl": "Chips", "pl": "Chipsy", "pt": "Batatas fritas"],
        "popcorn": ["de": "Popcorn", "es": "Palomitas", "fr": "Pop-corn", "it": "Popcorn", "nl": "Popcorn", "pl": "Popcorn", "pt": "Pipocas"],
        "nuts": ["de": "Nüsse", "es": "Frutos secos", "fr": "Noix", "it": "Frutta secca", "nl": "Noten", "pl": "Orzechy", "pt": "Nozes"],
        "candies": ["de": "Süßigkeiten", "es": "Caramelos", "fr": "Bonbons", "it": "Caramelle", "nl": "Snoep", "pl": "Cukierki", "pt": "Doces"],
        "chocolates": ["de": "Schokolade", "es": "Chocolates", "fr": "Chocolats", "it": "Cioccolato", "nl": "Chocolade", "pl": "Czekolada", "pt": "Chocolates"],
        "chocolate": ["de": "Schokolade", "es": "Chocolate", "fr": "Chocolat", "it": "Cioccolato", "nl": "Chocolade", "pl": "Czekolada", "pt": "Chocolate"],

        // Baked Goods
        "biscuits": ["de": "Kekse", "es": "Galletas", "fr": "Biscuits", "it": "Biscotti", "nl": "Koekjes", "pl": "Herbatniki", "pt": "Biscoitos"],
        "biscuits and crackers": ["de": "Kekse und Cracker", "es": "Galletas y crackers", "fr": "Biscuits et crackers", "it": "Biscotti e cracker", "nl": "Koekjes en crackers", "pl": "Herbatniki i krakersy", "pt": "Biscoitos e crackers"],
        "crackers": ["de": "Cracker", "es": "Crackers", "fr": "Crackers", "it": "Cracker", "nl": "Crackers", "pl": "Krakersy", "pt": "Crackers"],
        "cookies": ["de": "Kekse", "es": "Galletas", "fr": "Cookies", "it": "Biscotti", "nl": "Koekjes", "pl": "Ciastka", "pt": "Bolachas"],
        "bread": ["de": "Brot", "es": "Pan", "fr": "Pain", "it": "Pane", "nl": "Brood", "pl": "Chleb", "pt": "Pão"],
        "breads": ["de": "Brote", "es": "Panes", "fr": "Pains", "it": "Pani", "nl": "Broden", "pl": "Pieczywo", "pt": "Pães"],
        "pastries": ["de": "Gebäck", "es": "Pastelería", "fr": "Pâtisseries", "it": "Pasticceria", "nl": "Gebak", "pl": "Wypieki", "pt": "Pastelaria"],
        "cakes": ["de": "Kuchen", "es": "Pasteles", "fr": "Gâteaux", "it": "Torte", "nl": "Taarten", "pl": "Ciasta", "pt": "Bolos"],

        // Breakfast
        "breakfast": ["de": "Frühstück", "es": "Desayuno", "fr": "Petit-déjeuner", "it": "Colazione", "nl": "Ontbijt", "pl": "Śniadanie", "pt": "Pequeno-almoço"],
        "cereals": ["de": "Cerealien", "es": "Cereales", "fr": "Céréales", "it": "Cereali", "nl": "Ontbijtgranen", "pl": "Płatki śniadaniowe", "pt": "Cereais"],
        "breakfast cereals": ["de": "Frühstückscerealien", "es": "Cereales de desayuno", "fr": "Céréales petit-déjeuner", "it": "Cereali da colazione", "nl": "Ontbijtgranen", "pl": "Płatki śniadaniowe", "pt": "Cereais de pequeno-almoço"],
        "muesli": ["de": "Müsli", "es": "Muesli", "fr": "Muesli", "it": "Muesli", "nl": "Muesli", "pl": "Musli", "pt": "Muesli"],
        "granola": ["de": "Granola", "es": "Granola", "fr": "Granola", "it": "Granola", "nl": "Granola", "pl": "Granola", "pt": "Granola"],

        // Spreads
        "spreads": ["de": "Aufstriche", "es": "Untables", "fr": "Pâtes à tartiner", "it": "Creme spalmabili", "nl": "Smeersels", "pl": "Pasty do smarowania", "pt": "Pastas de barrar"],
        "sweet spreads": ["de": "Süße Aufstriche", "es": "Untables dulces", "fr": "Pâtes à tartiner sucrées", "it": "Creme dolci", "nl": "Zoete smeersels", "pl": "Słodkie pasty", "pt": "Pastas doces"],
        "jams": ["de": "Marmeladen", "es": "Mermeladas", "fr": "Confitures", "it": "Marmellate", "nl": "Jam", "pl": "Dżemy", "pt": "Compotas"],
        "honey": ["de": "Honig", "es": "Miel", "fr": "Miel", "it": "Miele", "nl": "Honing", "pl": "Miód", "pt": "Mel"],
        "peanut butter": ["de": "Erdnussbutter", "es": "Mantequilla de cacahuete", "fr": "Beurre de cacahuète", "it": "Burro di arachidi", "nl": "Pindakaas", "pl": "Masło orzechowe", "pt": "Manteiga de amendoim"],

        // Dairy
        "dairy": ["de": "Milchprodukte", "es": "Lácteos", "fr": "Produits laitiers", "it": "Latticini", "nl": "Zuivel", "pl": "Nabiał", "pt": "Laticínios"],
        "dairies": ["de": "Milchprodukte", "es": "Lácteos", "fr": "Produits laitiers", "it": "Latticini", "nl": "Zuivel", "pl": "Nabiał", "pt": "Laticínios"],
        "milk": ["de": "Milch", "es": "Leche", "fr": "Lait", "it": "Latte", "nl": "Melk", "pl": "Mleko", "pt": "Leite"],
        "cheese": ["de": "Käse", "es": "Queso", "fr": "Fromage", "it": "Formaggio", "nl": "Kaas", "pl": "Ser", "pt": "Queijo"],
        "cheeses": ["de": "Käse", "es": "Quesos", "fr": "Fromages", "it": "Formaggi", "nl": "Kazen", "pl": "Sery", "pt": "Queijos"],
        "yogurt": ["de": "Joghurt", "es": "Yogur", "fr": "Yaourt", "it": "Yogurt", "nl": "Yoghurt", "pl": "Jogurt", "pt": "Iogurte"],
        "yogurts": ["de": "Joghurts", "es": "Yogures", "fr": "Yaourts", "it": "Yogurt", "nl": "Yoghurts", "pl": "Jogurty", "pt": "Iogurtes"],
        "butter": ["de": "Butter", "es": "Mantequilla", "fr": "Beurre", "it": "Burro", "nl": "Boter", "pl": "Masło", "pt": "Manteiga"],
        "cream": ["de": "Sahne", "es": "Nata", "fr": "Crème", "it": "Panna", "nl": "Room", "pl": "Śmietana", "pt": "Nata"],
        "ice cream": ["de": "Eiscreme", "es": "Helado", "fr": "Glace", "it": "Gelato", "nl": "IJs", "pl": "Lody", "pt": "Gelado"],

        // Beverages
        "beverages": ["de": "Getränke", "es": "Bebidas", "fr": "Boissons", "it": "Bevande", "nl": "Dranken", "pl": "Napoje", "pt": "Bebidas"],
        "drinks": ["de": "Getränke", "es": "Bebidas", "fr": "Boissons", "it": "Bevande", "nl": "Dranken", "pl": "Napoje", "pt": "Bebidas"],
        "juices": ["de": "Säfte", "es": "Zumos", "fr": "Jus", "it": "Succhi", "nl": "Sappen", "pl": "Soki", "pt": "Sumos"],
        "sodas": ["de": "Limonaden", "es": "Refrescos", "fr": "Sodas", "it": "Bibite", "nl": "Frisdranken", "pl": "Napoje gazowane", "pt": "Refrigerantes"],
        "water": ["de": "Wasser", "es": "Agua", "fr": "Eau", "it": "Acqua", "nl": "Water", "pl": "Woda", "pt": "Água"],
        "coffee": ["de": "Kaffee", "es": "Café", "fr": "Café", "it": "Caffè", "nl": "Koffie", "pl": "Kawa", "pt": "Café"],
        "tea": ["de": "Tee", "es": "Té", "fr": "Thé", "it": "Tè", "nl": "Thee", "pl": "Herbata", "pt": "Chá"],

        // Meals
        "meals": ["de": "Mahlzeiten", "es": "Comidas", "fr": "Plats", "it": "Piatti", "nl": "Maaltijden", "pl": "Posiłki", "pt": "Refeições"],
        "prepared meals": ["de": "Fertiggerichte", "es": "Platos preparados", "fr": "Plats préparés", "it": "Piatti pronti", "nl": "Kant-en-klaar", "pl": "Gotowe dania", "pt": "Pratos preparados"],
        "frozen meals": ["de": "Tiefkühlgerichte", "es": "Platos congelados", "fr": "Plats surgelés", "it": "Piatti surgelati", "nl": "Diepvriesmaaltijden", "pl": "Mrożone dania", "pt": "Pratos congelados"],
        "soups": ["de": "Suppen", "es": "Sopas", "fr": "Soupes", "it": "Zuppe", "nl": "Soepen", "pl": "Zupy", "pt": "Sopas"],
        "salads": ["de": "Salate", "es": "Ensaladas", "fr": "Salades", "it": "Insalate", "nl": "Salades", "pl": "Sałatki", "pt": "Saladas"],
        "pizzas": ["de": "Pizzen", "es": "Pizzas", "fr": "Pizzas", "it": "Pizze", "nl": "Pizza's", "pl": "Pizze", "pt": "Pizzas"],
        "pasta": ["de": "Pasta", "es": "Pasta", "fr": "Pâtes", "it": "Pasta", "nl": "Pasta", "pl": "Makaron", "pt": "Massa"],
        "rice": ["de": "Reis", "es": "Arroz", "fr": "Riz", "it": "Riso", "nl": "Rijst", "pl": "Ryż", "pt": "Arroz"],
        "sandwiches": ["de": "Sandwiches", "es": "Sándwiches", "fr": "Sandwichs", "it": "Panini", "nl": "Broodjes", "pl": "Kanapki", "pt": "Sanduíches"],

        // Meat & Fish
        "meats": ["de": "Fleisch", "es": "Carnes", "fr": "Viandes", "it": "Carni", "nl": "Vlees", "pl": "Mięso", "pt": "Carnes"],
        "meat": ["de": "Fleisch", "es": "Carne", "fr": "Viande", "it": "Carne", "nl": "Vlees", "pl": "Mięso", "pt": "Carne"],
        "poultry": ["de": "Geflügel", "es": "Aves", "fr": "Volaille", "it": "Pollame", "nl": "Gevogelte", "pl": "Drób", "pt": "Aves"],
        "fish": ["de": "Fisch", "es": "Pescado", "fr": "Poisson", "it": "Pesce", "nl": "Vis", "pl": "Ryby", "pt": "Peixe"],
        "seafood": ["de": "Meeresfrüchte", "es": "Mariscos", "fr": "Fruits de mer", "it": "Frutti di mare", "nl": "Zeevruchten", "pl": "Owoce morza", "pt": "Frutos do mar"],
        "sausages": ["de": "Würste", "es": "Salchichas", "fr": "Saucisses", "it": "Salsicce", "nl": "Worstjes", "pl": "Kiełbasy", "pt": "Salsichas"],

        // Fruits & Vegetables
        "fruits": ["de": "Früchte", "es": "Frutas", "fr": "Fruits", "it": "Frutta", "nl": "Fruit", "pl": "Owoce", "pt": "Frutas"],
        "vegetables": ["de": "Gemüse", "es": "Verduras", "fr": "Légumes", "it": "Verdure", "nl": "Groenten", "pl": "Warzywa", "pt": "Legumes"],
        "frozen fruits": ["de": "Tiefkühl-Früchte", "es": "Frutas congeladas", "fr": "Fruits surgelés", "it": "Frutta surgelata", "nl": "Diepvriesfruit", "pl": "Mrożone owoce", "pt": "Frutas congeladas"],
        "frozen vegetables": ["de": "Tiefkühl-Gemüse", "es": "Verduras congeladas", "fr": "Légumes surgelés", "it": "Verdure surgelate", "nl": "Diepvriesgroenten", "pl": "Mrożone warzywa", "pt": "Legumes congelados"],
        "canned fruits": ["de": "Obstkonserven", "es": "Frutas en conserva", "fr": "Fruits en conserve", "it": "Frutta in scatola", "nl": "Ingeblikt fruit", "pl": "Owoce w puszce", "pt": "Frutas em conserva"],
        "canned vegetables": ["de": "Gemüsekonserven", "es": "Verduras en conserva", "fr": "Légumes en conserve", "it": "Verdure in scatola", "nl": "Ingeblikte groenten", "pl": "Warzywa w puszce", "pt": "Legumes em conserva"],

        // Condiments & Sauces
        "sauces": ["de": "Soßen", "es": "Salsas", "fr": "Sauces", "it": "Salse", "nl": "Sauzen", "pl": "Sosy", "pt": "Molhos"],
        "condiments": ["de": "Gewürze", "es": "Condimentos", "fr": "Condiments", "it": "Condimenti", "nl": "Kruiden", "pl": "Przyprawy", "pt": "Condimentos"],
        "ketchup": ["de": "Ketchup", "es": "Ketchup", "fr": "Ketchup", "it": "Ketchup", "nl": "Ketchup", "pl": "Ketchup", "pt": "Ketchup"],
        "mayonnaise": ["de": "Mayonnaise", "es": "Mayonesa", "fr": "Mayonnaise", "it": "Maionese", "nl": "Mayonaise", "pl": "Majonez", "pt": "Maionese"],
        "mustard": ["de": "Senf", "es": "Mostaza", "fr": "Moutarde", "it": "Senape", "nl": "Mosterd", "pl": "Musztarda", "pt": "Mostarda"],
        "vinegar": ["de": "Essig", "es": "Vinagre", "fr": "Vinaigre", "it": "Aceto", "nl": "Azijn", "pl": "Ocet", "pt": "Vinagre"],
        "oils": ["de": "Öle", "es": "Aceites", "fr": "Huiles", "it": "Oli", "nl": "Oliën", "pl": "Oleje", "pt": "Óleos"],
        "olive oil": ["de": "Olivenöl", "es": "Aceite de oliva", "fr": "Huile d'olive", "it": "Olio d'oliva", "nl": "Olijfolie", "pl": "Oliwa z oliwek", "pt": "Azeite"],

        // Plant-based
        "plant-based foods": ["de": "Pflanzliche Lebensmittel", "es": "Alimentos vegetales", "fr": "Aliments végétaux", "it": "Alimenti vegetali", "nl": "Plantaardige voeding", "pl": "Żywność roślinna", "pt": "Alimentos vegetais"],
        "plant-based": ["de": "Pflanzlich", "es": "Vegetal", "fr": "Végétal", "it": "Vegetale", "nl": "Plantaardig", "pl": "Roślinne", "pt": "Vegetal"],
        "vegan": ["de": "Vegan", "es": "Vegano", "fr": "Végan", "it": "Vegano", "nl": "Veganistisch", "pl": "Wegańskie", "pt": "Vegano"],
        "vegetarian": ["de": "Vegetarisch", "es": "Vegetariano", "fr": "Végétarien", "it": "Vegetariano", "nl": "Vegetarisch", "pl": "Wegetariańskie", "pt": "Vegetariano"],
        "tofu": ["de": "Tofu", "es": "Tofu", "fr": "Tofu", "it": "Tofu", "nl": "Tofu", "pl": "Tofu", "pt": "Tofu"],

        // Baby Food
        "baby foods": ["de": "Babynahrung", "es": "Alimentos para bebés", "fr": "Alimentation bébé", "it": "Alimenti per bambini", "nl": "Babyvoeding", "pl": "Żywność dla niemowląt", "pt": "Alimentos para bebés"],

        // Other
        "groceries": ["de": "Lebensmittel", "es": "Comestibles", "fr": "Épicerie", "it": "Generi alimentari", "nl": "Boodschappen", "pl": "Artykuły spożywcze", "pt": "Mercearia"],
        "organic": ["de": "Bio", "es": "Orgánico", "fr": "Bio", "it": "Biologico", "nl": "Biologisch", "pl": "Ekologiczne", "pt": "Biológico"],
        "gluten-free": ["de": "Glutenfrei", "es": "Sin gluten", "fr": "Sans gluten", "it": "Senza glutine", "nl": "Glutenvrij", "pl": "Bezglutenowe", "pt": "Sem glúten"],
        "sugar-free": ["de": "Zuckerfrei", "es": "Sin azúcar", "fr": "Sans sucre", "it": "Senza zucchero", "nl": "Suikervrij", "pl": "Bez cukru", "pt": "Sem açúcar"],
    ]

    /// Translates a category name to the current locale
    static func translate(_ category: String) -> String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"

        // If already in English or no translation needed
        if languageCode == "en" {
            return category
        }

        // Look up translation
        let lowercased = category.lowercased()
        if let languageTranslations = translations[lowercased],
           let translated = languageTranslations[languageCode] {
            return translated
        }

        // Return original if no translation found
        return category
    }

    /// Translates an array of categories
    static func translate(_ categories: [String]) -> [String] {
        categories.map { translate($0) }
    }
}
