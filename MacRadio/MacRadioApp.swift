//
//  MacRadioApp.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import SwiftUI
import SwiftData
import RadioBrowserKit
import AppKit

@main
struct MacRadioApp: App {
    @StateObject private var menuBarManager = MenuBarManager()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let windowDelegate = WindowDelegate()
    
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
                .environmentObject(menuBarManager)
                .background(WindowAccessor(delegate: windowDelegate))
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About MacRadio") {
                    NSApp.orderFrontStandardAboutPanel(nil)
                }
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}

// App Delegate to handle window closing
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app alive when window is closed
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup app behavior after app is fully launched
        // Don't terminate app when last window is closed
        NSApp.setActivationPolicy(.regular)
    }
}

// Settings view
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        Form {
            Section("Behavior") {
                Text("MacRadio will stay running in the menu bar when you close the window.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
