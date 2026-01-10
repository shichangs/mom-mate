//
//  DesignSystem.swift
//  BabySleepTracker
//
//  Apple-inspired design system with colors, typography, and reusable components
//

import SwiftUI

// MARK: - Colors
struct AppColors {
    // Primary palette
    static let primary = Color(hex: "5E5CE6")        // Soft indigo
    static let secondary = Color(hex: "FF6B6B")      // Warm coral
    static let accent = Color(hex: "34C759")         // Apple green
    static let warning = Color(hex: "FF9500")        // Orange
    
    // Semantic colors
    static let sleep = Color(hex: "5E5CE6")          // Indigo for sleep
    static let awake = Color(hex: "FF9F0A")          // Warm amber for awake
    static let meal = Color(hex: "30D158")           // Fresh green for meals
    static let milestone = Color(hex: "BF5AF2")      // Purple for milestones
    
    // Backgrounds
    static let background = Color(hex: "F2F2F7")     // System gray 6
    static let surface = Color.white
    static let surfaceSecondary = Color(hex: "F9F9FB")
    
    // Text
    static let textPrimary = Color(hex: "1C1C1E")
    static let textSecondary = Color(hex: "8E8E93")
    static let textTertiary = Color(hex: "AEAEB2")
    
    // Gradients
    static let sleepGradient = LinearGradient(
        colors: [Color(hex: "5E5CE6"), Color(hex: "7B7BF7")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let awakeGradient = LinearGradient(
        colors: [Color(hex: "FF9F0A"), Color(hex: "FFB340")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "34C759"), Color(hex: "30D158")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "F8F8FC"), Color(hex: "F2F2F7")],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
struct AppTypography {
    // Large Title
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    
    // Titles
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    // Body
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 17, weight: .medium, design: .default)
    static let bodySemibold = Font.system(size: 17, weight: .semibold, design: .default)
    
    // Callout
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let calloutMedium = Font.system(size: 16, weight: .medium, design: .default)
    
    // Subhead
    static let subhead = Font.system(size: 15, weight: .regular, design: .default)
    static let subheadMedium = Font.system(size: 15, weight: .medium, design: .default)
    
    // Footnote
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let footnoteMedium = Font.system(size: 13, weight: .medium, design: .default)
    
    // Caption
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionMedium = Font.system(size: 12, weight: .medium, design: .default)
    
    // Display (for large numbers)
    static let display = Font.system(size: 56, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 44, weight: .bold, design: .rounded)
    static let displaySmall = Font.system(size: 36, weight: .bold, design: .rounded)
}

// MARK: - Spacing
struct AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius
struct AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 28
    static let full: CGFloat = 100
}

// MARK: - Shadows
struct AppShadow {
    static let small = (color: Color.black.opacity(0.04), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))
    static let medium = (color: Color.black.opacity(0.06), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(4))
    static let large = (color: Color.black.opacity(0.08), radius: CGFloat(24), x: CGFloat(0), y: CGFloat(8))
}

// MARK: - View Modifiers

// Card style modifier
struct CardStyle: ViewModifier {
    var padding: CGFloat = AppSpacing.lg
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.xl)
            .shadow(
                color: AppShadow.medium.color,
                radius: AppShadow.medium.radius,
                x: AppShadow.medium.x,
                y: AppShadow.medium.y
            )
    }
}

// Primary button style
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = AppColors.primary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodySemibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(color)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Secondary button style
struct SecondaryButtonStyle: ButtonStyle {
    var color: Color = AppColors.primary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.subheadMedium)
            .foregroundColor(color)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(color.opacity(0.12))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Chip style for tags
struct ChipStyle: ViewModifier {
    var color: Color = AppColors.primary
    var isSelected: Bool = false
    
    func body(content: Content) -> some View {
        content
            .font(AppTypography.footnoteMedium)
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.12))
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = AppSpacing.lg) -> some View {
        modifier(CardStyle(padding: padding))
    }
    
    func chipStyle(color: Color = AppColors.primary, isSelected: Bool = false) -> some View {
        modifier(ChipStyle(color: color, isSelected: isSelected))
    }
}

// MARK: - Reusable Components

// Icon circle background
struct IconCircle: View {
    let icon: String
    var size: CGFloat = 48
    var iconSize: CGFloat = 22
    var color: Color = AppColors.primary
    var filled: Bool = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(filled ? color : color.opacity(0.12))
                .frame(width: size, height: size)
            
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(filled ? .white : color)
        }
    }
}

// Section header
struct SectionHeader: View {
    let title: String
    var showChevron: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action?()
        }
    }
}

// Empty state view
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var color: Color = AppColors.textSecondary
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(color.opacity(0.6))
            
            Text(title)
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            Text(subtitle)
                .font(AppTypography.subhead)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxxl)
    }
}

// Animated pulsing circle (for sleeping indicator)
struct PulsingCircle: View {
    let color: Color
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(color.opacity(0.3))
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 0 : 0.6)
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}
