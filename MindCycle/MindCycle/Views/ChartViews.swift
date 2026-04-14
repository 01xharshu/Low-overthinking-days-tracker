// ChartViews.swift
// MindCycle
//
// Interactive Swift Charts components for the Insights screen:
// - Monthly frequency area chart
// - Intensity distribution bar chart  
// - Cycle length trend chart
// - Phase timeline view

import SwiftUI
import Charts

// MARK: - Chart Data Models

struct MonthlyChartData: Identifiable {
    let id = UUID()
    let month: Date
    let count: Int
    let type: String
    
    var monthLabel: String {
        month.formatted(.dateTime.month(.abbreviated))
    }
}

struct IntensityChartData: Identifiable {
    let id = UUID()
    let intensity: String
    let count: Int
    let color: Color
}

struct CycleLengthData: Identifiable {
    let id = UUID()
    let cycleNumber: Int
    let length: Int
}

// MARK: - Monthly Frequency Chart

struct MonthlyFrequencyChart: View {
    let entries: [CycleEntry]
    let patternEngine: PatternEngine
    
    @State private var selectedMonth: Date? = nil
    @State private var selectedType: String? = nil
    
    private var chartData: [MonthlyChartData] {
        let breakdown = patternEngine.monthlyBreakdown(from: entries, months: 6)
        var data: [MonthlyChartData] = []
        
        for item in breakdown {
            data.append(MonthlyChartData(month: item.month, count: item.lowCount, type: "Low Feeling"))
            data.append(MonthlyChartData(month: item.month, count: item.overthinkingCount, type: "Overthinking"))
            data.append(MonthlyChartData(month: item.month, count: item.bothCount, type: "Both"))
        }
        
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Frequency")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MindCycleTheme.textPrimary)
                    
                    Text("Entry count by type over the last 6 months")
                        .font(.system(size: 11))
                        .foregroundStyle(MindCycleTheme.textTertiary)
                }
                
                Spacer()
                
                // Legend
                HStack(spacing: 12) {
                    legendItem("Low", color: MindCycleTheme.lowFeeling)
                    legendItem("Over", color: MindCycleTheme.overthinking)
                    legendItem("Both", color: MindCycleTheme.both)
                }
            }
            
            Chart(chartData) { item in
                AreaMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(by: .value("Type", item.type))
                .interpolationMethod(.catmullRom)
                .opacity(0.3)
                
                LineMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(by: .value("Type", item.type))
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                PointMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(by: .value("Type", item.type))
                .symbolSize(item.count > 0 ? 30 : 0)
            }
            .chartForegroundStyleScale([
                "Low Feeling": MindCycleTheme.lowFeeling,
                "Overthinking": MindCycleTheme.overthinking,
                "Both": MindCycleTheme.both
            ])
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .foregroundStyle(MindCycleTheme.textTertiary)
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.04))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(MindCycleTheme.textTertiary)
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.04))
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                if let date: Date = proxy.value(atX: location.x) {
                                    selectedMonth = date
                                }
                            case .ended:
                                selectedMonth = nil
                            }
                        }
                }
            }
            .frame(height: 220)
            
            // Tooltip
            if let selected = selectedMonth {
                let cal = Calendar.current
                let monthEntries = entries.filter {
                    cal.isDate($0.date, equalTo: selected, toGranularity: .month)
                }
                if !monthEntries.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundStyle(MindCycleTheme.accent)
                        
                        Text("\(selected.formatted(.dateTime.month(.wide).year())): \(monthEntries.count) entries")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(MindCycleTheme.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(MindCycleTheme.accent.opacity(0.1))
                    }
                    .transition(.opacity)
                }
            }
        }
        .mindCycleCard()
    }
    
    private func legendItem(_ label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(MindCycleTheme.textTertiary)
        }
    }
}

// MARK: - Intensity Distribution Chart

struct IntensityDistributionChart: View {
    let statistics: CycleStatistics
    
    @State private var selectedBar: String? = nil
    
