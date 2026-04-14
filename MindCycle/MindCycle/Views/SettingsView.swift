// SettingsView.swift
// MindCycle
//
// Settings screen with notification preferences, data export,
// clear data, and app information.

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager
    @Query(sort: \CycleEntry.date, order: .reverse) private var entries: [CycleEntry]
    
    @State private var showClearConfirmation = false
    @State private var showExportSuccess = false
    @State private var selectedExportFormat: DataExporter.ExportFormat = .json
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MindCycleTheme.sectionSpacing) {
                // Header
                header
                
                HStack(alignment: .top, spacing: 20) {
                    // Left column
                    VStack(spacing: 20) {
                        notificationSection
                        dataManagementSection
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right column
                    VStack(spacing: 20) {
                        exportSection
                        aboutSection
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
        .background(MindCycleTheme.backgroundPrimary)
        .alert("Clear All Data?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all \(entries.count) entries. This action cannot be undone.")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(MindCycleTheme.textPrimary)
            
            Text("Customize your MindCycle experience")
                .font(.system(size: 14))
                .foregroundStyle(MindCycleTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Notifications Section
    
    @ViewBuilder
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Notifications", icon: "bell.badge", color: MindCycleTheme.accentWarm)
            
            // Enable toggle
            settingsToggle(
                title: "Predicted Window Alerts",
                subtitle: "Get notified when a low window is approaching",
                icon: "bell.fill",
                isOn: Binding(
                    get: { notificationManager.notificationsEnabled },
                    set: { notificationManager.notificationsEnabled = $0 }
                )
            )
            
            if notificationManager.notificationsEnabled {
                // Reminder days
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Remind me")
                            .font(.system(size: 13))
                            .foregroundStyle(MindCycleTheme.textSecondary)
                        
                        Picker("", selection: Binding(
                            get: { notificationManager.reminderDaysBefore },
                            set: { notificationManager.reminderDaysBefore = $0 }
                        )) {
                            ForEach(1...7, id: \.self) { days in
                                Text("\(days) day\(days == 1 ? "" : "s") before")
                                    .tag(days)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 160)
                    }
                    
                    if !notificationManager.isAuthorized {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 11))
                            Text("Notifications not authorized. Please enable in System Settings.")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(MindCycleTheme.warning)
                        .padding(8)
                        .background {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(MindCycleTheme.warning.opacity(0.08))
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .mindCycleCard()
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Export Data", icon: "square.and.arrow.up", color: MindCycleTheme.accentCool)
            
            Text("Export your MindCycle data for backup or analysis.")
                .font(.system(size: 12))
                .foregroundStyle(MindCycleTheme.textSecondary)
            
            VStack(spacing: 10) {
                exportButton(format: .json, icon: "doc.text", description: "Structured data format, easy to re-import")
                exportButton(format: .csv, icon: "tablecells", description: "Spreadsheet compatible (Excel, Sheets)")
            }
            
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                Text("\(entries.count) entries ready to export")
                    .font(.system(size: 11))
            }
            .foregroundStyle(MindCycleTheme.textTertiary)
        }
        .mindCycleCard()
    }
    
    private func exportButton(format: DataExporter.ExportFormat, icon: String, description: String) -> some View {
        Button {
            DataExporter.export(entries: entries, format: format)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(MindCycleTheme.accentCool.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(MindCycleTheme.accentCool)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Export as \(format.rawValue)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MindCycleTheme.textPrimary)
                    
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundStyle(MindCycleTheme.textTertiary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(MindCycleTheme.accentCool)
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.02))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
        .disabled(entries.isEmpty)
        .opacity(entries.isEmpty ? 0.5 : 1)
    }
    
    // MARK: - Data Management Section
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Data Management", icon: "externaldrive", color: MindCycleTheme.danger)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clear All Data")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(MindCycleTheme.textPrimary)
                        
                        Text("Permanently delete all entries and start fresh")
                            .font(.system(size: 11))
                            .foregroundStyle(MindCycleTheme.textTertiary)
                    }
                    
                    Spacer()
                    
                    Button {
                        showClearConfirmation = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MindCycleTheme.danger)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background {
                            Capsule()
                                .stroke(MindCycleTheme.danger.opacity(0.3), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(entries.isEmpty)
                    .opacity(entries.isEmpty ? 0.5 : 1)
                }
                
                // Storage info
                HStack(spacing: 6) {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 11))
                    Text("All data stored locally on your Mac • \(entries.count) entries")
                        .font(.system(size: 11))
                }
                .foregroundStyle(MindCycleTheme.textTertiary)
            }
        }
        .mindCycleCard()
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("About MindCycle", icon: "brain.head.profile", color: MindCycleTheme.accent)
            
            VStack(alignment: .leading, spacing: 12) {
                aboutRow("Version", value: "1.0.0")
                aboutRow("Build", value: "1")
                aboutRow("Platform", value: "macOS 14+")
                aboutRow("Data Storage", value: "Local Only (SwiftData)")
                aboutRow("Privacy", value: "No data leaves your device")
            }
            
            Divider().overlay(Color.white.opacity(0.06))
            
            VStack(alignment: .leading, spacing: 6) {
                Text("MindCycle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MindCycleTheme.textPrimary)
                
                Text("A gentle mental health companion for understanding your emotional patterns. Track low days and overthinking cycles to build self-awareness and resilience.")
                    .font(.system(size: 12))
                    .foregroundStyle(MindCycleTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Keyboard shortcuts
            Divider().overlay(Color.white.opacity(0.06))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Keyboard Shortcuts")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MindCycleTheme.textSecondary)
                
                shortcutRow("New Entry", shortcut: "⌘N")
                shortcutRow("Export JSON", shortcut: "⇧⌘E")
                shortcutRow("Export CSV", shortcut: "⌥⌘E")
                shortcutRow("Save Entry", shortcut: "⌘↵")
            }
        }
        .mindCycleCard()
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MindCycleTheme.textPrimary)
        }
    }
    
    private func settingsToggle(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(MindCycleTheme.accentWarm.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(MindCycleTheme.accentWarm)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MindCycleTheme.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(MindCycleTheme.textTertiary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(MindCycleTheme.accentWarm)
        }
    }
    
    private func aboutRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(MindCycleTheme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(MindCycleTheme.textPrimary)
        }
    }
    
    private func shortcutRow(_ action: String, shortcut: String) -> some View {
        HStack {
            Text(action)
                .font(.system(size: 11))
                .foregroundStyle(MindCycleTheme.textTertiary)
            
            Spacer()
            
            Text(shortcut)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(MindCycleTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                }
        }
    }
    
    private func clearAllData() {
        for entry in entries {
            modelContext.delete(entry)
        }
        notificationManager.removeAllPending()
    }
}
