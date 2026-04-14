// MindCycleWidget.swift
// MindCycleWidget
//
// WidgetKit extension providing small, medium, and large widget families.
// Uses a TimelineProvider that reads cached data from a shared JSON file
// written by the main app via App Groups.

import WidgetKit
import SwiftUI

// MARK: - Widget Data (Shared via JSON file)

/// Lightweight snapshot of app state for the widget, stored as JSON.
struct WidgetData: Codable {
    let daysSinceLastEntry: Int
    let lastEntryDate: Date?
    let lastEntryType: String?
    let predictedWindowStart: Date?
    let predictedWindowEnd: Date?
    let predictedDaysUntil: Int?
    let confidenceLabel: String?
    let averageCycleLength: Int?
    let currentPhase: String
    let phaseDescription: String
    let totalEntries: Int
    let lastUpdated: Date
    
    static let empty = WidgetData(
        daysSinceLastEntry: 0,
        lastEntryDate: nil,
        lastEntryType: nil,
        predictedWindowStart: nil,
        predictedWindowEnd: nil,
        predictedDaysUntil: nil,
        confidenceLabel: nil,
        averageCycleLength: nil,
        currentPhase: "Gathering Data",
        phaseDescription: "Open MindCycle to start logging",
        totalEntries: 0,
        lastUpdated: .now
    )
    
    /// Reads widget data from the shared App Group container.
    static func load() -> WidgetData {
        // In production, use App Groups:
        // let containerURL = FileManager.default.containerURL(
        //     forSecurityApplicationGroupIdentifier: "group.com.mindcycle.shared"
        // )?.appendingPathComponent("widget_data.json")
        
        // For standalone use, read from app support
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MindCycle")
            .appendingPathComponent("widget_data.json")
        
        guard let url, FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return .empty
        }
        
        return decoded
    }
    
    /// Writes widget data to the shared location (called from main app).
    static func save(_ data: WidgetData) {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MindCycle")
        
        guard let dir else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        
        let url = dir.appendingPathComponent("widget_data.json")
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: url)
        }
    }
}

// MARK: - Timeline Entry

struct MindCycleEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Timeline Provider

struct MindCycleTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MindCycleEntry {
        MindCycleEntry(date: .now, data: .empty)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MindCycleEntry) -> Void) {
        let data = WidgetData.load()
        completion(MindCycleEntry(date: .now, data: data))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MindCycleEntry>) -> Void) {
        let data = WidgetData.load()
        let entry = MindCycleEntry(date: .now, data: data)
        
        // Refresh daily at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now))!
        
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}

// MARK: - Widget Definition

struct MindCycleWidget: Widget {
    let kind = "MindCycleWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MindCycleTimelineProvider()) { entry in
            MindCycleWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackground()
                }
        }
        .configurationDisplayName("MindCycle")
        .description("Track your emotional patterns at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Background

struct WidgetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.067, green: 0.071, blue: 0.106),
                Color(red: 0.098, green: 0.106, blue: 0.153),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Widget Colors (standalone, since Theme.swift is in main target)

private struct WidgetColors {
    static let accent = Color(red: 0.545, green: 0.502, blue: 0.957)
    static let accentWarm = Color(red: 0.698, green: 0.463, blue: 0.906)
    static let accentCool = Color(red: 0.396, green: 0.565, blue: 0.957)
    static let lowFeeling = Color(red: 0.361, green: 0.533, blue: 0.898)
    static let overthinking = Color(red: 0.725, green: 0.443, blue: 0.878)
    static let positive = Color(red: 0.396, green: 0.784, blue: 0.588)
    static let warning = Color(red: 0.957, green: 0.757, blue: 0.357)
    static let danger = Color(red: 0.918, green: 0.404, blue: 0.404)
    static let textPrimary = Color(red: 0.933, green: 0.937, blue: 0.969)
    static let textSecondary = Color(red: 0.600, green: 0.616, blue: 0.706)
    static let textTertiary = Color(red: 0.400, green: 0.416, blue: 0.506)
    static let cardBg = Color(red: 0.133, green: 0.145, blue: 0.200)
}

// MARK: - Widget View (Adaptive to Family)

