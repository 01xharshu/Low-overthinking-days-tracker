// HistoryView.swift
// MindCycle
//
// Searchable, filterable list of all logged entries with editing and deletion support.

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CycleEntry.date, order: .reverse) private var entries: [CycleEntry]
    
    @State private var searchText: String = ""
    @State private var filterType: EntryType? = nil
    @State private var filterIntensity: IntensityLevel? = nil
    @State private var filterMonth: Date? = nil
    @State private var selectedEntry: CycleEntry? = nil
    @State private var showDeleteConfirmation = false
    @State private var entryToDelete: CycleEntry? = nil
    
    private var filteredEntries: [CycleEntry] {
        entries.filter { entry in
            // Search filter
            let matchesSearch = searchText.isEmpty ||
                entry.type.rawValue.localizedCaseInsensitiveContains(searchText) ||
                entry.intensity.rawValue.localizedCaseInsensitiveContains(searchText) ||
                (entry.notes ?? "").localizedCaseInsensitiveContains(searchText) ||
                entry.tags.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            
            // Type filter
            let matchesType = filterType == nil || entry.type == filterType
            
            // Intensity filter
            let matchesIntensity = filterIntensity == nil || entry.intensity == filterIntensity
            
            // Month filter
            let matchesMonth: Bool
            if let filterMonth {
                let cal = Calendar.current
                let entryComponents = cal.dateComponents([.year, .month], from: entry.date)
                let filterComponents = cal.dateComponents([.year, .month], from: filterMonth)
                matchesMonth = entryComponents.year == filterComponents.year && entryComponents.month == filterComponents.month
            } else {
                matchesMonth = true
            }
            
            return matchesSearch && matchesType && matchesIntensity && matchesMonth
        }
    }
    
    /// Distinct months present in entries for the month filter picker.
    private var availableMonths: [Date] {
        let cal = Calendar.current
        let months = Set(entries.map { date -> Date in
            let components = cal.dateComponents([.year, .month], from: date.date)
            return cal.date(from: components)!
        })
        return months.sorted(by: >)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header & Filters
            headerSection
            
            Divider()
                .overlay(Color.white.opacity(0.06))
            
            // MARK: - Entry List
            if filteredEntries.isEmpty {
                emptyFilterState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredEntries) { entry in
                            historyRow(entry: entry)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(MindCycleTheme.backgroundPrimary)
        .sheet(item: $selectedEntry) { entry in
            entryDetailSheet(entry: entry)
        }
        .alert("Delete Entry?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { entryToDelete = nil }
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    withAnimation(.spring(response: 0.3)) {
                        modelContext.delete(entry)
                    }
                    entryToDelete = nil
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("History")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(MindCycleTheme.textPrimary)
                    
                    Text("\(filteredEntries.count) of \(entries.count) entries")
                        .font(.system(size: 12))
                        .foregroundStyle(MindCycleTheme.textSecondary)
                }
                
                Spacer()
            }
            
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundStyle(MindCycleTheme.textTertiary)
                
                TextField("Search entries…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(MindCycleTheme.textPrimary)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(MindCycleTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    }
            }
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Type filters
                    filterChip("All Types", isActive: filterType == nil) {
                        filterType = nil
                    }
                    ForEach(EntryType.allCases) { type in
                        filterChip(type.rawValue, icon: type.icon, isActive: filterType == type, color: MindCycleTheme.color(for: type)) {
                            filterType = filterType == type ? nil : type
                        }
                    }
                    
                    Divider().frame(height: 20).overlay(Color.white.opacity(0.1))
                    
                    // Intensity filters
                    ForEach(IntensityLevel.allCases) { level in
                        filterChip(level.rawValue, icon: level.icon, isActive: filterIntensity == level, color: MindCycleTheme.color(for: level)) {
                            filterIntensity = filterIntensity == level ? nil : level
                        }
                    }
                    
                    if !availableMonths.isEmpty {
                        Divider().frame(height: 20).overlay(Color.white.opacity(0.1))
                        
                        // Month filter
                        filterChip("All Months", isActive: filterMonth == nil) {
                            filterMonth = nil
                        }
                        ForEach(availableMonths.prefix(6), id: \.self) { month in
                            filterChip(month.formatted(.dateTime.month(.abbreviated).year()), isActive: filterMonth == month) {
                                filterMonth = filterMonth == month ? nil : month
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
    }
    
    // MARK: - Filter Chip
    
    private func filterChip(_ title: String, icon: String? = nil, isActive: Bool, color: Color = MindCycleTheme.accent, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                action()
            }
        }) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(title)
                    .font(.system(size: 11, weight: isActive ? .semibold : .medium))
            }
            .foregroundStyle(isActive ? .white : MindCycleTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(isActive ? color : Color.white.opacity(0.04))
                    .overlay {
                        if !isActive {
                            Capsule()
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - History Row
    
    private func historyRow(entry: CycleEntry) -> some View {
        Button {
            selectedEntry = entry
        } label: {
            EntryRowView(entry: entry, showFullDate: true)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                selectedEntry = entry
            } label: {
                Label("View Details", systemImage: "eye")
            }
            
            Divider()
            
            Button(role: .destructive) {
                entryToDelete = entry
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Entry Detail Sheet
    
    private func entryDetailSheet(entry: CycleEntry) -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: entry.type.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(MindCycleTheme.color(for: entry.type))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.type.rawValue)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(MindCycleTheme.textPrimary)
                    
                    Text(entry.formattedDateLong + " • " + entry.dayOfWeek)
                        .font(.system(size: 13))
                        .foregroundStyle(MindCycleTheme.textSecondary)
                }
                
                Spacer()
                
                Button { selectedEntry = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(MindCycleTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            
            Divider().overlay(Color.white.opacity(0.06))
            
            // Details
            HStack(spacing: 24) {
                detailItem(title: "Intensity", value: entry.intensity.rawValue, icon: entry.intensity.icon, color: MindCycleTheme.color(for: entry.intensity))
                detailItem(title: "Days Ago", value: "\(entry.daysAgo)", icon: "clock", color: MindCycleTheme.accentCool)
            }
            
            if let notes = entry.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MindCycleTheme.textSecondary)
                    
                    Text(notes)
                        .font(.system(size: 13))
                        .foregroundStyle(MindCycleTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.03))
                        }
                }
            }
            
            if !entry.tags.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tags")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MindCycleTheme.textSecondary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(entry.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(MindCycleTheme.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background {
                                    Capsule()
                                        .fill(MindCycleTheme.accent.opacity(0.12))
                                }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Delete button
            Button(role: .destructive) {
                selectedEntry = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    entryToDelete = entry
                    showDeleteConfirmation = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Delete Entry")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MindCycleTheme.danger)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background {
                    Capsule()
                        .stroke(MindCycleTheme.danger.opacity(0.3), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(width: 480, height: 420)
        .background(MindCycleTheme.backgroundSecondary)
        .preferredColorScheme(.dark)
    }
    
    private func detailItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MindCycleTheme.textPrimary)
            
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(MindCycleTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.06))
        }
    }
    
    // MARK: - Empty Filter State
    
    private var emptyFilterState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(MindCycleTheme.textTertiary)
            
            Text(entries.isEmpty ? "No entries yet" : "No matching entries")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MindCycleTheme.textSecondary)
            
            if !entries.isEmpty {
                Text("Try adjusting your filters or search terms")
                    .font(.system(size: 13))
                    .foregroundStyle(MindCycleTheme.textTertiary)
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        searchText = ""
                        filterType = nil
                        filterIntensity = nil
                        filterMonth = nil
                    }
                } label: {
                    Text("Clear All Filters")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(MindCycleTheme.accent)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
    }
}
