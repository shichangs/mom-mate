//
//  DesignSystem.swift
//  MomMate
//
//  Premium Apple-inspired design system with Glassmorphism, Micro-interactions, and Semantic Colors
//

import SwiftUI
import Foundation

// MARK: - Semantic Colors (情绪化色彩)
struct AppColors {
    // Primary palette
    static let primary = Color(hex: "5E5CE6")        // 宁静紫
    static let secondary = Color(hex: "FF6B6B")      // 温暖珊瑚
    static let accent = Color(hex: "34C759")         // 活力绿
    static let warning = Color(hex: "FF9500")        // 警示橙
    
    // Semantic/Emotional colors (情绪色)
    static let sleep = Color(hex: "6366F1")          // 安睡紫 - Indigo for peaceful sleep
    static let awake = Color(hex: "F59E0B")          // 活力橙 - Amber for energy
    static let meal = Color(hex: "10B981")           // 成长绿 - Emerald for nourishment
    static let milestone = Color(hex: "A855F7")      // 喜悦紫 - Purple for celebration
    static let notes = Color(hex: "06B6D4")          // 记录青 - Cyan for notes
    
    // Backgrounds
    static let background = Color(hex: "F8FAFC")     // Light slate
    static let surface = Color.white
    static let surfaceSecondary = Color(hex: "F1F5F9")
    static let surfaceElevated = Color(hex: "FFFFFF")
    
    // Dark mode surfaces
    static let darkBackground = Color(hex: "0F172A")
    static let darkSurface = Color(hex: "1E293B")
    
    // Text
    static let textPrimary = Color(hex: "0F172A")
    static let textSecondary = Color(hex: "64748B")
    static let textTertiary = Color(hex: "94A3B8")
    
