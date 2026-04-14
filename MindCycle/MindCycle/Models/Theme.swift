// Theme.swift
// MindCycle
//
// Design system: calming, dark-mode first color palette with soft blues, purples, and grays.
// All colors and styling constants live here for consistent theming.

import SwiftUI

// MARK: - MindCycle Theme

struct MindCycleTheme {
    
    // MARK: - Core Palette
    
    /// Deep background
    static var backgroundPrimary: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
                return NSColor(red: 0.067, green: 0.071, blue: 0.106, alpha: 1.0)
            } else {
                return NSColor(red: 0.96, green: 0.97, blue: 1.0, alpha: 1.0)
            }
        })
    }
    
    /// Slightly elevated surface
    static var backgroundSecondary: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
                return NSColor(red: 0.098, green: 0.106, blue: 0.153, alpha: 1.0)
            } else {
                return NSColor(red: 0.92, green: 0.93, blue: 0.98, alpha: 1.0)
            }
        })
    }
    
    /// Card/panel surface
    static var backgroundTertiary: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
                return NSColor(red: 0.133, green: 0.145, blue: 0.200, alpha: 1.0)
            } else {
                return NSColor.white
            }
        })
    }
    
    /// Soft lavender accent – primary brand color
    static let accent = Color(red: 0.545, green: 0.502, blue: 0.957)
    /// Warmer purple accent
    static let accentWarm = Color(red: 0.698, green: 0.463, blue: 0.906)
    /// Cool blue accent
    static let accentCool = Color(red: 0.396, green: 0.565, blue: 0.957)
    
    /// Low feeling indicator – soft blue
    static let lowFeeling = Color(red: 0.361, green: 0.533, blue: 0.898)
    /// Overthinking indicator – warm purple
    static let overthinking = Color(red: 0.725, green: 0.443, blue: 0.878)
    /// Both indicator – blended gradient midpoint
    static let both = Color(red: 0.541, green: 0.486, blue: 0.890)
    
    /// Mild intensity – soft sage
    static let mildIntensity = Color(red: 0.478, green: 0.722, blue: 0.635)
    /// Moderate intensity – amber warmth
    static let moderateIntensity = Color(red: 0.878, green: 0.718, blue: 0.384)
    /// Severe intensity – soft coral
    static let severeIntensity = Color(red: 0.886, green: 0.443, blue: 0.427)
    
    /// Primary text
    static var textPrimary: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
                return NSColor(red: 0.933, green: 0.937, blue: 0.969, alpha: 1.0)
            } else {
                return NSColor(red: 0.08, green: 0.09, blue: 0.14, alpha: 1.0)
            }
        })
    }
    
    /// Secondary text
    static var textSecondary: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
                return NSColor(red: 0.600, green: 0.616, blue: 0.706, alpha: 1.0)
            } else {
                return NSColor(red: 0.4, green: 0.42, blue: 0.5, alpha: 1.0)
            }
        })
    }
    
    /// Tertiary/disabled text
    static var textTertiary: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
                return NSColor(red: 0.400, green: 0.416, blue: 0.506, alpha: 1.0)
            } else {
                return NSColor(red: 0.6, green: 0.62, blue: 0.7, alpha: 1.0)
            }
        })
    }
    
    /// Positive/recovery indicator
    static let positive = Color(red: 0.396, green: 0.784, blue: 0.588)
    /// Warning indicator
    static let warning = Color(red: 0.957, green: 0.757, blue: 0.357)
    /// Danger/alert indicator
    static let danger = Color(red: 0.918, green: 0.404, blue: 0.404)
    
    // MARK: - Gradients
    
    static let mainGradient = LinearGradient(
        colors: [accent, accentWarm],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let subtleGradient = LinearGradient(
        colors: [backgroundSecondary, backgroundTertiary],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let lowFeelingGradient = LinearGradient(
        colors: [lowFeeling.opacity(0.8), accentCool.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let overthinkingGradient = LinearGradient(
        colors: [overthinking.opacity(0.8), accentWarm.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.06),
            Color.white.opacity(0.02)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Styling Functions
    
    /// Returns the theme color for a given entry type.
    static func color(for type: EntryType) -> Color {
        switch type {
        case .lowFeeling: return lowFeeling
        case .overthinking: return overthinking
        case .both: return both
        }
    }
    
    /// Returns the theme color for a given intensity level.
    static func color(for intensity: IntensityLevel) -> Color {
        switch intensity {
        case .mild: return mildIntensity
        case .moderate: return moderateIntensity
        case .severe: return severeIntensity
        }
    }
    
    // MARK: - Dimensions
    
    static let cornerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let iconSize: CGFloat = 20
    
    // MARK: - Sidebar Width
    
    static let sidebarWidth: CGFloat = 220
}

// MARK: - Card Modifier

struct MindCycleCard: ViewModifier {
    var padding: CGFloat = MindCycleTheme.cardPadding
    
    func body(content: Content) -> some View {
        @Environment(\.colorScheme) var colorScheme
        
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: MindCycleTheme.cornerRadius, style: .continuous)
                    .fill(MindCycleTheme.backgroundTertiary)
                    .overlay {
                        RoundedRectangle(cornerRadius: MindCycleTheme.cornerRadius, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 10, x: 0, y: 4)
            }
    }
}

// MARK: - Glowing Card Modifier

struct GlowingCard: ViewModifier {
    let glowColor: Color
    var intensity: CGFloat = 0.3
    
    func body(content: Content) -> some View {
        @Environment(\.colorScheme) var colorScheme
        
        content
            .padding(MindCycleTheme.cardPadding)
            .background {
                RoundedRectangle(cornerRadius: MindCycleTheme.cornerRadius, style: .continuous)
                    .fill(MindCycleTheme.backgroundTertiary)
                    .overlay {
                        RoundedRectangle(cornerRadius: MindCycleTheme.cornerRadius, style: .continuous)
                            .stroke(glowColor.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
                    }
                    .shadow(color: glowColor.opacity(intensity), radius: 20, x: 0, y: 4)
            }
    }
}

// MARK: - View Extensions

extension View {
    func mindCycleCard(padding: CGFloat = MindCycleTheme.cardPadding) -> some View {
        modifier(MindCycleCard(padding: padding))
    }
    
    func glowingCard(color: Color, intensity: CGFloat = 0.3) -> some View {
        modifier(GlowingCard(glowColor: color, intensity: intensity))
    }
}

// MARK: - Animated Number Text

struct AnimatedNumberView: View {
    let value: Int
    let suffix: String
    let color: Color
    
    init(_ value: Int, suffix: String = "", color: Color = MindCycleTheme.textPrimary) {
        self.value = value
        self.suffix = suffix
        self.color = color
    }
    
    var body: some View {
        Text("\(value)\(suffix)")
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(value)))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
    }
}

// MARK: - Pulse Animation

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .overlay {
                Circle()
                    .fill(color)
                    .scaleEffect(isPulsing ? 1.5 : 0.8)
                    .opacity(isPulsing ? 0 : 0.4)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: false),
                        value: isPulsing
                    )
            }
            .onAppear { isPulsing = true }
    }
}
