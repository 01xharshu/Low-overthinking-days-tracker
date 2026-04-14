// PatternEngine.swift
// MindCycle
//
// Analyzes logged data to detect patterns, calculate cycle lengths,
// and predict upcoming low/overthinking windows.

import Foundation
import SwiftData

// MARK: - Cycle Phase

/// Represents the user's current phase relative to their cycle.
enum CyclePhase: String {
    case recovery = "Recovery Phase"
    case stable = "Stable Period"
    case approaching = "Low Window Approaching"
    case inLowWindow = "In Low Window"
    case unknown = "Gathering Data"
    
    var icon: String {
        switch self {
        case .recovery: return "leaf.fill"
        case .stable: return "sun.max.fill"
        case .approaching: return "cloud.sun.fill"
        case .inLowWindow: return "cloud.rain.fill"
        case .unknown: return "questionmark.circle"
        }
    }
    
    var description: String {
        switch self {
        case .recovery: return "You're in a recovery period. Take it easy and be gentle with yourself."
        case .stable: return "Things are steady. A good time to build resilience."
        case .approaching: return "A low window may be approaching. Prepare your support strategies."
        case .inLowWindow: return "You may be in a low window. Remember: this is temporary."
        case .unknown: return "Keep logging to help me learn your patterns."
        }
    }
}

// MARK: - Prediction Result

/// Holds a predicted upcoming low window.
struct PredictionResult {
    let startDate: Date
    let endDate: Date
    let confidence: Double   // 0.0 – 1.0
    let averageCycleLength: Double
    let standardDeviation: Double
    
    var confidenceLabel: String {
        switch confidence {
        case 0.7...1.0: return "High"
        case 0.4..<0.7: return "Moderate"
        default: return "Low"
        }
    }
    
    var formattedWindow: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate))–\(formatter.string(from: endDate))"
    }
    
    var daysUntilStart: Int {
        max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: startDate).day ?? 0)
    }
}

// MARK: - Phase Info

/// A detected contiguous phase (cluster) of logged days.
struct PhaseInfo {
    let startDate: Date
    let endDate: Date
    let entries: [CycleEntry]
    
    var duration: Int {
        (Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1
    }
    
    var averageIntensity: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.intensity.numericValue).reduce(0, +)) / Double(entries.count)
    }
    
    var dominantType: EntryType {
        let lowCount = entries.filter { $0.type == .lowFeeling || $0.type == .both }.count
        let overCount = entries.filter { $0.type == .overthinking || $0.type == .both }.count
        if lowCount > overCount { return .lowFeeling }
        if overCount > lowCount { return .overthinking }
        return .both
    }
}

// MARK: - Cycle Statistics

/// Summary statistics computed from all entries.
struct CycleStatistics {
    let totalEntries: Int
    let averageCycleLength: Double
    let standardDeviation: Double
    let lastPhaseDuration: Int
    let lastPhaseStart: Date?
    let lastPhaseEnd: Date?
    let lowFeelingCount: Int
    let overthinkingCount: Int
    let bothCount: Int
    let mildCount: Int
    let moderateCount: Int
    let severeCount: Int
    let phases: [PhaseInfo]
    let cycleLengths: [Int]
    
    var averageIntensity: Double {
        guard totalEntries > 0 else { return 0 }
        let total = Double(mildCount * 1 + moderateCount * 2 + severeCount * 3)
        return total / Double(totalEntries)
    }
    
    var daysSinceLastEntry: Int? {
        guard let lastDate = phases.last?.endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: .now).day
    }
}

// MARK: - Pattern Engine

/// The core analysis engine that processes entries and generates insights.
@Observable
final class PatternEngine {
    
    // MARK: - Configuration
    
    /// Maximum gap (in days) between entries to consider them part of the same phase.
    private let phaseGapThreshold: Int = 3
    
    /// Minimum number of cycles needed for meaningful predictions.
    private let minimumCyclesForPrediction: Int = 2
    
    // MARK: - Public Analysis Methods
    
    /// Detect contiguous phases from sorted entries.
    func detectPhases(from entries: [CycleEntry]) -> [PhaseInfo] {
        let sorted = entries.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return [] }
        
        var phases: [PhaseInfo] = []
        var currentPhaseEntries: [CycleEntry] = [sorted[0]]
        
