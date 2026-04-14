// DashboardView.swift
// MindCycle
//
// The main dashboard showing at-a-glance summary: days since last entry,
// predicted window, current phase, and quick log button.

import SwiftUI
import SwiftData

struct DashboardView: View {
    let navigateToLog: () -> Void
    
    @Environment(PatternEngine.self) private var patternEngine
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CycleEntry.date, order: .reverse) private var entries: [CycleEntry]
    
    @State private var animateCards = false
    
    private var statistics: CycleStatistics {
        patternEngine.computeStatistics(from: entries)
    }
    
    private var prediction: PredictionResult? {
        patternEngine.predictNextWindow(from: entries)
    }
    
    private var phase: CyclePhase {
        patternEngine.currentPhase(from: entries)
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MindCycleTheme.sectionSpacing) {
                // MARK: - Greeting Header
                greetingHeader
                
                // MARK: - Quick Stats Row
                if !entries.isEmpty {
                    HStack(spacing: 16) {
                        DaysSinceCard(daysSince: statistics.daysSinceLastEntry ?? 0)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                        
                        PredictionCard(prediction: prediction)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                        
                        PhaseCard(phase: phase, entries: entries, prediction: prediction)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                    }
                }
                
                // MARK: - Quick Log & Insight
                HStack(spacing: 16) {
                    quickLogCard
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                    
                    if !entries.isEmpty {
                        insightCard
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                    }
                }
                
                // MARK: - Recent Entries
                if !entries.isEmpty {
                    recentEntries
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                }
                
                // MARK: - Empty State
                if entries.isEmpty {
                    emptyState
                }
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateCards = true
            }
            // Schedule notification if predictions available
            if let prediction {
                notificationManager.scheduleNotification(for: prediction)
            }
        }
    }
    
    // MARK: - Greeting Header
    
    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greetingText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(MindCycleTheme.textPrimary)
            
            Text(motivationalText)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(MindCycleTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Quick Log Card
    
    private var quickLogCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(MindCycleTheme.accent)
                
                Text("Quick Log")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MindCycleTheme.textPrimary)
                
                Spacer()
            }
            
            Text("How are you feeling today? Take a moment to check in with yourself.")
                .font(.system(size: 12))
                .foregroundStyle(MindCycleTheme.textSecondary)
                .lineLimit(3)
            
            Button(action: navigateToLog) {
                HStack(spacing: 8) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 14))
                    Text("Log Today")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background {
                    Capsule()
                        .fill(MindCycleTheme.mainGradient)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Log today's entry")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glowingCard(color: MindCycleTheme.accent, intensity: 0.15)
    }
    
    // MARK: - Insight Card
    
    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundStyle(MindCycleTheme.accentWarm)
                
                Text("Insight")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MindCycleTheme.textPrimary)
                
                Spacer()
            }
            
            Text(patternEngine.generateInsightText(from: entries))
                .font(.system(size: 12))
                .foregroundStyle(MindCycleTheme.textSecondary)
                .lineLimit(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mindCycleCard()
    }
    
    // MARK: - Recent Entries
    
    private var recentEntries: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Entries")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MindCycleTheme.textPrimary)
                
                Spacer()
                
                Text("Last 5")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MindCycleTheme.textTertiary)
            }
            
            VStack(spacing: 8) {
                ForEach(Array(entries.prefix(5))) { entry in
                    EntryRowView(entry: entry)
                }
            }
        }
        .mindCycleCard()
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)
            
            ZStack {
                Circle()
                    .fill(MindCycleTheme.accent.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 36))
                    .foregroundStyle(MindCycleTheme.accent)
            }
            
            VStack(spacing: 8) {
                Text("Welcome to MindCycle")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(MindCycleTheme.textPrimary)
                
                Text("Your gentle mental health companion.\nStart by logging your first entry to begin tracking patterns.")
                    .font(.system(size: 14))
                    .foregroundStyle(MindCycleTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            Button(action: navigateToLog) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Your First Entry")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background {
                    Capsule()
                        .fill(MindCycleTheme.mainGradient)
                        .shadow(color: MindCycleTheme.accent.opacity(0.4), radius: 16, y: 4)
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Helpers
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good Morning ☀️"
        case 12..<17: return "Good Afternoon 🌤"
        case 17..<21: return "Good Evening 🌅"
        default: return "Good Night 🌙"
        }
    }
    
    private var motivationalText: String {
        let texts = [
            "Every day you track is a step toward self-understanding.",
            "Awareness is the first step to change.",
            "You're doing great by showing up for yourself.",
            "Patterns reveal paths — keep going.",
            "Gentle awareness, powerful results.",
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        return texts[dayOfYear % texts.count]
    }
}
