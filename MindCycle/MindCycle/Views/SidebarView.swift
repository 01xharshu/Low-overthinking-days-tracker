// SidebarView.swift
// MindCycle
//
// The sidebar navigation with calming design, phase indicator, and navigation items.

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selection: NavigationItem?
    
    @Environment(PatternEngine.self) private var patternEngine
    @Query(sort: \CycleEntry.date, order: .reverse) private var entries: [CycleEntry]
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - App Header
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            Divider()
                .overlay(Color.white.opacity(0.06))
            
            // MARK: - Phase Indicator
            phaseIndicator
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            
            Divider()
                .overlay(Color.white.opacity(0.06))
            
            // MARK: - Navigation Items
            VStack(spacing: 4) {
                ForEach(NavigationItem.allCases) { item in
                    sidebarButton(for: item)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            Spacer()
            
            // MARK: - Entry Count
            footerView
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .background(MindCycleTheme.backgroundSecondary)
        #if os(macOS)
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 260)
        #endif
    }

    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 10) {
            // Animated logo
            ZStack {
                Circle()
                    .fill(MindCycleTheme.accent.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MindCycleTheme.accent)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text("MindCycle")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(MindCycleTheme.textPrimary)
                
                Text("Your gentle companion")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(MindCycleTheme.textTertiary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Phase Indicator
    
    private var phaseIndicator: some View {
        let phase = patternEngine.currentPhase(from: entries)
        
        return HStack(spacing: 8) {
            Image(systemName: phase.icon)
                .font(.system(size: 13))
                .foregroundStyle(phaseColor(for: phase))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(phase.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MindCycleTheme.textPrimary)
                
                Text(phase == .unknown ? "Log entries to begin" : phaseSubtext(for: phase))
                    .font(.system(size: 10))
                    .foregroundStyle(MindCycleTheme.textTertiary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(phaseColor(for: phase).opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(phaseColor(for: phase).opacity(0.15), lineWidth: 1)
                }
        }
    }
    
    // MARK: - Sidebar Button
    
    private func sidebarButton(for item: NavigationItem) -> some View {
        let isSelected = selection == item
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selection = item
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? MindCycleTheme.accent : MindCycleTheme.textSecondary)
                    .frame(width: 22)
                
                Text(item.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? MindCycleTheme.textPrimary : MindCycleTheme.textSecondary)
                
                Spacer()
                
                if item == .history {
                    Text("\(entries.count)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(MindCycleTheme.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(Color.white.opacity(0.06))
                        }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(MindCycleTheme.accent.opacity(0.12))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.rawValue)
        .accessibilityHint(item.description)
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        VStack(spacing: 4) {
            Divider()
                .overlay(Color.white.opacity(0.06))
            
            HStack {
                Text("v1.0")
                    .font(.system(size: 10))
                    .foregroundStyle(MindCycleTheme.textTertiary)
                
                Spacer()
                
                Text("\(entries.count) entries")
                    .font(.system(size: 10))
                    .foregroundStyle(MindCycleTheme.textTertiary)
            }
            .padding(.top, 6)
        }
    }
    
    // MARK: - Helpers
    
    private func phaseColor(for phase: CyclePhase) -> Color {
        switch phase {
        case .recovery: return MindCycleTheme.positive
        case .stable: return MindCycleTheme.accentCool
        case .approaching: return MindCycleTheme.warning
        case .inLowWindow: return MindCycleTheme.danger
        case .unknown: return MindCycleTheme.textTertiary
        }
    }
    
    private func phaseSubtext(for phase: CyclePhase) -> String {
        if let prediction = patternEngine.predictNextWindow(from: entries) {
            let days = prediction.daysUntilStart
            if days > 0 {
                return "\(days) day\(days == 1 ? "" : "s") until next window"
            } else {
                return "Predicted window active"
            }
        }
        
        if let daysSince = patternEngine.computeStatistics(from: entries).daysSinceLastEntry {
            return "\(daysSince) day\(daysSince == 1 ? "" : "s") since last log"
        }
        
        return ""
    }
}
