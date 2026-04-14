// InsightsView.swift
// MindCycle
//
// The Insights screen showing interactive charts, statistics,
// pattern analysis, and smart text insights.

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(PatternEngine.self) private var patternEngine
    @Query(sort: \CycleEntry.date, order: .reverse) private var entries: [CycleEntry]
    
    @State private var animateCards = false
    
    private var statistics: CycleStatistics {
        patternEngine.computeStatistics(from: entries)
    }
    
    private var prediction: PredictionResult? {
        patternEngine.predictNextWindow(from: entries)
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if entries.isEmpty {
                emptyState
            } else {
                VStack(spacing: MindCycleTheme.sectionSpacing) {
                    // MARK: - Header
                    header
                    
                    // MARK: - Smart Insight Text
                    insightBanner
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                    
                    // MARK: - Stats Overview
                    statsOverview
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                    
                    // MARK: - Charts Grid
                    chartsGrid
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                    
                    // MARK: - Phase Timeline
                    PhaseTimelineView(phases: statistics.phases)
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                }
                .padding(24)
            }
        }
        .background(MindCycleTheme.backgroundPrimary)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateCards = true
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Insights")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(MindCycleTheme.textPrimary)
            
            Text("Patterns and trends from your \(entries.count) logged entries")
                .font(.system(size: 14))
                .foregroundStyle(MindCycleTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Insight Banner
    
    private var insightBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(MindCycleTheme.accentWarm.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundStyle(MindCycleTheme.accentWarm)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Smart Insight")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MindCycleTheme.accentWarm)
                
                Text(patternEngine.generateInsightText(from: entries))
                    .font(.system(size: 13))
                    .foregroundStyle(MindCycleTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .glowingCard(color: MindCycleTheme.accentWarm, intensity: 0.12)
    }
    
    // MARK: - Stats Overview
    
    private var statsOverview: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Total Entries",
                value: "\(statistics.totalEntries)",
                icon: "list.bullet.clipboard",
                color: MindCycleTheme.accent
            )
            
            statCard(
                title: "Avg Cycle",
                value: statistics.averageCycleLength > 0 ? "\(Int(statistics.averageCycleLength.rounded()))d" : "—",
                icon: "arrow.triangle.2.circlepath",
                color: MindCycleTheme.accentCool
            )
            
            statCard(
                title: "Last Phase",
                value: statistics.lastPhaseDuration > 0 ? "\(statistics.lastPhaseDuration)d" : "—",
                icon: "clock",
                color: MindCycleTheme.accentWarm
            )
            
            statCard(
                title: "Phases",
                value: "\(statistics.phases.count)",
                icon: "chart.bar.xaxis",
                color: MindCycleTheme.both
            )
            
            statCard(
                title: "Deviation",
                value: statistics.standardDeviation > 0 ? "±\(Int(statistics.standardDeviation.rounded()))d" : "—",
                icon: "waveform.path.ecg",
                color: MindCycleTheme.positive
            )
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(MindCycleTheme.textPrimary)
            
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(MindCycleTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(color.opacity(0.1), lineWidth: 1)
                }
        }
    }
    
    // MARK: - Charts Grid
    
    private var chartsGrid: some View {
        VStack(spacing: 16) {
            // Row 1: Monthly + Intensity
            HStack(alignment: .top, spacing: 16) {
                MonthlyFrequencyChart(entries: entries, patternEngine: patternEngine)
                
                VStack(spacing: 16) {
                    IntensityDistributionChart(statistics: statistics)
                    TypeDistributionChart(statistics: statistics)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Row 2: Cycle length
            CycleLengthChart(
                cycleLengths: statistics.cycleLengths,
                averageCycleLength: statistics.averageCycleLength,
                standardDeviation: statistics.standardDeviation
            )
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 80)
            
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundStyle(MindCycleTheme.textTertiary)
            
            VStack(spacing: 8) {
                Text("No Insights Yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(MindCycleTheme.textPrimary)
                
                Text("Start logging entries to discover your patterns.\nThe more you log, the smarter the insights become.")
                    .font(.system(size: 14))
                    .foregroundStyle(MindCycleTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
