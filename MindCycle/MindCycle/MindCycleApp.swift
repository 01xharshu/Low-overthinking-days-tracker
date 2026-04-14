// MindCycleApp.swift
// MindCycle
//
// Main application entry point. Configures SwiftData model container
// and sets up the app window with calming dark theme.

import SwiftUI
import SwiftData

@main
struct MindCycleApp: App {
    
    /// Shared pattern engine for the app.
    @State private var patternEngine = PatternEngine()
    
    /// Notification manager instance.
    @State private var notificationManager = NotificationManager()
    
    /// SwiftData model container for local persistence.
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([CycleEntry.self])
            let modelConfiguration = ModelConfiguration(
                "MindCycleStore",
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(patternEngine)
                .environment(notificationManager)
                #if os(macOS)
                .frame(minWidth: 900, minHeight: 600)
                .background(MindCycleTheme.backgroundPrimary)
                #endif
        }
        .modelContainer(modelContainer)
        #if os(macOS)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1100, height: 720)
        .commands {
            // Custom menu commands
            CommandGroup(replacing: .newItem) {
                Button("New Entry") {
                    NotificationCenter.default.post(name: .newEntryShortcut, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandMenu("Data") {
                Button("Export as JSON…") {
                    NotificationCenter.default.post(name: .exportJSON, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                
                Button("Export as CSV…") {
                    NotificationCenter.default.post(name: .exportCSV, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .option])
            }
        }
        #endif
    }

}

// MARK: - Notification Names for Keyboard Shortcuts

extension Notification.Name {
    static let newEntryShortcut = Notification.Name("com.mindcycle.newEntry")
    static let exportJSON = Notification.Name("com.mindcycle.exportJSON")
    static let exportCSV = Notification.Name("com.mindcycle.exportCSV")
}
