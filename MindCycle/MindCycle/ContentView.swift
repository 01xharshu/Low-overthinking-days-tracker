// ContentView.swift
// MindCycle
//
// Root view with NavigationSplitView providing the sidebar navigation
// and detail content area. Handles keyboard shortcut routing.

import SwiftUI
import SwiftData

// MARK: - Navigation Destination

/// Sidebar navigation destinations.
enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case logEntry = "Log Entry"
    case history = "History"
    case insights = "Insights"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "heart.text.square"
        case .logEntry: return "plus.circle"
        case .history: return "clock.arrow.circlepath"
        case .insights: return "chart.xyaxis.line"
        case .settings: return "gearshape"
        }
    }
    
    var description: String {
        switch self {
        case .dashboard: return "Overview of your patterns"
        case .logEntry: return "Record how you're feeling"
        case .history: return "Browse past entries"
        case .insights: return "Charts and analysis"
        case .settings: return "Preferences and data"
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var selectedItem: NavigationItem? = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CycleEntry.date, order: .reverse) private var entries: [CycleEntry]
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $selectedItem)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(MindCycleTheme.backgroundPrimary)
        }
        .navigationSplitViewStyle(.balanced)
        .onReceive(NotificationCenter.default.publisher(for: .newEntryShortcut)) { _ in
            withAnimation(.spring(response: 0.3)) {
                selectedItem = .logEntry
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportJSON)) { _ in
            DataExporter.export(entries: entries, format: .json)
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportCSV)) { _ in
            DataExporter.export(entries: entries, format: .csv)
        }
    }
    
    // MARK: - Detail View Router
    
    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .dashboard:
            DashboardView(navigateToLog: {
                withAnimation(.spring(response: 0.3)) {
                    selectedItem = .logEntry
                }
            })
        case .logEntry:
            LogEntryView()
        case .history:
            HistoryView()
        case .insights:
            InsightsView()
        case .settings:
            SettingsView()
        case .none:
            DashboardView(navigateToLog: {
                withAnimation(.spring(response: 0.3)) {
                    selectedItem = .logEntry
                }
            })
        }
    }
}
