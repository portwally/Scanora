import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [CachedProduct.self, ScanHistory.self], inMemory: true)
}
