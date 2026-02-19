import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [Product] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var errorMessage: String?
    @State private var selectedProduct: Product?

    private let api = OpenFoodFactsAPI()

    var body: some View {
        NavigationStack {
            Group {
                if !hasSearched && searchResults.isEmpty {
                    SearchPromptView()
                } else if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && hasSearched {
                    ContentUnavailableView {
                        Label("No Results", systemImage: "magnifyingglass")
                    } description: {
                        Text("No products found for \"\(searchText)\"")
                    }
                } else {
                    List(searchResults) { product in
                        SearchResultRow(product: product)
                            .onTapGesture {
                                selectedProduct = product
                            }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search products by name or brand"
            )
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty {
                    searchResults = []
                    hasSearched = false
                }
            }
            .alert("Search Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let message = errorMessage {
                    Text(message)
                }
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailView(product: product) {
                    selectedProduct = nil
                }
            }
        }
    }

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isSearching = true
        hasSearched = true
        errorMessage = nil

        Task {
            do {
                searchResults = try await api.searchProducts(query: query)
            } catch {
                errorMessage = error.localizedDescription
            }
            isSearching = false
        }
    }
}

// MARK: - Search Prompt View

struct SearchPromptView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Search Products")
                .font(.title2.bold())

            Text("Search by product name, brand, or category")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                SearchSuggestion(text: "Nutella", icon: "sparkles")
                SearchSuggestion(text: "Organic milk", icon: "leaf")
                SearchSuggestion(text: "Gluten-free bread", icon: "star")
            }
            .padding(.top)
        }
        .padding()
    }
}

struct SearchSuggestion: View {
    let text: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(text)
                .foregroundColor(.secondary)
        }
        .font(.subheadline)
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            // Product image
            AsyncImage(url: product.imageThumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                }
            }
            .frame(width: 60, height: 60)

            // Product info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)

                if let brand = product.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    if let nutriScore = product.nutriScore {
                        NutriScoreBadgeCompact(score: nutriScore)
                    }

                    if let quantity = product.quantity {
                        Text(quantity)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    SearchView()
}
