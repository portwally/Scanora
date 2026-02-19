//
//  ScanoraApp.swift
//  Scanora
//
//  Created by Walter Tengler on 19/02/2026.
//

import SwiftUI
import SwiftData

@main
struct ScanoraApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                CachedProduct.self,
                ScanHistory.self,
                ShoppingListItem.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(modelContainer)
    }
}