    // MARK: - Premium Gradients (高级渐变)
    static let sleepGradient = LinearGradient(
        colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6"), Color(hex: "A78BFA")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let awakeGradient = LinearGradient(
        colors: [Color(hex: "F59E0B"), Color(hex: "FBBF24"), Color(hex: "FCD34D")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let mealGradient = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "34D399"), Color(hex: "6EE7B7")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let milestoneGradient = LinearGradient(
        colors: [Color(hex: "A855F7"), Color(hex: "C084FC"), Color(hex: "DDD6FE")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let heroGradient = LinearGradient(
        colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6"), Color(hex: "EC4899")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "F8FAFC"), Color(hex: "E2E8F0")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Mesh gradient colors for iOS 17+
    static let meshColors: [Color] = [
        Color(hex: "6366F1"),
        Color(hex: "8B5CF6"),
        Color(hex: "EC4899"),
        Color(hex: "F59E0B")
    ]
}

// MARK: - Shared Date Formatters
enum DateFormatters {
    static let fullDateTimeZhCN: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    static let time24ZhCN: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    static let dayNumber: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    static let monthZh: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    static let monthDayZh: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    static let dayLabel: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    static let monthLabelZh: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    static let yearLabelZh: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    static let fullDateZh: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
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

// MARK: - Typography (动态字体)
struct AppTypography {
    // 字体缩放比例 (默认 1.0)
    // 获取用户设置的缩放比例，建议在 View 中通过 @AppStorage("fontSizeFactor") 传递给这里或直接读取
    static var fontScale: CGFloat {
        UserDefaults.standard.double(forKey: "fontSizeFactor") == 0 ? 1.0 : CGFloat(UserDefaults.standard.double(forKey: "fontSizeFactor"))
    }
    
    private static func scaledFont(size: CGFloat, weight: Font.Weight, design: Font.Design = .default) -> Font {
        return Font.system(size: size * fontScale, weight: weight, design: design)
    }

    // Large Title - Extra bold for hero sections
    static var largeTitle: Font { scaledFont(size: 34, weight: .heavy, design: .rounded) }
    static var largeTitleSerif: Font { scaledFont(size: 34, weight: .bold, design: .serif) }
    
    // Titles
    static var title1: Font { scaledFont(size: 28, weight: .bold, design: .rounded) }
    static var title2: Font { scaledFont(size: 22, weight: .bold, design: .rounded) }
    static var title3: Font { scaledFont(size: 20, weight: .semibold, design: .rounded) }
    
    // Body
    static var body: Font { scaledFont(size: 17, weight: .regular) }
    static var bodyMedium: Font { scaledFont(size: 17, weight: .medium) }
    static var bodySemibold: Font { scaledFont(size: 17, weight: .semibold) }
    
    // Callout
    static var callout: Font { scaledFont(size: 16, weight: .regular) }
    static var calloutMedium: Font { scaledFont(size: 16, weight: .medium) }
    
    // Subhead
    static var subhead: Font { scaledFont(size: 15, weight: .regular) }
    static var subheadMedium: Font { scaledFont(size: 15, weight: .medium) }
    
    // Footnote
    static var footnote: Font { scaledFont(size: 13, weight: .regular) }
    static var footnoteMedium: Font { scaledFont(size: 13, weight: .medium) }
    
    // Caption
    static var caption: Font { scaledFont(size: 12, weight: .regular) }
    static var captionMedium: Font { scaledFont(size: 12, weight: .medium) }
    
    // Display (for large numbers) - More dramatic
    static var display: Font { scaledFont(size: 64, weight: .heavy, design: .rounded) }
    static var displayMedium: Font { scaledFont(size: 48, weight: .bold, design: .rounded) }
    static var displaySmall: Font { scaledFont(size: 36, weight: .bold, design: .rounded) }
    
    // Monospace for timers
    static var timer: Font { scaledFont(size: 56, weight: .bold, design: .monospaced) }
    static var timerSmall: Font { scaledFont(size: 32, weight: .semibold, design: .monospaced) }
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
    static let huge: CGFloat = 64
}

// MARK: - Corner Radius
struct AppRadius {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 18
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let full: CGFloat = 9999
}

// MARK: - Layered Shadows (多层阴影体系)
struct AppShadow {
    // Subtle elevation
    static let small = (
        color: Color.black.opacity(0.04),
        radius: CGFloat(8),
        x: CGFloat(0),
        y: CGFloat(2)
    )
    
    // Cards and surfaces
    static let medium = (
        color: Color.black.opacity(0.08),
        radius: CGFloat(16),
        x: CGFloat(0),
        y: CGFloat(4)
    )
    
    // Floating elements
    static let large = (
        color: Color.black.opacity(0.12),
        radius: CGFloat(24),
        x: CGFloat(0),
        y: CGFloat(8)
    )
    
    // Dramatic depth
    static let xlarge = (
        color: Color.black.opacity(0.16),
        radius: CGFloat(32),
        x: CGFloat(0),
        y: CGFloat(12)
    )
    
    // Colored shadow (for buttons)
    static func colored(_ color: Color) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        return (color: color.opacity(0.4), radius: 16, x: 0, y: 6)
    }
}

// MARK: - Animation Presets (动画预设)
struct AppAnimation {
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)
    static let springSmooth = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)
    static let easeOutQuick = Animation.easeOut(duration: 0.2)
    static let easeInOutMedium = Animation.easeInOut(duration: 0.35)
}

// MARK: - View Modifiers

// Glassmorphism Card (毛玻璃卡片)
struct GlassCardStyle: ViewModifier {
    var padding: CGFloat = AppSpacing.lg
    var cornerRadius: CGFloat = AppRadius.xl
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Blurred background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    // Subtle border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: AppShadow.medium.color,
                radius: AppShadow.medium.radius,
                x: AppShadow.medium.x,
                y: AppShadow.medium.y
            )
    }
}

