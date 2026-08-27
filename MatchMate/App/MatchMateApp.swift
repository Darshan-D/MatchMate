//
//  MatchMateApp.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import SwiftUI
import SwiftData

@main
struct MatchMateApp: App {
    let container: ModelContainer = {
        let schema = Schema([ProfileEntity.self])

        do {
            let config = ModelConfiguration(schema: schema)
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            // Persistent store failed to load (corruption, migration failure, disk issue).
            // Fall back to an in-memory container so the app still launches and functions
            // for this session, rather than crashing outright.
            print("⚠️ [WARN][MatchMateApp] Failed to load persistent ModelContainer: \(error). Falling back to in-memory store.")

            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            guard let fallbackContainer = try? ModelContainer(for: schema, configurations: fallbackConfig) else {
                // If even an in-memory container fails, something is fundamentally wrong
                // with the schema itself — this is a programmer error, not a runtime
                // condition, so failing loudly here is appropriate.
                fatalError("❌ [ERROR][MatchMateApp] Failed to create even an in-memory ModelContainer: \(error)")
            }
            return fallbackContainer
        }
    }()

    var body: some Scene {
        WindowGroup {
            MatchListView(
                viewModel: AppComposition.makeMatchListViewModel(context: container.mainContext)
            )
        }
        .modelContainer(container)
    }
}
