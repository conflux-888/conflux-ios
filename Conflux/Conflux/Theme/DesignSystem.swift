import SwiftUI

// MARK: - Conflux Design System (Palantir Gotham)

// MARK: Colors

extension Color {
    // Backgrounds
    static let cxBackground = Color(red: 0.039, green: 0.055, blue: 0.102) // #0A0E1A
    static let cxBackgroundPure = Color.black // #000000
    static let cxSurface = Color(red: 0.067, green: 0.094, blue: 0.153) // #111827
    static let cxSurfaceElevated = Color(red: 0.102, green: 0.125, blue: 0.208) // #1A2035

    // Borders
    static let cxBorder = Color(red: 0, green: 0.898, blue: 1).opacity(0.12) // cyan @ 12%
    static let cxBorderActive = Color(red: 0, green: 0.898, blue: 1).opacity(0.35) // cyan @ 35%

    // Accent
    static let cxAccent = Color(red: 0, green: 0.898, blue: 1) // #00E5FF
    static let cxAccentDim = Color(red: 0, green: 0.898, blue: 1).opacity(0.15)
    static let cxWarning = Color(red: 1, green: 0.722, blue: 0) // #FFB800

    // Severity
    static let cxCritical = Color(red: 1, green: 0.231, blue: 0.188) // #FF3B30
    static let cxHigh = Color(red: 1, green: 0.584, blue: 0) // #FF9500
    static let cxMedium = Color(red: 1, green: 0.839, blue: 0.039) // #FFD60A
    static let cxLow = Color(red: 0.188, green: 0.820, blue: 0.345) // #30D158

    // Text
    static let cxText = Color(red: 0.910, green: 0.918, blue: 0.929) // #E8EAED
    static let cxTextSecondary = Color(red: 0.604, green: 0.627, blue: 0.651) // #9AA0A6
    static let cxTextTertiary = Color(red: 0.373, green: 0.388, blue: 0.416) // #5F6368

    // Sources
    static let cxSourceGDELT = Color(red: 0, green: 0.898, blue: 1) // #00E5FF
    static let cxSourceUser = Color(red: 0.733, green: 0.525, blue: 0.988) // #BB86FC
}

// MARK: - Typography

extension Font {
    static let cxHeading: Font = .system(.title3, design: .monospaced).weight(.bold)
    static let cxTitle: Font = .system(.headline, design: .monospaced).weight(.semibold)
    static let cxBody: Font = .system(.subheadline, design: .default).weight(.regular)
    static let cxData: Font = .system(.caption, design: .monospaced)
    static let cxLabel: Font = .system(.caption2, design: .default).weight(.semibold)
    static let cxMono: Font = .system(.caption, design: .monospaced).weight(.medium)
}

// MARK: - Shape Constants

enum CXConstants {
    static let cornerRadius: CGFloat = 3
    static let borderWidth: CGFloat = 1
    static let cardPadding: CGFloat = 12
    static let chipCornerRadius: CGFloat = 2
}

// MARK: - View Modifiers

struct CXCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(CXConstants.cardPadding)
            .background(Color.cxSurface)
            .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                    .stroke(Color.cxBorder, lineWidth: CXConstants.borderWidth)
            )
    }
}

struct CXFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.cxSurface)
            .foregroundStyle(Color.cxText)
            .font(.system(.body, design: .monospaced))
            .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                    .stroke(Color.cxBorder, lineWidth: CXConstants.borderWidth)
            )
    }
}

struct CXChipModifier: ViewModifier {
    let isSelected: Bool
    var activeColor: Color = .cxAccent

    func body(content: Content) -> some View {
        content
            .font(.cxData)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? activeColor.opacity(0.15) : Color.cxSurface)
            .foregroundStyle(isSelected ? activeColor : .cxTextSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CXConstants.chipCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: CXConstants.chipCornerRadius)
                    .stroke(isSelected ? activeColor.opacity(0.5) : Color.cxBorder, lineWidth: CXConstants.borderWidth)
            )
    }
}

struct CXGlowModifier: ViewModifier {
    var color: Color = .cxAccent
    var radius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

// MARK: - View Extensions

extension View {
    func cxCard() -> some View {
        modifier(CXCardModifier())
    }

    func cxField() -> some View {
        modifier(CXFieldModifier())
    }

    func cxChip(isSelected: Bool, activeColor: Color = .cxAccent) -> some View {
        modifier(CXChipModifier(isSelected: isSelected, activeColor: activeColor))
    }

    func cxGlow(_ color: Color = .cxAccent, radius: CGFloat = 8) -> some View {
        modifier(CXGlowModifier(color: color, radius: radius))
    }
}
