//
//  MatchMateApp.swift
//  MatchMate
//

import SwiftUI
import SwiftData
import os

@main
@MainActor
struct MatchMateApp: App {

    private let container: ModelContainer
    private let environment: AppEnvironment

    init() {
        let container = Self.makeContainer()
        self.container = container
        self.environment = AppEnvironment(modelContainer: container)
    }

    var body: some Scene {
        WindowGroup {
            DiscoverView(viewModel: environment.makeDiscoverViewModel(), environment: environment)
        }
        .modelContainer(container)
    }

    /// Falls back to an in-memory store if the persistent one can't be opened (corruption,
    /// migration failure, disk issue) so the app still launches instead of crashing.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([ProfileEntity.self])
        do {
            return try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema))
        } catch {
            Log.app.error("Persistent store failed to load: \(error.localizedDescription). Using in-memory store.")
            do {
                return try ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                )
            } catch {
                fatalError("Failed to create even an in-memory ModelContainer: \(error)")
            }
        }
    }
}
