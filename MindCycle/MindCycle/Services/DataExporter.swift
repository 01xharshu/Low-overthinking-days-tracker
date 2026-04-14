// DataExporter.swift
// MindCycle
//
// Handles exporting cycle data to JSON and CSV formats for backup/sharing.

import Foundation
import AppKit

/// Exports CycleEntry data to JSON or CSV files.
struct DataExporter {
    
    // MARK: - Export Formats
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
        
        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            }
        }
        
        var contentType: String {
            switch self {
            case .json: return "application/json"
            case .csv: return "text/csv"
            }
        }
    }
    
    // MARK: - Exportable Entry
    
    /// A Codable struct mirroring CycleEntry for clean JSON export.
    struct ExportableEntry: Codable {
        let date: String
        let type: String
        let intensity: String
        let notes: String?
        let tags: [String]
        let createdAt: String
        
        init(from entry: CycleEntry) {
            let formatter = ISO8601DateFormatter()
            self.date = formatter.string(from: entry.date)
            self.type = entry.type.rawValue
            self.intensity = entry.intensity.rawValue
            self.notes = entry.notes
            self.tags = entry.tags
            self.createdAt = formatter.string(from: entry.createdAt)
        }
    }
    
    // MARK: - Export Methods
    
    /// Export entries in the specified format, presenting a save dialog.
    static func export(entries: [CycleEntry], format: ExportFormat) {
        let sorted = entries.sorted { $0.date > $1.date }
        
        let data: Data?
        switch format {
        case .json:
            data = generateJSON(from: sorted)
        case .csv:
            data = generateCSV(from: sorted)
        }
        
        guard let exportData = data else { return }
        
        // Present save dialog
        let panel = NSSavePanel()
        panel.title = "Export MindCycle Data"
        panel.nameFieldStringValue = "mindcycle_export_\(dateStamp()).\(format.fileExtension)"
        panel.allowedContentTypes = format == .json
            ? [.json]
            : [.commaSeparatedText]
        panel.canCreateDirectories = true
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try exportData.write(to: url)
                } catch {
                    print("Export failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - JSON Generation
    
    private static func generateJSON(from entries: [CycleEntry]) -> Data? {
        let exportable = entries.map { ExportableEntry(from: $0) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(exportable)
    }
    
    // MARK: - CSV Generation
    
    private static func generateCSV(from entries: [CycleEntry]) -> Data? {
        var csv = "Date,Type,Intensity,Notes,Tags,Created At\n"
        
        let formatter = ISO8601DateFormatter()
        
        for entry in entries {
            let date = formatter.string(from: entry.date)
            let type = entry.type.rawValue
            let intensity = entry.intensity.rawValue
            let notes = escapeCSV(entry.notes ?? "")
            let tags = escapeCSV(entry.tags.joined(separator: "; "))
            let createdAt = formatter.string(from: entry.createdAt)
            
            csv += "\(date),\(type),\(intensity),\(notes),\(tags),\(createdAt)\n"
        }
        
        return csv.data(using: .utf8)
    }
    
    // MARK: - Helpers
    
    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
    
    private static func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: .now)
    }
}
