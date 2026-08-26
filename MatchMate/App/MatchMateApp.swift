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
    // Setup our SwiftData container
    let container: ModelContainer = {
        let schema = Schema([ProfileEntity.self]) // ProfileEntity to be built in Phase 2
        return try! ModelContainer(for: schema)
    }()

    var body: some Scene {
        WindowGroup {
            MatchListView(
                viewModel: AppComposition.makeMatchListViewModel(context: container.mainContext)
            )
        }
        .modelContainer(container) // Injects the ModelContext into the environment
    }
}