        for i in 1..<sorted.count {
            let daysBetween = Calendar.current.dateComponents(
                [.day],
                from: sorted[i - 1].date,
                to: sorted[i].date
            ).day ?? 0
            
            if daysBetween <= phaseGapThreshold {
                // Same phase – extend
                currentPhaseEntries.append(sorted[i])
            } else {
                // New phase - save current and start new
                let phase = PhaseInfo(
                    startDate: currentPhaseEntries.first!.date,
                    endDate: currentPhaseEntries.last!.date,
                    entries: currentPhaseEntries
                )
                phases.append(phase)
                currentPhaseEntries = [sorted[i]]
            }
        }
        
        // Don't forget the last phase
        if !currentPhaseEntries.isEmpty {
            let phase = PhaseInfo(
                startDate: currentPhaseEntries.first!.date,
                endDate: currentPhaseEntries.last!.date,
                entries: currentPhaseEntries
            )
            phases.append(phase)
        }
        
        return phases
    }
    
    /// Calculate cycle lengths (gaps between phase starts).
    func calculateCycleLengths(from phases: [PhaseInfo]) -> [Int] {
        guard phases.count >= 2 else { return [] }
        
        var lengths: [Int] = []
        for i in 1..<phases.count {
            let days = Calendar.current.dateComponents(
                [.day],
                from: phases[i - 1].startDate,
                to: phases[i].startDate
            ).day ?? 0
            if days > 0 {
                lengths.append(days)
            }
        }
        return lengths
    }
    
    /// Compute full statistics from entries.
    func computeStatistics(from entries: [CycleEntry]) -> CycleStatistics {
        let phases = detectPhases(from: entries)
        let cycleLengths = calculateCycleLengths(from: phases)
        
        let avgCycle = cycleLengths.isEmpty ? 0.0 : Double(cycleLengths.reduce(0, +)) / Double(cycleLengths.count)
        let stdDev = calculateStandardDeviation(cycleLengths)
        
        let lastPhase = phases.last
        
        return CycleStatistics(
            totalEntries: entries.count,
            averageCycleLength: avgCycle,
            standardDeviation: stdDev,
            lastPhaseDuration: lastPhase?.duration ?? 0,
            lastPhaseStart: lastPhase?.startDate,
            lastPhaseEnd: lastPhase?.endDate,
            lowFeelingCount: entries.filter { $0.type == .lowFeeling }.count,
            overthinkingCount: entries.filter { $0.type == .overthinking }.count,
            bothCount: entries.filter { $0.type == .both }.count,
            mildCount: entries.filter { $0.intensity == .mild }.count,
            moderateCount: entries.filter { $0.intensity == .moderate }.count,
            severeCount: entries.filter { $0.intensity == .severe }.count,
            phases: phases,
            cycleLengths: cycleLengths
        )
    }
    
    /// Predict the next low window based on historical patterns.
    func predictNextWindow(from entries: [CycleEntry]) -> PredictionResult? {
        let phases = detectPhases(from: entries)
        let cycleLengths = calculateCycleLengths(from: phases)
        
        guard cycleLengths.count >= minimumCyclesForPrediction,
              let lastPhase = phases.last else {
            return nil
        }
        
        let avgCycle = Double(cycleLengths.reduce(0, +)) / Double(cycleLengths.count)
        let stdDev = calculateStandardDeviation(cycleLengths)
        
        // Average phase duration for window width
        let avgPhaseDuration = Double(phases.map(\.duration).reduce(0, +)) / Double(phases.count)
        
        // Predicted start = last phase start + average cycle length
        let predictedStart = Calendar.current.date(
            byAdding: .day,
            value: Int(avgCycle.rounded()),
            to: lastPhase.startDate
        ) ?? lastPhase.startDate
        
        // Predicted end = start + average phase duration
        let predictedEnd = Calendar.current.date(
            byAdding: .day,
            value: max(1, Int(avgPhaseDuration.rounded()) - 1),
            to: predictedStart
        ) ?? predictedStart
        
        // Confidence based on consistency of cycle lengths
        let confidence = calculateConfidence(stdDev: stdDev, avgCycle: avgCycle, dataPoints: cycleLengths.count)
        
        return PredictionResult(
            startDate: predictedStart,
            endDate: predictedEnd,
            confidence: confidence,
            averageCycleLength: avgCycle,
            standardDeviation: stdDev
        )
    }
    
    /// Determine the current cycle phase.
    func currentPhase(from entries: [CycleEntry]) -> CyclePhase {
        guard !entries.isEmpty else { return .unknown }
        
        let sorted = entries.sorted { $0.date < $1.date }
        guard let lastEntry = sorted.last else { return .unknown }
        
        let daysSinceLast = Calendar.current.dateComponents([.day], from: lastEntry.date, to: .now).day ?? 0
        
        // Check if currently in a low window  (logged today or yesterday)
        if daysSinceLast <= 1 {
            return .inLowWindow
        }
        
        // Check prediction
        if let prediction = predictNextWindow(from: entries) {
            let daysUntil = prediction.daysUntilStart
            
            if daysUntil <= 0 {
                return .inLowWindow
            } else if daysUntil <= 5 {
                return .approaching
            } else if daysSinceLast <= 7 {
                return .recovery
            } else {
                return .stable
            }
        }
        
        // Fallback based on recency
        if daysSinceLast <= 5 {
            return .recovery
        }
        return .stable
    }
    
    /// Generate a natural language insight summary.
    func generateInsightText(from entries: [CycleEntry]) -> String {
        let stats = computeStatistics(from: entries)
        
        guard stats.totalEntries > 0 else {
            return "Start logging your days to uncover patterns. Even a few entries can reveal useful insights."
        }
        
        var insights: [String] = []
        
        // Last phase info
        if stats.lastPhaseDuration > 0, let start = stats.lastPhaseStart {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            insights.append("Last low phase lasted \(stats.lastPhaseDuration) day\(stats.lastPhaseDuration == 1 ? "" : "s") (starting \(formatter.string(from: start))).")
        }
        
        // Cycle length
        if stats.averageCycleLength > 0 {
            let dev = Int(stats.standardDeviation.rounded())
            insights.append("Average cycle: \(Int(stats.averageCycleLength.rounded())) days (±\(dev) days).")
        }
        
        // Prediction
        if let prediction = predictNextWindow(from: entries) {
            insights.append("Next expected low window: \(prediction.formattedWindow) with \(prediction.confidenceLabel.lowercased()) confidence.")
        }
        
        // Type distribution
        let dominant: String
        if stats.lowFeelingCount > stats.overthinkingCount {
            dominant = "low feeling"
        } else if stats.overthinkingCount > stats.lowFeelingCount {
            dominant = "overthinking"
        } else {
            dominant = "both low feeling and overthinking equally"
        }
        insights.append("You tend to experience \(dominant) more frequently.")
        
        return insights.joined(separator: " ")
    }
    
    // MARK: - Monthly Aggregation for Charts
    
    /// Group entries by month and return counts for each type.
    func monthlyBreakdown(from entries: [CycleEntry], months: Int = 6) -> [(month: Date, lowCount: Int, overthinkingCount: Int, bothCount: Int)] {
        let calendar = Calendar.current
        let now = Date.now
        
        var result: [(month: Date, lowCount: Int, overthinkingCount: Int, bothCount: Int)] = []
        
        for i in (0..<months).reversed() {
            guard let monthStart = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            let components = calendar.dateComponents([.year, .month], from: monthStart)
            guard let normalizedMonth = calendar.date(from: components) else { continue }
            
            let monthEntries = entries.filter {
                let entryComponents = calendar.dateComponents([.year, .month], from: $0.date)
                return entryComponents.year == components.year && entryComponents.month == components.month
            }
            
            let lowCount = monthEntries.filter { $0.type == .lowFeeling }.count
            let overCount = monthEntries.filter { $0.type == .overthinking }.count
            let bothCount = monthEntries.filter { $0.type == .both }.count
            
            result.append((month: normalizedMonth, lowCount: lowCount, overthinkingCount: overCount, bothCount: bothCount))
        }
        
        return result
    }
    
    // MARK: - Private Helpers
    
    /// Calculate standard deviation for an array of integers.
    private func calculateStandardDeviation(_ values: [Int]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = Double(values.reduce(0, +)) / Double(values.count)
        let squaredDiffs = values.map { pow(Double($0) - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
    
    /// Calculate prediction confidence based on cycle regularity.
    private func calculateConfidence(stdDev: Double, avgCycle: Double, dataPoints: Int) -> Double {
        guard avgCycle > 0 else { return 0 }
        
        // Coefficient of variation (lower = more regular = higher confidence)
        let cv = stdDev / avgCycle
        
        // Base confidence from regularity (CV < 0.1 = very regular)
        var confidence = max(0, 1.0 - cv * 2)
        
        // Boost for more data points (diminishing returns)
        let dataBoost = min(0.2, Double(dataPoints) * 0.05)
        confidence = min(1.0, confidence + dataBoost)
        
        return confidence
    }
}
