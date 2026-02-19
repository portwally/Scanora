# Scanora - Food Barcode Scanner App

## Context
Building a barcode scanning app that provides food product information (ingredients, origin, nutritional data, allergens) for the EU market, starting with Portugal. The app uses Open Food Facts as the primary data source, which has strong EU coverage and supports multiple languages. The project is a fresh Xcode template ready for implementation.

## Architecture Overview
- **Platform**: iOS 26.2+ with SwiftUI
- **Pattern**: MVVM with async/await
- **Data Source**: Open Food Facts API v2
- **Persistence**: SwiftData for offline caching
- **Scanner**: AVFoundation (native barcode scanning)
- **Localization**: All major EU languages (24 official languages)

## Project Structure
```
Scanora/
├── App/                    # App entry, configuration
├── Models/
│   ├── API/                # DTOs matching OFF API response
│   ├── Domain/             # Clean domain models (Product, Allergen, NutriScore)
│   └── Persistence/        # SwiftData @Model classes
├── Services/
│   ├── Networking/         # NetworkService, OpenFoodFactsAPI
│   ├── Scanner/            # BarcodeScannerService (AVFoundation)
│   └── Persistence/        # Cache & history services
├── ViewModels/             # ScannerVM, ProductDetailVM, HistoryVM
├── Views/
│   ├── Scanner/            # Camera preview, overlay, permissions
│   ├── Product/            # Detail view, NutriScore badge, allergens
│   ├── History/            # Scan history list
│   ├── Search/             # Product search
│   ├── Settings/           # App settings, language selection
│   └── Common/             # LoadingView, ErrorView, EmptyState
├── Utilities/              # Extensions, helpers, constants
└── Resources/
    ├── Localizable.xcstrings   # All EU language translations
    └── Assets.xcassets
```

## EU Language Support

### Supported Languages (24 Official EU Languages)
| Code | Language | Priority |
|------|----------|----------|
| pt | Portuguese | Primary |
| en | English | High |
| es | Spanish | High |
| fr | French | High |
| de | German | High |
| it | Italian | High |
| nl | Dutch | Medium |
| pl | Polish | Medium |
| ro | Romanian | Medium |
| el | Greek | Medium |
| cs | Czech | Medium |
| sv | Swedish | Medium |
| hu | Hungarian | Medium |
| bg | Bulgarian | Low |
| da | Danish | Low |
| fi | Finnish | Low |
| sk | Slovak | Low |
| lt | Lithuanian | Low |
| lv | Latvian | Low |
| sl | Slovenian | Low |
| et | Estonian | Low |
| hr | Croatian | Low |
| ga | Irish | Low |
| mt | Maltese | Low |

### Localization Strategy
1. **String Catalogs** (Localizable.xcstrings) - Xcode native, type-safe
2. **Open Food Facts Language Support** - API returns localized product names per language code
3. **Allergen Names** - 14 EU mandatory allergens translated for each language
4. **Dynamic Language Switching** - Users can change app language in Settings
5. **Fallback Chain**: User's language → English → Raw API text

### What Gets Localized
- All UI labels and buttons
- Error messages and recovery suggestions
- Allergen names (14 EU mandatory)
- NutriScore/NOVA descriptions
- Settings and help text
- Placeholder text
- Accessibility labels

## Implementation Phases

### Phase 1: Foundation
1. Create folder structure
2. Implement API DTOs (`OFFProductResponse`, `OFFProductDTO`, `OFFNutrimentsDTO`)
3. Create domain models (`Product`, `NutriScore`, `NovaGroup`, `Allergen`, `Nutriments`)
4. Build networking layer (`NetworkService`, `OpenFoodFactsAPI`, rate limiter)
5. Add error types (`NetworkError`, `ScannerError`)

### Phase 2: Barcode Scanner
1. Implement `BarcodeScannerService` with AVFoundation
   - Support EAN-13, EAN-8, UPC-E barcodes
   - Camera permission handling
   - Torch control
2. Create `ScannerView` with camera preview
3. Add scanning overlay UI with viewfinder
4. Build `ScannerViewModel` connecting scanner → API → UI

