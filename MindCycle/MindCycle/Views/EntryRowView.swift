// EntryRowView.swift
// MindCycle
//
// A compact, informative row view for displaying a single CycleEntry
// in lists, dashboards, and history views.

import SwiftUI

struct EntryRowView: View {
    let entry: CycleEntry
    var showFullDate: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Type indicator dot
            ZStack {
                Circle()
                    .fill(MindCycleTheme.color(for: entry.type).opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: entry.type.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(MindCycleTheme.color(for: entry.type))
            }
            
            // Entry info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.type.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MindCycleTheme.textPrimary)
                    
                    intensityBadge
                }
                
                HStack(spacing: 8) {
                    Text(showFullDate ? entry.formattedDateLong : relativeDate)
                        .font(.system(size: 11))
                        .foregroundStyle(MindCycleTheme.textTertiary)
                    
                    if let notes = entry.notes, !notes.isEmpty {
                        Text("•")
                            .foregroundStyle(MindCycleTheme.textTertiary)
                        
                        Text(notes)
                            .font(.system(size: 11))
                            .foregroundStyle(MindCycleTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Tags (compact)
            if !entry.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(entry.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(MindCycleTheme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background {
                                Capsule()
                                    .fill(MindCycleTheme.accent.opacity(0.1))
                            }
                    }
                    if entry.tags.count > 2 {
                        Text("+\(entry.tags.count - 2)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(MindCycleTheme.textTertiary)
                    }
                }
            }
            
            // Date column
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MindCycleTheme.textSecondary)
                
                Text(entry.dayOfWeek.prefix(3).description)
                    .font(.system(size: 10))
                    .foregroundStyle(MindCycleTheme.textTertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.02))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                }
        }
    }
    
    // MARK: - Components
    
    private var intensityBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: entry.intensity.icon)
                .font(.system(size: 8))
            Text(entry.intensity.rawValue)
                .font(.system(size: 9, weight: .semibold))
        }
        .foregroundStyle(MindCycleTheme.color(for: entry.intensity))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background {
            Capsule()
                .fill(MindCycleTheme.color(for: entry.intensity).opacity(0.12))
        }
    }
    
    private var relativeDate: String {
        let days = entry.daysAgo
        switch days {
        case 0: return "Today"
        case 1: return "Yesterday"
        default: return "\(days) days ago"
        }
    }
}
