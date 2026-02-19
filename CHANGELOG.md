# Changelog

All notable changes to Scanora will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-02-19

### Changed

#### Navigation Redesign
- **Dashboard Home Screen** - Replaced tab-based navigation with a central home dashboard
- **Hero Scan Button** - Prominent scan button at the top of the home screen
- **Quick Stats** - Display of total scans, favorites count, and today's scan count
- **Recent Scans** - Shows last 5 scanned products on home screen
- **Favorites Section** - Quick access to favorited products on home screen
- **Full-Screen Scanner** - Scanner now opens as fullScreenCover overlay instead of tab
- **Improved Flow** - "Done" button returns to home dashboard instead of scanner camera

#### User Experience
- After scanning a product, tapping "Done" returns to the home dashboard
- All navigation flows through home screen (History, Search, Settings)
- HistoryListView now supports filtering to show favorites only

### Fixed
- German localization now displays correctly for all new UI strings
- ProductDetailView navigation works properly with NavigationStack

---

## [0.1.0] - 2026-02-19

### Added

#### Core Features
- **Barcode Scanner** - AVFoundation-based scanner supporting EAN-13, EAN-8, and UPC-E barcodes
- **Product Lookup** - Integration with Open Food Facts API v2 for product information
- **Product Details** - Display of nutritional information, allergens, ingredients, and origin
- **Scan History** - Persistent history of scanned products with search and favorites
- **Product Search** - Manual search for products by name or brand
- **Offline Caching** - SwiftData-based caching with 7-day TTL for offline access
- **Product Contribution** - In-app flow to add missing products to Open Food Facts

#### Health & Safety Information
- **Nutri-Score Display** - Color-coded A-E nutritional quality badges
- **NOVA Group Display** - Food processing level indicators (1-4)
- **Eco-Score Display** - Environmental impact badges
- **Allergen Warnings** - Prominent display of all 14 EU mandatory allergens
- **Trace Warnings** - "May contain" allergen information

#### User Interface
- **Tab Navigation** - Scan, History, Search, Settings tabs
- **Scanner Overlay** - Animated viewfinder with scanning line
- **Torch Control** - Flashlight toggle for low-light scanning
- **Manual Barcode Entry** - Keyboard input for damaged barcodes
- **Dark/Light Mode** - System appearance support

#### Localization
- **24 EU Languages** - Full allergen translations for all official EU languages
- **8 Priority Languages** - Complete UI translations for:
  - English, Portuguese, Spanish, French
  - German, Italian, Dutch, Polish
- **Dynamic Language Selection** - In-app language switcher

#### Product Contribution Features
- **Photo Capture** - Camera and photo library integration
- **OCR Text Extraction** - Vision framework for automatic ingredient text recognition
- **Multi-Image Upload** - Front, ingredients, and nutrition label photos
- **Form Validation** - Required field checking before submission

### Technical Details

#### Architecture
- SwiftUI with MVVM pattern
- Async/await for all networking
- SwiftData for persistence
- AVFoundation for camera/barcode scanning
- Vision framework for OCR

#### Models (7 files)
- `OFFProductResponse.swift` - API response DTOs
- `Product.swift` - Core domain model
- `NutriScore.swift` - Health score enums (NutriScore, NovaGroup, EcoScore)
- `Allergen.swift` - 14 EU allergens with multilingual parsing
- `Nutriments.swift` - Nutritional data with daily value calculations
- `Ingredient.swift` - Ingredient model with dietary flags
- `CachedProduct.swift` / `ScanHistory.swift` - SwiftData models

#### Services (7 files)
- `NetworkService.swift` - Generic HTTP client with rate limiting
- `OpenFoodFactsAPI.swift` - OFF API client with barcode validation
- `ProductContributionAPI.swift` - Product submission and image upload
- `BarcodeScannerService.swift` - AVFoundation camera management
- `ProductCacheService.swift` - Cache CRUD operations
- `ScanHistoryService.swift` - History management

#### Views (12 files)
- Scanner: `ScannerView`, `ScannerOverlayView`
- Product: `ProductDetailView`, `NutriScoreBadge`, `AllergenWarningView`
- History: `HistoryListView`
- Search: `SearchView`
- Settings: `SettingsView`
- Contribute: `ContributeProductView`
- Common: `LoadingView`, `ErrorView`
- Navigation: `MainTabView`

### Dependencies
- None (pure SwiftUI/Swift)

### Requirements
- iOS 26.2+
- Xcode 16+
- Physical device for camera features

---

## Future Releases

### Planned for [0.2.0]
- Allergen profile (personal allergen warnings)
- Shopping list integration
- Widget for quick scanning

### Planned for [0.3.0]
- Advanced OCR with ML for automatic field extraction
- Product comparison feature
- Apple Watch companion app