    private var chartData: [IntensityChartData] {
        [
            IntensityChartData(intensity: "Mild", count: statistics.mildCount, color: MindCycleTheme.mildIntensity),
            IntensityChartData(intensity: "Moderate", count: statistics.moderateCount, color: MindCycleTheme.moderateIntensity),
            IntensityChartData(intensity: "Severe", count: statistics.severeCount, color: MindCycleTheme.severeIntensity),
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Intensity Distribution")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MindCycleTheme.textPrimary)
                
                Text("How intense your logged days tend to be")
                    .font(.system(size: 11))
                    .foregroundStyle(MindCycleTheme.textTertiary)
            }
            
            Chart(chartData) { item in
                BarMark(
                    x: .value("Intensity", item.intensity),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(item.color.gradient)
                .cornerRadius(6)
                .annotation(position: .top, spacing: 4) {
                    if item.count > 0 {
                        Text("\(item.count)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(item.color)
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(MindCycleTheme.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(MindCycleTheme.textTertiary)
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.04))
                }
            }
            .frame(height: 180)
            
            // Average intensity text
            HStack(spacing: 6) {
                Image(systemName: "gauge.with.dots.needle.50percent")
                    .font(.system(size: 11))
                    .foregroundStyle(MindCycleTheme.accentWarm)
                
                Text("Average intensity: \(String(format: "%.1f", statistics.averageIntensity))/3.0")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MindCycleTheme.textSecondary)
            }
        }
        .mindCycleCard()
    }
}

// MARK: - Cycle Length Chart

struct CycleLengthChart: View {
    let cycleLengths: [Int]
    let averageCycleLength: Double
    let standardDeviation: Double
    
    private var chartData: [CycleLengthData] {
        cycleLengths.enumerated().map { index, length in
            CycleLengthData(cycleNumber: index + 1, length: length)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Cycle Length Trend")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MindCycleTheme.textPrimary)
                
                Text("Days between the start of each low phase")
                    .font(.system(size: 11))
                    .foregroundStyle(MindCycleTheme.textTertiary)
            }
            
            if chartData.isEmpty {
                Text("Need at least 2 phases to calculate cycle lengths")
                    .font(.system(size: 12))
                    .foregroundStyle(MindCycleTheme.textTertiary)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    // Average line
                    RuleMark(y: .value("Average", averageCycleLength))
                        .foregroundStyle(MindCycleTheme.accent.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("avg: \(Int(averageCycleLength.rounded()))d")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(MindCycleTheme.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background {
                                    Capsule()
                                        .fill(MindCycleTheme.accent.opacity(0.1))
                                }
                        }
                    
                    // Deviation band
                    if standardDeviation > 0 {
                        RectangleMark(
                            yStart: .value("Lower", max(0, averageCycleLength - standardDeviation)),
                            yEnd: .value("Upper", averageCycleLength + standardDeviation)
                        )
                        .foregroundStyle(MindCycleTheme.accent.opacity(0.06))
                    }
                    
                    // Data points
                    ForEach(chartData) { item in
                        LineMark(
                            x: .value("Cycle", item.cycleNumber),
                            y: .value("Days", item.length)
                        )
                        .foregroundStyle(MindCycleTheme.accentCool)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        PointMark(
                            x: .value("Cycle", item.cycleNumber),
                            y: .value("Days", item.length)
                        )
                        .foregroundStyle(MindCycleTheme.accentCool)
                        .symbolSize(40)
                        .annotation(position: .top, spacing: 4) {
                            Text("\(item.length)d")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(MindCycleTheme.textSecondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("C\(intValue)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(MindCycleTheme.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .foregroundStyle(MindCycleTheme.textTertiary)
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.04))
                    }
                }
                .frame(height: 180)
                
                HStack(spacing: 16) {
                    statBadge(label: "Average", value: "\(Int(averageCycleLength.rounded()))d", color: MindCycleTheme.accent)
                    statBadge(label: "Deviation", value: "±\(Int(standardDeviation.rounded()))d", color: MindCycleTheme.accentWarm)
                    statBadge(label: "Cycles", value: "\(cycleLengths.count)", color: MindCycleTheme.accentCool)
                }
            }
        }
        .mindCycleCard()
    }
    