struct MindCycleWidgetView: View {
    let entry: MindCycleEntry
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .systemLarge:
            largeWidget
        default:
            smallWidget
        }
    }
    
    // MARK: - Small Widget
    
    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WidgetColors.accent)
                
                Text("MindCycle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetColors.textSecondary)
            }
            
            Spacer()
            
            // Days since
            if entry.data.totalEntries > 0 {
                Text("\(entry.data.daysSinceLastEntry)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetColors.textPrimary)
                
                Text("days since last log")
                    .font(.system(size: 10))
                    .foregroundStyle(WidgetColors.textTertiary)
            } else {
                Text("Start\nTracking")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetColors.accent)
                
                Text("Open app to begin")
                    .font(.system(size: 10))
                    .foregroundStyle(WidgetColors.textTertiary)
            }
            
            Spacer()
            
            // Phase
            HStack(spacing: 4) {
                Circle()
                    .fill(phaseColor)
                    .frame(width: 6, height: 6)
                
                Text(entry.data.currentPhase)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(phaseColor)
                    .lineLimit(1)
            }
        }
        .padding(14)
    }
    
    // MARK: - Medium Widget
    
    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // Left: Days since
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 13))
                        .foregroundStyle(WidgetColors.accent)
                    
                    Text("MindCycle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WidgetColors.textSecondary)
                }
                
                Spacer()
                
                if entry.data.totalEntries > 0 {
                    Text("\(entry.data.daysSinceLastEntry)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetColors.textPrimary)
                    
                    Text("days since last log")
                        .font(.system(size: 11))
                        .foregroundStyle(WidgetColors.textTertiary)
                } else {
                    Text("No entries yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(WidgetColors.textSecondary)
                }
                
                Spacer()
            }
            
            // Divider
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white.opacity(0.08))
                .frame(width: 1)
                .padding(.vertical, 8)
            
            // Right: Prediction + Phase
            VStack(alignment: .leading, spacing: 8) {
                // Current phase
                HStack(spacing: 6) {
                    Circle()
                        .fill(phaseColor)
                        .frame(width: 8, height: 8)
                    
                    Text(entry.data.currentPhase)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(phaseColor)
                }
                
                Text(entry.data.phaseDescription)
                    .font(.system(size: 10))
                    .foregroundStyle(WidgetColors.textTertiary)
                    .lineLimit(2)
                
                Spacer()
                
                // Prediction
                if let daysUntil = entry.data.predictedDaysUntil {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next window")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(WidgetColors.textTertiary)
                        
                        HStack(spacing: 4) {
                            Text(daysUntil > 0 ? "in \(daysUntil) days" : "now")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(daysUntil <= 3 ? WidgetColors.warning : WidgetColors.accentCool)
                            
                            if let confidence = entry.data.confidenceLabel {
                                Text("• \(confidence)")
                                    .font(.system(size: 9))
                                    .foregroundStyle(WidgetColors.textTertiary)
                            }
                        }
                    }
                } else {
                    Text("Gathering pattern data…")
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetColors.textTertiary)
                        .italic()
                }
            }
        }
        .padding(14)
    }
    
    // MARK: - Large Widget
    
    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(WidgetColors.accent.opacity(0.2))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14))
                        .foregroundStyle(WidgetColors.accent)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("MindCycle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WidgetColors.textPrimary)
                    
                    Text("Your gentle companion")
                        .font(.system(size: 9))
                        .foregroundStyle(WidgetColors.textTertiary)
                }
                
                Spacer()
                
                Text("\(entry.data.totalEntries) entries")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(WidgetColors.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background {
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                    }
            }
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
            
            // Phase indicator
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(phaseColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: phaseIcon)
                        .font(.system(size: 16))
                        .foregroundStyle(phaseColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.data.currentPhase)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(phaseColor)
                    
                    Text(entry.data.phaseDescription)
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetColors.textTertiary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(phaseColor.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(phaseColor.opacity(0.1), lineWidth: 1)
                    }
            }
            
            // Stats row
            HStack(spacing: 12) {
                // Days since
                widgetStatCard(
                    title: "Days Since",
                    value: entry.data.totalEntries > 0 ? "\(entry.data.daysSinceLastEntry)" : "—",
                    color: WidgetColors.accentCool
                )
                
                // Next window
                widgetStatCard(
                    title: "Next Window",
                    value: entry.data.predictedDaysUntil.map { $0 > 0 ? "\($0)d" : "Now" } ?? "—",
                    color: WidgetColors.accentWarm
                )
                
                // Avg cycle
                widgetStatCard(
                    title: "Avg Cycle",
                    value: entry.data.averageCycleLength.map { "\($0)d" } ?? "—",
                    color: WidgetColors.accent
                )
            }
            
            Spacer()
            
            // Prediction detail
            if let start = entry.data.predictedWindowStart,
               let end = entry.data.predictedWindowEnd {
                let formatter = DateFormatter()
                let _ = formatter.dateFormat = "MMM d"
                
                HStack(spacing: 8) {
                    Image(systemName: "eye.trianglebadge.exclamationmark")
                        .font(.system(size: 12))
                        .foregroundStyle(WidgetColors.warning)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Predicted Window")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(WidgetColors.textSecondary)
                        
                        Text("\(formatter.string(from: start)) – \(formatter.string(from: end))")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(WidgetColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    if let confidence = entry.data.confidenceLabel {
                        Text(confidence)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(WidgetColors.positive)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background {
                                Capsule()
                                    .fill(WidgetColors.positive.opacity(0.12))
                            }
                    }
                }
                .padding(10)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(WidgetColors.cardBg.opacity(0.5))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.04), lineWidth: 1)
                        }
                }
            }
            
            // Footer
            HStack {
                Text("Updated \(entry.data.lastUpdated.formatted(.relative(presentation: .named)))")
                    .font(.system(size: 8))
                    .foregroundStyle(WidgetColors.textTertiary)
                
                Spacer()
            }
        }
        .padding(14)
    }
    
    // MARK: - Widget Stat Card
    
    private func widgetStatCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            
            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(WidgetColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.opacity(0.06))
        }
    }
    
    // MARK: - Phase Helpers
    
    private var phaseColor: Color {
        switch entry.data.currentPhase {
        case "Recovery Phase": return WidgetColors.positive
        case "Stable Period": return WidgetColors.accentCool
        case "Low Window Approaching": return WidgetColors.warning
        case "In Low Window": return WidgetColors.danger
        default: return WidgetColors.textTertiary
        }
    }
    
    private var phaseIcon: String {
        switch entry.data.currentPhase {
        case "Recovery Phase": return "leaf.fill"
        case "Stable Period": return "sun.max.fill"
        case "Low Window Approaching": return "cloud.sun.fill"
        case "In Low Window": return "cloud.rain.fill"
        default: return "questionmark.circle"
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    MindCycleWidget()
} timeline: {
    MindCycleEntry(date: .now, data: WidgetData(
        daysSinceLastEntry: 5,
        lastEntryDate: Calendar.current.date(byAdding: .day, value: -5, to: .now),
        lastEntryType: "Low Feeling",
        predictedWindowStart: Calendar.current.date(byAdding: .day, value: 12, to: .now),
        predictedWindowEnd: Calendar.current.date(byAdding: .day, value: 15, to: .now),
        predictedDaysUntil: 12,
        confidenceLabel: "High",
        averageCycleLength: 28,
        currentPhase: "Stable Period",
        phaseDescription: "Things are steady",
        totalEntries: 15,
        lastUpdated: .now
    ))
}

#Preview("Medium", as: .systemMedium) {
    MindCycleWidget()
} timeline: {
    MindCycleEntry(date: .now, data: WidgetData(
        daysSinceLastEntry: 3,
        lastEntryDate: Calendar.current.date(byAdding: .day, value: -3, to: .now),
        lastEntryType: "Overthinking",
        predictedWindowStart: Calendar.current.date(byAdding: .day, value: 4, to: .now),
        predictedWindowEnd: Calendar.current.date(byAdding: .day, value: 7, to: .now),
        predictedDaysUntil: 4,
        confidenceLabel: "Moderate",
        averageCycleLength: 25,
        currentPhase: "Low Window Approaching",
        phaseDescription: "A low window may be approaching. Prepare your support strategies.",
        totalEntries: 22,
        lastUpdated: .now
    ))
}

#Preview("Large", as: .systemLarge) {
    MindCycleWidget()
} timeline: {
    MindCycleEntry(date: .now, data: WidgetData(
        daysSinceLastEntry: 1,
        lastEntryDate: Calendar.current.date(byAdding: .day, value: -1, to: .now),
        lastEntryType: "Both",
        predictedWindowStart: Calendar.current.date(byAdding: .day, value: 0, to: .now),
        predictedWindowEnd: Calendar.current.date(byAdding: .day, value: 3, to: .now),
        predictedDaysUntil: 0,
        confidenceLabel: "High",
        averageCycleLength: 30,
        currentPhase: "Recovery Phase",
        phaseDescription: "You're in a recovery period. Take it easy and be gentle with yourself.",
        totalEntries: 45,
        lastUpdated: .now
    ))
}