// Elevated Card with layered shadows
struct ElevatedCardStyle: ViewModifier {
    var padding: CGFloat = AppSpacing.lg
    var cornerRadius: CGFloat = AppRadius.xl
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColors.surface)
            )
            // Multiple shadow layers for depth
            .shadow(color: Color.black.opacity(0.02), radius: 1, x: 0, y: 1)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// Legacy Card style (保持向后兼容)
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

// Floating Action Button Style (悬浮按钮)
struct FloatingButtonStyle: ButtonStyle {
    var color: Color = AppColors.primary
    var size: CGFloat = 56
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 24, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            // Colored shadow
            .shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppAnimation.springBouncy, value: configuration.isPressed)
    }
}

// Primary button with gradient
struct GradientButtonStyle: ButtonStyle {
    var gradient: LinearGradient = AppColors.heroGradient
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodySemibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(gradient)
            )
            .shadow(color: AppColors.primary.opacity(0.3), radius: 12, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppAnimation.springSnappy, value: configuration.isPressed)
    }
}

// Primary button style (保持兼容)
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
            .animation(AppAnimation.springSnappy, value: configuration.isPressed)
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
            .animation(AppAnimation.springSnappy, value: configuration.isPressed)
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

// MARK: - View Extensions
extension View {
    func cardStyle(padding: CGFloat = AppSpacing.lg) -> some View {
        modifier(CardStyle(padding: padding))
    }
    
    func glassCard(padding: CGFloat = AppSpacing.lg, cornerRadius: CGFloat = AppRadius.xl) -> some View {
        modifier(GlassCardStyle(padding: padding, cornerRadius: cornerRadius))
    }
    
    func elevatedCard(padding: CGFloat = AppSpacing.lg, cornerRadius: CGFloat = AppRadius.xl) -> some View {
        modifier(ElevatedCardStyle(padding: padding, cornerRadius: cornerRadius))
    }
    
    func chipStyle(color: Color = AppColors.primary, isSelected: Bool = false) -> some View {
        modifier(ChipStyle(color: color, isSelected: isSelected))
    }
}

// MARK: - Reusable Components

// Icon circle background with gradient option
struct IconCircle: View {
    let icon: String
    var size: CGFloat = 48
    var iconSize: CGFloat = 22
    var color: Color = AppColors.primary
    var filled: Bool = false
    var gradient: LinearGradient? = nil
    
    var body: some View {
        ZStack {
            Circle()
                .fill(gradient ?? LinearGradient(colors: [filled ? color : color.opacity(0.12)], startPoint: .top, endPoint: .bottom))
                .frame(width: size, height: size)
            
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(filled || gradient != nil ? .white : color)
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
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.8), color.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
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
            .scaleEffect(isPulsing ? 1.3 : 1.0)
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

// Breathing animation circle (优化的呼吸动画)
struct BreathingCircle: View {
    let color: Color
    var size: CGFloat = 200
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Outer pulse
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size * 1.4, height: size * 1.4)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
            
            // Middle pulse
            Circle()
                .fill(color.opacity(0.25))
                .frame(width: size * 1.2, height: size * 1.2)
                .scaleEffect(isAnimating ? 1.05 : 0.95)
            
            // Inner circle with gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color, color.opacity(0.7)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)
        }
        .animation(
            .easeInOut(duration: 2.5)
            .repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// Stats Card with gradient accent
struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    var accentColor: Color = AppColors.primary
    var gradient: LinearGradient? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                IconCircle(
                    icon: icon,
                    size: 40,
                    iconSize: 18,
                    color: accentColor,
                    filled: true,
                    gradient: gradient
                )
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(value)
                    .font(AppTypography.displaySmall)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(title)
                    .font(AppTypography.subhead)
                    .foregroundColor(AppColors.textSecondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .elevatedCard()
    }
}

// Progress ring with animation
struct ProgressRing: View {
    var progress: Double
    var color: Color = AppColors.primary
    var lineWidth: CGFloat = 8
    var size: CGFloat = 100
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.5), color],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}