### Phase 3: Product Display
1. `ProductDetailView` - main product info screen
2. `NutriScoreBadge` - color-coded A-E score display
3. `NovaGroupBadge` - processing level indicator (1-4)
4. `AllergenWarningView` - prominent allergen display with icons
5. `IngredientsView` - ingredient list with highlighting
6. `NutrimentsView` - nutrition facts table (per 100g)

### Phase 4: Persistence & History
1. SwiftData models (`CachedProduct`, `ScanHistory`)
2. `ProductCacheService` - fetch/save cached products
3. `ScanHistoryService` - track scanned products
4. Offline-first: check cache before API call
5. Cache TTL: 7 days for product data

### Phase 5: Navigation & Settings ✅ REDESIGNED
**Changed from tab-based to dashboard-centric navigation:**

1. `HomeView` - Dashboard home screen with:
   - Hero scan button (prominent, centered)
   - Quick stats (total scans, favorites, today count)
   - Recent scans list (last 5)
   - Favorites section (last 3)
   - Search button
   - Settings gear in navigation bar

2. `HomeViewModel` - Dashboard data provider:
   - Fetches recent scans and favorites
   - Calculates stats (totalScans, favoritesCount, todayCount)

3. `MainTabView` - Now just wraps HomeView (no tabs)

4. Navigation Flow:
   ```
   HomeView (Root)
   ├─ Scan Button → ScannerView (fullScreenCover)
   │   └─ Product Found → ProductDetailView (push)
   │       └─ Done → Pop to Home
   ├─ Recent/Favorite Row → ProductDetailView (push)
   ├─ "See All" Recent → HistoryListView (push)
   ├─ "See All" Favorites → HistoryListView (filtered)
   ├─ Search Button → SearchView (push)
   └─ Settings Gear → SettingsView (push)
   ```

5. `HistoryListView` - Now supports `showFavoritesOnly` parameter
6. `ProductDetailView` - Uses NavigationStack pop (not dismiss)
7. `SettingsView` - language selection, cache management, about

### Phase 6: Product Contribution
1. `ContributeProductView` - form for missing products
2. Photo capture for front, ingredients, nutrition labels
3. `OpenFoodFactsContributionAPI` - upload product data
4. Basic OCR with Vision framework for text extraction hints
5. Success confirmation and immediate display of contributed product

### Phase 7: Localization
1. Set up Localizable.xcstrings with all strings
2. Export for translation (high-priority languages first)
3. Implement language selection in Settings
4. Test RTL support (for future Arabic/Hebrew if needed)
5. Verify all screens in multiple languages

## Key Technical Details

### Open Food Facts API
- **Base URL**: `https://world.openfoodfacts.org/api/v2/product/{barcode}.json`
- **Localized URL**: `https://{lang}.openfoodfacts.org/api/v2/product/{barcode}.json`
- **Language Param**: `?lc={lang}` for localized responses
- **Rate Limit**: 100 requests/minute
- **User-Agent**: Required, format: `Scanora/1.0 (contact@scanora.app)`
- **Localized Fields**: `product_name_{lang}`, `ingredients_text_{lang}`

### Open Food Facts Contribution API
- **Write Endpoint**: `https://world.openfoodfacts.org/cgi/product_jqm2.pl`
- **Required Fields**: barcode, product_name, brands
- **Image Upload**: POST with `imgupload_front`, `imgupload_ingredients`, `imgupload_nutrition`
- **Auth**: Anonymous contributions allowed (with user agent)

### Barcode Types
- **EAN-13**: Most common in EU (13 digits)
- **EAN-8**: Smaller packages (8 digits)
- **UPC-E**: Compressed UPC (auto-expand to check)

## Files to Create (in order)

### Models
1. [Models/API/OFFProductResponse.swift](Scanora/Models/API/OFFProductResponse.swift) - API DTOs
2. [Models/Domain/Product.swift](Scanora/Models/Domain/Product.swift) - Core product model
3. [Models/Domain/NutriScore.swift](Scanora/Models/Domain/NutriScore.swift) - Health scores
4. [Models/Domain/Allergen.swift](Scanora/Models/Domain/Allergen.swift) - EU allergens enum
5. [Models/Domain/Nutriments.swift](Scanora/Models/Domain/Nutriments.swift) - Nutrition data
6. [Models/Domain/Ingredient.swift](Scanora/Models/Domain/Ingredient.swift) - Ingredient model
7. [Models/Persistence/CachedProduct.swift](Scanora/Models/Persistence/CachedProduct.swift) - SwiftData model
8. [Models/Persistence/ScanHistory.swift](Scanora/Models/Persistence/ScanHistory.swift) - History model

