// DashboardCards.swift
// MindCycle
//
// Reusable dashboard stat cards: Days Since, Prediction, Phase indicator.

import SwiftUI

// MARK: - Days Since Card

struct DaysSinceCard: View {
    let daysSince: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14))
                    .foregroundStyle(MindCycleTheme.accentCool)
                
                Text("Days Since")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MindCycleTheme.textSecondary)
                
                Spacer()
            }
            
            AnimatedNumberView(daysSince, suffix: "", color: MindCycleTheme.textPrimary)
            
            Text(daysSince == 0 ? "Logged today" : daysSince == 1 ? "day ago" : "days ago")
                .font(.system(size: 11))
                .foregroundStyle(MindCycleTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mindCycleCard()
    }
}

// MARK: - Prediction Card

struct PredictionCard: View {
    let prediction: PredictionResult?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "eye.trianglebadge.exclamationmark")
                    .font(.system(size: 14))
                    .foregroundStyle(MindCycleTheme.accentWarm)
                
                Text("Next Window")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MindCycleTheme.textSecondary)
                
                Spacer()
            }
            
            if let prediction {
                if prediction.daysUntilStart > 0 {
                    AnimatedNumberView(prediction.daysUntilStart, suffix: "", color: warningColor(for: prediction.daysUntilStart))
                    
                    Text("days • \(prediction.formattedWindow)")
                        .font(.system(size: 11))
                        .foregroundStyle(MindCycleTheme.textTertiary)
                } else {
                    Text("Now")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(MindCycleTheme.warning)
                    
                    Text(prediction.formattedWindow)
                        .font(.system(size: 11))
                        .foregroundStyle(MindCycleTheme.textTertiary)
                }
                
                // Confidence badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(confidenceColor(prediction.confidence))
                        .frame(width: 6, height: 6)
                    
                    Text("\(prediction.confidenceLabel) confidence")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(MindCycleTheme.textTertiary)
                }
            } else {
                Text("—")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(MindCycleTheme.textTertiary)
                
                Text("Need more data")
                    .font(.system(size: 11))
                    .foregroundStyle(MindCycleTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mindCycleCard()
    }
    
    private func warningColor(for days: Int) -> Color {
        switch days {
        case 0...3: return MindCycleTheme.danger
        case 4...7: return MindCycleTheme.warning
        default: return MindCycleTheme.positive
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.7...1.0: return MindCycleTheme.positive
        case 0.4..<0.7: return MindCycleTheme.warning
        default: return MindCycleTheme.danger
        }
    }
}

// MARK: - Phase Card

struct PhaseCard: View {
    let phase: CyclePhase
    let entries: [CycleEntry]
    let prediction: PredictionResult?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: phase.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(phaseColor)
                
                Text("Current Phase")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MindCycleTheme.textSecondary)
                
                Spacer()
            }
            
            Text(phase.rawValue)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(phaseColor)
            
            Text(phase.description)
                .font(.system(size: 11))
                .foregroundStyle(MindCycleTheme.textTertiary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            
            if let prediction {
                HStack(spacing: 4) {
                    Text("Avg cycle:")
                        .font(.system(size: 10))
                        .foregroundStyle(MindCycleTheme.textTertiary)
                    Text("\(Int(prediction.averageCycleLength.rounded()))d")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(MindCycleTheme.textSecondary)
                    Text("±\(Int(prediction.standardDeviation.rounded()))d")
                        .font(.system(size: 10))
                        .foregroundStyle(MindCycleTheme.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glowingCard(color: phaseColor, intensity: 0.12)
    }
    
    private var phaseColor: Color {
        switch phase {
        case .recovery: return MindCycleTheme.positive
        case .stable: return MindCycleTheme.accentCool
        case .approaching: return MindCycleTheme.warning
        case .inLowWindow: return MindCycleTheme.danger
        case .unknown: return MindCycleTheme.textTertiary
        }
    }
}
