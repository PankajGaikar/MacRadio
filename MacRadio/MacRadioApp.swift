//
//  MacRadioApp.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import SwiftUI
import SwiftData
import RadioBrowserKit

@main
struct MacRadioApp: App {
    init() {
        // Configure RadioBrowserKit logging
        RadioBrowserKit.configuration = RadioBrowserConfig(
            logging: LogConfiguration(
                enabled: [.network, .mirrors, .api, .decode, .general],
                minLevel: .debug,
                redactPII: false,
                emitCURL: true
            )
        )
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FavoriteStation.self,
            RecentStation.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(modelContext: sharedModelContainer.mainContext)
        }
        .modelContainer(sharedModelContainer)
    }
}