### Services
9. [Services/Networking/NetworkError.swift](Scanora/Services/Networking/NetworkError.swift) - Error types
10. [Services/Networking/APIEndpoint.swift](Scanora/Services/Networking/APIEndpoint.swift) - Endpoint definitions
11. [Services/Networking/NetworkService.swift](Scanora/Services/Networking/NetworkService.swift) - HTTP layer
12. [Services/Networking/OpenFoodFactsAPI.swift](Scanora/Services/Networking/OpenFoodFactsAPI.swift) - OFF client
13. [Services/Scanner/BarcodeScannerService.swift](Scanora/Services/Scanner/BarcodeScannerService.swift) - AVFoundation
14. [Services/Persistence/ProductCacheService.swift](Scanora/Services/Persistence/ProductCacheService.swift) - Cache ops
15. [Services/Persistence/ScanHistoryService.swift](Scanora/Services/Persistence/ScanHistoryService.swift) - History ops

### Views & ViewModels
16. [ViewModels/ScannerViewModel.swift](Scanora/ViewModels/ScannerViewModel.swift) - Scanner logic
17. [ViewModels/ProductDetailViewModel.swift](Scanora/ViewModels/ProductDetailViewModel.swift) - Product logic
18. [ViewModels/HistoryViewModel.swift](Scanora/ViewModels/HistoryViewModel.swift) - History logic
19. [ViewModels/SearchViewModel.swift](Scanora/ViewModels/SearchViewModel.swift) - Search logic
20. [ViewModels/HomeViewModel.swift](Scanora/ViewModels/HomeViewModel.swift) - Dashboard stats & data ✅
21. [Views/Home/HomeView.swift](Scanora/Views/Home/HomeView.swift) - Dashboard home screen ✅
22. [Views/Scanner/ScannerView.swift](Scanora/Views/Scanner/ScannerView.swift) - Camera UI
23. [Views/Scanner/ScannerOverlayView.swift](Scanora/Views/Scanner/ScannerOverlayView.swift) - Viewfinder overlay
24. [Views/Product/ProductDetailView.swift](Scanora/Views/Product/ProductDetailView.swift) - Product info
25. [Views/Product/NutriScoreBadge.swift](Scanora/Views/Product/NutriScoreBadge.swift) - Score display
26. [Views/Product/AllergenWarningView.swift](Scanora/Views/Product/AllergenWarningView.swift) - Allergen UI
27. [Views/History/HistoryListView.swift](Scanora/Views/History/HistoryListView.swift) - History list
28. [Views/Search/SearchView.swift](Scanora/Views/Search/SearchView.swift) - Search UI
29. [Views/Settings/SettingsView.swift](Scanora/Views/Settings/SettingsView.swift) - Settings
30. [Views/Contribute/ContributeProductView.swift](Scanora/Views/Contribute/ContributeProductView.swift) - Add product
31. [Views/MainTabView.swift](Scanora/Views/MainTabView.swift) - Home wrapper (no tabs)
32. [Views/Common/ErrorView.swift](Scanora/Views/Common/ErrorView.swift) - Error states
33. [Views/Common/LoadingView.swift](Scanora/Views/Common/LoadingView.swift) - Loading states

### Resources
34. [Resources/Localizable.xcstrings](Scanora/Resources/Localizable.xcstrings) - All translations

## Verification Plan
1. **Unit Tests**: NetworkService, API response parsing, barcode validation
2. **Manual Testing**:
   - Scan real products from various EU countries
   - Test offline mode (airplane mode after caching)
   - Verify text displays correctly in multiple languages
   - Test language switching
3. **Edge Cases**:
   - Product not found in database → show contribution flow
   - Network timeout/unavailable → use cached data or show error
   - Camera permission denied → guide to settings
   - Invalid/damaged barcode → helpful error message

## Future Enhancements (Post-MVP)
- Advanced OCR with ML for automatic field extraction
- Allergen profile (personal allergen warnings)
- Shopping list integration
- Comparison between similar products
- Widget for quick scanning
- Apple Watch companion app