    private func statBadge(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(MindCycleTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.opacity(0.08))
        }
    }
}

// MARK: - Phase Timeline View

struct PhaseTimelineView: View {
    let phases: [PhaseInfo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Phase Timeline")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MindCycleTheme.textPrimary)
                
                Text("Detected clusters of low/overthinking days")
                    .font(.system(size: 11))
                    .foregroundStyle(MindCycleTheme.textTertiary)
            }
            
            if phases.isEmpty {
                Text("No phases detected yet. Keep logging to see patterns emerge.")
                    .font(.system(size: 12))
                    .foregroundStyle(MindCycleTheme.textTertiary)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(phases.enumerated()), id: \.offset) { index, phase in
                            phaseCard(phase: phase, index: index)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .mindCycleCard()
    }
    
    private func phaseCard(phase: PhaseInfo, index: Int) -> some View {
        let color = MindCycleTheme.color(for: phase.dominantType)
        
        return VStack(alignment: .leading, spacing: 8) {
            // Phase header
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color)
                    .frame(width: 4, height: 20)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Phase \(index + 1)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MindCycleTheme.textPrimary)
                    
                    Text(phase.dominantType.rawValue)
                        .font(.system(size: 9))
                        .foregroundStyle(color)
                }
            }
            
            // Duration
            HStack(spacing: 4) {
                Text("\(phase.duration)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text("day\(phase.duration == 1 ? "" : "s")")
                    .font(.system(size: 10))
                    .foregroundStyle(MindCycleTheme.textTertiary)
            }
            
            // Date range
            let formatter = DateFormatter()
            let _ = formatter.dateFormat = "MMM d"
            Text("\(formatter.string(from: phase.startDate))–\(formatter.string(from: phase.endDate))")
                .font(.system(size: 10))
                .foregroundStyle(MindCycleTheme.textTertiary)
            
            // Entries count
            Text("\(phase.entries.count) entries")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(MindCycleTheme.textTertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background {
                    Capsule()
                        .fill(Color.white.opacity(0.04))
                }
        }
        .padding(12)
        .frame(width: 130)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                }
        }
    }
}

// MARK: - Type Distribution Chart

struct TypeDistributionChart: View {
    let statistics: CycleStatistics
    
    private var chartData: [(type: String, count: Int, color: Color)] {
        [
            ("Low Feeling", statistics.lowFeelingCount, MindCycleTheme.lowFeeling),
            ("Overthinking", statistics.overthinkingCount, MindCycleTheme.overthinking),
            ("Both", statistics.bothCount, MindCycleTheme.both),
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type Breakdown")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MindCycleTheme.textPrimary)
            
            HStack(spacing: 20) {
                // Donut-style visual
                ZStack {
                    ForEach(Array(chartData.enumerated()), id: \.offset) { index, item in
                        let total = Double(statistics.totalEntries)
                        let percentage = total > 0 ? Double(item.count) / total : 0
                        
                        Circle()
                            .trim(from: trimStart(for: index), to: trimStart(for: index) + percentage)
                            .stroke(item.color, lineWidth: 12)
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                    }
                    
                    VStack(spacing: 0) {
                        Text("\(statistics.totalEntries)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(MindCycleTheme.textPrimary)
                        Text("total")
                            .font(.system(size: 9))
                            .foregroundStyle(MindCycleTheme.textTertiary)
                    }
                }
                
                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(chartData.enumerated()), id: \.offset) { _, item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            
                            Text(item.type)
                                .font(.system(size: 12))
                                .foregroundStyle(MindCycleTheme.textSecondary)
                            
                            Spacer()
                            
                            Text("\(item.count)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(MindCycleTheme.textPrimary)
                        }
                    }
                }
            }
        }
        .mindCycleCard()
    }
    
    private func trimStart(for index: Int) -> Double {
        let total = Double(statistics.totalEntries)
        guard total > 0 else { return 0 }
        var start: Double = 0
        for i in 0..<index {
            start += Double(chartData[i].count) / total
        }
        return start
    }
}
