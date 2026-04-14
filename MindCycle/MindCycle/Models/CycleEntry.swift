// CycleEntry.swift
// MindCycle
//
// The core data model for tracking low feeling and overthinking days.
// Uses SwiftData for local persistence with no cloud sync.

import Foundation
import SwiftData

// MARK: - Entry Type

/// Represents what type of day was logged.
enum EntryType: String, Codable, CaseIterable, Identifiable {
    case lowFeeling = "Low Feeling"
    case overthinking = "Overthinking"
    case both = "Both"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .lowFeeling: return "cloud.rain"
        case .overthinking: return "brain.head.profile"
        case .both: return "cloud.bolt"
        }
    }
    
    var color: String {
        switch self {
        case .lowFeeling: return "lowFeeling"
        case .overthinking: return "overthinking"
        case .both: return "both"
        }
    }
}

// MARK: - Intensity Level

/// The severity/intensity of the logged day.
enum IntensityLevel: String, Codable, CaseIterable, Identifiable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"
    
    var id: String { rawValue }
    
    var numericValue: Int {
        switch self {
        case .mild: return 1
        case .moderate: return 2
        case .severe: return 3
        }
    }
    
    var icon: String {
        switch self {
        case .mild: return "drop"
        case .moderate: return "drop.halffull"
        case .severe: return "drop.fill"
        }
    }
    
    var description: String {
        switch self {
        case .mild: return "A gentle wave – manageable but noticeable"
        case .moderate: return "Heavier than usual – taking extra care"
        case .severe: return "A difficult day – be kind to yourself"
        }
    }
}

// MARK: - Cycle Entry Model

/// The primary SwiftData model for a logged entry.
@Model
final class CycleEntry {
    /// The date of this entry (normalized to midnight for consistency).
    var date: Date
    
    /// The type of entry (low feeling, overthinking, or both).
    var typeRawValue: String
    
    /// The intensity level of the entry.
    var intensityRawValue: String
    
    /// Optional notes the user wants to record.
    var notes: String?
    
    /// Optional tags for categorization (stored as comma-separated string).
    var tagsString: String?
    
    /// Timestamp when this entry was created.
    var createdAt: Date
    
    /// Timestamp when this entry was last modified.
    var updatedAt: Date
    
    // MARK: - Computed Properties
    
    /// Typed accessor for entry type.
    var type: EntryType {
        get { EntryType(rawValue: typeRawValue) ?? .lowFeeling }
        set { typeRawValue = newValue.rawValue }
    }
    
    /// Typed accessor for intensity.
    var intensity: IntensityLevel {
        get { IntensityLevel(rawValue: intensityRawValue) ?? .mild }
        set { intensityRawValue = newValue.rawValue }
    }
    
    /// Typed accessor for tags array.
    var tags: [String] {
        get {
            guard let tagsString, !tagsString.isEmpty else { return [] }
            return tagsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            tagsString = newValue.isEmpty ? nil : newValue.joined(separator: ",")
        }
    }
    
    // MARK: - Initializer
    
    init(
        date: Date = .now,
        type: EntryType = .lowFeeling,
        intensity: IntensityLevel = .mild,
        notes: String? = nil,
        tags: [String] = []
    ) {
        // Normalize date to start of day
        self.date = Calendar.current.startOfDay(for: date)
        self.typeRawValue = type.rawValue
        self.intensityRawValue = intensity.rawValue
        self.notes = notes
        self.tagsString = tags.isEmpty ? nil : tags.joined(separator: ",")
        self.createdAt = .now
        self.updatedAt = .now
    }
}

// MARK: - Convenience Extensions

extension CycleEntry {
    /// Returns a formatted date string.
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    /// Returns a long formatted date string.
    var formattedDateLong: String {
        date.formatted(date: .long, time: .omitted)
    }
    
    /// Returns the day of week for this entry.
    var dayOfWeek: String {
        date.formatted(.dateTime.weekday(.wide))
    }
    
    /// Check if this entry is from today.
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Number of days ago this entry was logged.
    var daysAgo: Int {
        Calendar.current.dateComponents([.day], from: date, to: .now).day ?? 0
    }
}

// MARK: - Sample Data for Previews

extension CycleEntry {
    static var sampleEntries: [CycleEntry] {
        let calendar = Calendar.current
        let today = Date.now
        
        return [
            CycleEntry(
                date: calendar.date(byAdding: .day, value: -1, to: today)!,
                type: .lowFeeling,
                intensity: .moderate,
                notes: "Felt heavy today, hard to concentrate",
                tags: ["work", "stress"]
            ),
            CycleEntry(
                date: calendar.date(byAdding: .day, value: -3, to: today)!,
                type: .overthinking,
                intensity: .mild,
                notes: "Spiral about the presentation tomorrow",
                tags: ["anxiety"]
            ),
            CycleEntry(
                date: calendar.date(byAdding: .day, value: -7, to: today)!,
                type: .both,
                intensity: .severe,
                notes: "Really tough day. Everything felt overwhelming.",
                tags: ["overwhelm", "fatigue"]
            ),
            CycleEntry(
                date: calendar.date(byAdding: .day, value: -14, to: today)!,
                type: .lowFeeling,
                intensity: .mild,
                notes: nil,
                tags: []
            ),
            CycleEntry(
                date: calendar.date(byAdding: .day, value: -28, to: today)!,
                type: .both,
                intensity: .moderate,
                notes: "End of month stress hitting hard",
                tags: ["deadlines", "burnout"]
            ),
            CycleEntry(
                date: calendar.date(byAdding: .day, value: -35, to: today)!,
                type: .overthinking,
                intensity: .severe,
                notes: "Can't stop thinking about what went wrong",
                tags: ["rumination"]
            ),
            CycleEntry(
                date: calendar.date(byAdding: .day, value: -42, to: today)!,
                type: .lowFeeling,
                intensity: .moderate,
                notes: "Weather is gray, energy is low",
                tags: ["seasonal"]
            ),
            CycleEntry(
                date: calendar.date(byAdding: .day, value: -56, to: today)!,
                type: .overthinking,
                intensity: .mild,
                notes: nil,
                tags: ["night"]
            ),
        ]
    }
}
