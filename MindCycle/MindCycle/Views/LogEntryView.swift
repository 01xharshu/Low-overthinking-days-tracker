// LogEntryView.swift
// MindCycle
//
// Full-featured entry logging screen with date picker, type toggles,
// intensity selector, notes editor, tags input, and save functionality.

import SwiftUI
import SwiftData

struct LogEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CycleEntry.date, order: .reverse) private var entries: [CycleEntry]
    
    // MARK: - State
    @State private var selectedDate: Date = .now
    @State private var isLowFeeling: Bool = true
    @State private var isOverthinking: Bool = false
    @State private var intensity: IntensityLevel = .mild
    @State private var notes: String = ""
    @State private var tagInput: String = ""
    @State private var tags: [String] = []
    @State private var showSavedConfirmation: Bool = false
    @State private var editingEntry: CycleEntry? = nil
    
    private var entryType: EntryType {
        if isLowFeeling && isOverthinking { return .both }
        if isOverthinking { return .overthinking }
        return .lowFeeling
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MindCycleTheme.sectionSpacing) {
                // MARK: - Header
                header
                
                HStack(alignment: .top, spacing: 20) {
                    // Left column: Date + Type + Intensity
                    VStack(spacing: 20) {
                        dateSection
                        typeSection
                        intensitySection
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right column: Notes + Tags + Actions
                    VStack(spacing: 20) {
                        notesSection
                        tagsSection
                        saveSection
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
        .overlay {
            if showSavedConfirmation {
                savedOverlay
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(editingEntry != nil ? "Edit Entry" : "Log Entry")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(MindCycleTheme.textPrimary)
            
            Text("Take a moment to check in with yourself. There's no right or wrong — just honest reflection.")
                .font(.system(size: 14))
                .foregroundStyle(MindCycleTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Date Section
    
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Date", icon: "calendar")
            
            DatePicker(
                "Select date",
                selection: $selectedDate,
                in: ...Date.now,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .tint(MindCycleTheme.accent)
            .padding(4)
        }
        .mindCycleCard()
    }
    
    // MARK: - Type Section
    
    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("What are you experiencing?", icon: "heart.text.square")
            
            VStack(spacing: 10) {
                toggleButton(
                    title: "Low Feeling",
                    subtitle: "Emotional low, sadness, or lack of energy",
                    icon: "cloud.rain",
                    isOn: $isLowFeeling,
                    color: MindCycleTheme.lowFeeling
                )
                
                toggleButton(
                    title: "Overthinking",
                    subtitle: "Racing thoughts, rumination, or anxiety spirals",
                    icon: "brain.head.profile",
                    isOn: $isOverthinking,
                    color: MindCycleTheme.overthinking
                )
            }
            
            // Ensure at least one is selected
            .onChange(of: isLowFeeling) { _, newValue in
                if !newValue && !isOverthinking { isOverthinking = true }
            }
            .onChange(of: isOverthinking) { _, newValue in
                if !newValue && !isLowFeeling { isLowFeeling = true }
            }
            
            // Combined indicator
            if isLowFeeling && isOverthinking {
                HStack(spacing: 6) {
                    Image(systemName: "cloud.bolt")
                        .font(.system(size: 12))
                    Text("Logging as Both")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(MindCycleTheme.both)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(MindCycleTheme.both.opacity(0.12))
                }
            }
        }
        .mindCycleCard()
    }
    
    // MARK: - Intensity Section
    
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Intensity", icon: "gauge.with.dots.needle.33percent")
            
            // Segmented control
            HStack(spacing: 0) {
                ForEach(IntensityLevel.allCases) { level in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            intensity = level
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: level.icon)
                                .font(.system(size: 16))
                            
                            Text(level.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(intensity == level ? .white : MindCycleTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            if intensity == level {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(MindCycleTheme.color(for: level))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            }
            
            // Description
            Text(intensity.description)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(MindCycleTheme.textTertiary)
                .italic()
                .padding(.horizontal, 4)
        }
        .mindCycleCard()
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Notes", icon: "note.text")
            
            TextEditor(text: $notes)
                .font(.system(size: 13))
                .foregroundStyle(MindCycleTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120, maxHeight: 200)
                .padding(10)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        }
                }
                .overlay(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("How are you feeling? What's on your mind?")
                            .font(.system(size: 13))
                            .foregroundStyle(MindCycleTheme.textTertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
        }
        .mindCycleCard()
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Tags", icon: "tag")
            
            HStack(spacing: 8) {
                TextField("Add a tag…", text: $tagInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(MindCycleTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            }
                    }
                    .onSubmit { addTag() }
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(MindCycleTheme.accent)
                }
                .buttonStyle(.plain)
                .disabled(tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            
            // Tag chips
            if !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.system(size: 11, weight: .medium))
                            
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    tags.removeAll { $0 == tag }
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 10))
                            }
                            .buttonStyle(.plain)
                        }
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
            
            // Quick suggestions
            HStack(spacing: 6) {
                ForEach(["stress", "work", "sleep", "anxiety", "energy"], id: \.self) { suggestion in
                    Button {
                        if !tags.contains(suggestion) {
                            withAnimation(.spring(response: 0.3)) {
                                tags.append(suggestion)
                            }
                        }
                    } label: {
                        Text(suggestion)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(tags.contains(suggestion) ? MindCycleTheme.accent : MindCycleTheme.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background {
                                Capsule()
                                    .stroke(tags.contains(suggestion) ? MindCycleTheme.accent.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mindCycleCard()
    }
    
    // MARK: - Save Section
    
    private var saveSection: some View {
        VStack(spacing: 12) {
            // Preview summary
            previewSummary
            
            HStack(spacing: 12) {
                // Reset button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        resetForm()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MindCycleTheme.textSecondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background {
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                
                // Save button
                Button(action: saveEntry) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text(editingEntry != nil ? "Update Entry" : "Save Entry")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        Capsule()
                            .fill(MindCycleTheme.mainGradient)
                            .shadow(color: MindCycleTheme.accent.opacity(0.4), radius: 12, y: 4)
                    }
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .mindCycleCard()
    }
    
    // MARK: - Preview Summary
    
    private var previewSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Entry Preview")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MindCycleTheme.textSecondary)
            
            HStack(spacing: 16) {
                // Date
                VStack(alignment: .leading, spacing: 2) {
                    Text("Date")
                        .font(.system(size: 10))
                        .foregroundStyle(MindCycleTheme.textTertiary)
                    Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MindCycleTheme.textPrimary)
                }
                
                Divider().frame(height: 24)
                
                // Type
                VStack(alignment: .leading, spacing: 2) {
                    Text("Type")
                        .font(.system(size: 10))
                        .foregroundStyle(MindCycleTheme.textTertiary)
                    HStack(spacing: 4) {
                        Image(systemName: entryType.icon)
                            .font(.system(size: 10))
                        Text(entryType.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(MindCycleTheme.color(for: entryType))
                }
                
                Divider().frame(height: 24)
                
                // Intensity
                VStack(alignment: .leading, spacing: 2) {
                    Text("Intensity")
                        .font(.system(size: 10))
                        .foregroundStyle(MindCycleTheme.textTertiary)
                    HStack(spacing: 4) {
                        Image(systemName: intensity.icon)
                            .font(.system(size: 10))
                        Text(intensity.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(MindCycleTheme.color(for: intensity))
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                }
        }
    }
    
    // MARK: - Saved Overlay
    
    private var savedOverlay: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(MindCycleTheme.positive.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(MindCycleTheme.positive)
            }
            
            Text("Entry Saved")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(MindCycleTheme.textPrimary)
            
            Text("Thank you for checking in with yourself 💙")
                .font(.system(size: 13))
                .foregroundStyle(MindCycleTheme.textSecondary)
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
        }
        .transition(.scale(scale: 0.8).combined(with: .opacity))
        .zIndex(100)
    }
    
    // MARK: - Actions
    
    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        withAnimation(.spring(response: 0.3)) {
            tags.append(trimmed)
            tagInput = ""
        }
    }
    
    private func saveEntry() {
        if let editing = editingEntry {
            // Update existing
            editing.date = Calendar.current.startOfDay(for: selectedDate)
            editing.type = entryType
            editing.intensity = intensity
            editing.notes = notes.isEmpty ? nil : notes
            editing.tags = tags
            editing.updatedAt = .now
        } else {
            // Create new
            let entry = CycleEntry(
                date: selectedDate,
                type: entryType,
                intensity: intensity,
                notes: notes.isEmpty ? nil : notes,
                tags: tags
            )
            modelContext.insert(entry)
        }
        
        // Show confirmation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSavedConfirmation = true
        }
        
        // Auto-dismiss and reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.3)) {
                showSavedConfirmation = false
                resetForm()
            }
        }
    }
    
    private func resetForm() {
        selectedDate = .now
        isLowFeeling = true
        isOverthinking = false
        intensity = .mild
        notes = ""
        tagInput = ""
        tags = []
        editingEntry = nil
    }
    
    // MARK: - Helpers
    
    private func sectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(MindCycleTheme.accent)
            
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MindCycleTheme.textPrimary)
        }
    }
    
    private func toggleButton(title: String, subtitle: String, icon: String, isOn: Binding<Bool>, color: Color) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isOn.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isOn.wrappedValue ? color.opacity(0.15) : Color.white.opacity(0.04))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(isOn.wrappedValue ? color : MindCycleTheme.textTertiary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isOn.wrappedValue ? MindCycleTheme.textPrimary : MindCycleTheme.textSecondary)
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(MindCycleTheme.textTertiary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isOn.wrappedValue ? color : MindCycleTheme.textTertiary)
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isOn.wrappedValue ? color.opacity(0.06) : Color.clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isOn.wrappedValue ? color.opacity(0.2) : Color.white.opacity(0.06), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .init(frame.size))
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
