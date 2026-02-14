//
//  DesignSystem.swift
//  MomMate
//
//  Modern minimalist design system — 现代极简
//

import SwiftUI
import Foundation

// MARK: - Semantic Colors (现代极简色彩)
struct AppColors {
    // Primary palette — 低饱和度、克制
    static let primary = Color(hex: "2C3E50")       // 深墨蓝
    static let secondary = Color(hex: "94A3B8")     // 冷灰蓝
    static let accent = Color(hex: "3D8B6E")        // 鼠尾草绿
    static let warning = Color(hex: "D4956A")       // 柔和琥珀
    
    // Semantic/Emotional colors (情绪色 — 低饱和)
    static let sleep = Color(hex: "5B6C9F")         // 静谧蓝紫
    static let awake = Color(hex: "C4855C")         // 柔暖橘
    static let meal = Color(hex: "3D8B6E")          // 鼠尾草绿
    static let milestone = Color(hex: "A85C6E")     // 柔玫红
    static let notes = Color(hex: "5A8296")         // 雾蓝
    
    // Backgrounds — 近纯白
    static let background = Color(hex: "FAFBFC")
    static let surface = Color.white
    static let surfaceSecondary = Color(hex: "F5F6F8")
    static let surfaceElevated = Color.white
    
    // Dark mode surfaces
    static let darkBackground = Color(hex: "0F172A")
    static let darkSurface = Color(hex: "1E293B")
    
    // Text — 三级灰度
    static let textPrimary = Color(hex: "1A1A2E")
    static let textSecondary = Color(hex: "6B7280")
    static let textTertiary = Color(hex: "B0B8C1")
    
    // Borders & Dividers — 极淡
    static let border = Color(hex: "E8EAED")
    static let divider = Color(hex: "F0F1F3")

    // Subtle tinted backgrounds for summary cards
    static let sleepTint = Color(hex: "5B6C9F").opacity(0.06)
    static let mealTint = Color(hex: "3D8B6E").opacity(0.06)
    static let milestoneTint = Color(hex: "A85C6E").opacity(0.06)
    
    // Soft dual-tone gradients
    static let sleepGradient = LinearGradient(
        colors: [Color(hex: "5B6C9F"), Color(hex: "7B8FBF")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let awakeGradient = LinearGradient(
        colors: [Color(hex: "C4855C"), Color(hex: "D9A87C")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let mealGradient = LinearGradient(
        colors: [Color(hex: "3D8B6E"), Color(hex: "5AAE8E")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let milestoneGradient = LinearGradient(
        colors: [Color(hex: "A85C6E"), Color(hex: "C47D8E")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let heroGradient = LinearGradient(
        colors: [Color(hex: "2C3E50"), Color(hex: "3E5871")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "FAFBFC"), Color(hex: "F0F2F5")],
        startPoint: .top, endPoint: .bottom
    )
    
    // Mesh gradient colors for iOS 17+
    static let meshColors: [Color] = [
        Color(hex: "5B6C9F"),
        Color(hex: "94A3B8"),
        Color(hex: "A85C6E"),
        Color(hex: "D4956A")
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
        formatter.locale = Locale(identifier: "zh_CN")
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

// MARK: - Typography (现代极简排版)
struct AppTypography {
    // 字体缩放比例 (默认 1.0)
    static var fontScale: CGFloat {
        let value = UserDefaults.standard.double(forKey: StorageKeys.fontSizeFactor)
        return value == 0 ? 1.0 : CGFloat(value)
    }
    
    private static func scaledFont(size: CGFloat, weight: Font.Weight, design: Font.Design = .default) -> Font {
        return Font.system(size: size * fontScale, weight: weight, design: design)
    }

    // Large Title — 锐利
    static var largeTitle: Font { scaledFont(size: 30, weight: .bold) }
    static var largeTitleSerif: Font { scaledFont(size: 30, weight: .bold, design: .serif) }
    
    // Titles
    static var title1: Font { scaledFont(size: 24, weight: .bold) }
    static var title2: Font { scaledFont(size: 20, weight: .semibold) }
    static var title3: Font { scaledFont(size: 18, weight: .semibold) }
    
    // Body
    static var body: Font { scaledFont(size: 15, weight: .regular) }
    static var bodyMedium: Font { scaledFont(size: 15, weight: .medium) }
    static var bodySemibold: Font { scaledFont(size: 15, weight: .semibold) }
    
    // Callout
    static var callout: Font { scaledFont(size: 14, weight: .regular) }
    static var calloutMedium: Font { scaledFont(size: 14, weight: .medium) }
    
    // Subhead
    static var subhead: Font { scaledFont(size: 13, weight: .regular) }
    static var subheadMedium: Font { scaledFont(size: 13, weight: .medium) }
    
    // Footnote
    static var footnote: Font { scaledFont(size: 13, weight: .regular) }
    static var footnoteMedium: Font { scaledFont(size: 13, weight: .medium) }
    
    // Caption
    static var caption: Font { scaledFont(size: 11, weight: .regular) }
    static var captionMedium: Font { scaledFont(size: 11, weight: .medium) }
    
    // Display (for large numbers) — 纤细高级感
    static var display: Font { scaledFont(size: 48, weight: .light) }
    static var displayMedium: Font { scaledFont(size: 36, weight: .light) }
    static var displaySmall: Font { scaledFont(size: 28, weight: .regular) }
    
    // Monospace for timers — 纤细等宽
    static var timer: Font { scaledFont(size: 42, weight: .light, design: .monospaced) }
    static var timerSmall: Font { scaledFont(size: 28, weight: .regular, design: .monospaced) }
}

// MARK: - Spacing (加大留白)
struct AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let xxl: CGFloat = 36
    static let xxxl: CGFloat = 48
    static let huge: CGFloat = 64
}

// MARK: - Corner Radius
struct AppRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 14
    static let xl: CGFloat = 18
    static let xxl: CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - Layered Shadows (极简化)
struct AppShadow {
    // 几乎不可见
    static let small = (
        color: Color.black.opacity(0.03),
        radius: CGFloat(2),
        x: CGFloat(0),
        y: CGFloat(1)
    )
    
    // 微弱感知
    static let medium = (
        color: Color.black.opacity(0.04),
        radius: CGFloat(4),
        x: CGFloat(0),
        y: CGFloat(2)
    )
    
    // 浮动元素
    static let large = (
        color: Color.black.opacity(0.06),
        radius: CGFloat(8),
        x: CGFloat(0),
        y: CGFloat(4)
    )
    
    // Dramatic depth
    static let xlarge = (
        color: Color.black.opacity(0.08),
        radius: CGFloat(16),
        x: CGFloat(0),
        y: CGFloat(8)
    )
    
    // Colored shadow (for buttons)
    static func colored(_ color: Color) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        return (color: color.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Animation Presets
struct AppAnimation {
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)
    static let springSmooth = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)
    static let easeOutQuick = Animation.easeOut(duration: 0.2)
    static let easeInOutMedium = Animation.easeInOut(duration: 0.35)
}

// MARK: - View Modifiers

// Minimal Card — 纯白底 + 超淡边框 + 微圆角
struct GlassCardStyle: ViewModifier {
    var padding: CGFloat = AppSpacing.lg
    var cornerRadius: CGFloat = AppRadius.xl
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(AppColors.border.opacity(0.5), lineWidth: 0.5)
                    )
            )
    }
}

// Elevated Card — 带极淡阴影
struct ElevatedCardStyle: ViewModifier {
    var padding: CGFloat = AppSpacing.lg
    var cornerRadius: CGFloat = AppRadius.xl
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColors.surface)
                    .shadow(
                        color: AppShadow.small.color,
                        radius: AppShadow.small.radius,
                        x: AppShadow.small.x,
                        y: AppShadow.small.y
                    )
            )
    }
}

// Legacy Card style
struct CardStyle: ViewModifier {
    var padding: CGFloat = AppSpacing.lg
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .fill(AppColors.surface)
            )
    }
}

// Floating Action Button Style — 带色阴影 + 弹性位移
struct FloatingButtonStyle: ButtonStyle {
    var color: Color = AppColors.primary
    var size: CGFloat = 52
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(color)
                    .shadow(
                        color: color.opacity(configuration.isPressed ? 0.15 : 0.3),
                        radius: configuration.isPressed ? 4 : 12,
                        x: 0,
                        y: configuration.isPressed ? 2 : 6
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(AppAnimation.springBouncy, value: configuration.isPressed)
    }
}

// Primary button — 胶囊形，纯色底
struct GradientButtonStyle: ButtonStyle {
    var gradient: LinearGradient = AppColors.heroGradient
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodySemibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Capsule()
                    .fill(AppColors.primary)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(AppAnimation.springSnappy, value: configuration.isPressed)
    }
}

// Primary button style — 胶囊形
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = AppColors.primary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodySemibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(color)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
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
                Capsule()
                    .fill(color.opacity(0.08))
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
                    .fill(isSelected ? color : color.opacity(0.08))
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

// Icon circle background
struct IconCircle: View {
    let icon: String
    var size: CGFloat = 44
    var iconSize: CGFloat = 20
    var color: Color = AppColors.primary
    var filled: Bool = false
    var gradient: LinearGradient? = nil
    
    var body: some View {
        ZStack {
            Circle()
                .fill(filled || gradient != nil ? color : color.opacity(0.08))
                .frame(width: size, height: size)
            
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
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
                .font(AppTypography.calloutMedium)
                .foregroundColor(AppColors.textSecondary)
                .textCase(.none)
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
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
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundColor(color.opacity(0.5))
            
            Text(title)
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            Text(subtitle)
                .font(AppTypography.subhead)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
    }
}

// Pulsing circle (sleeping indicator)
struct PulsingCircle: View {
    let color: Color
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(color.opacity(0.2))
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0 : 0.4)
            .animation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: false),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// Breathing animation circle — 三层涟漪
struct BreathingCircle: View {
    let color: Color
    var size: CGFloat = 140
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Outermost pulse — delayed
            Circle()
                .fill(color.opacity(0.04))
                .frame(width: size * 1.5, height: size * 1.5)
                .scaleEffect(isAnimating ? 1.08 : 0.92)
                .animation(
                    .easeInOut(duration: 3.5)
                    .repeatForever(autoreverses: true)
                    .delay(0.5),
                    value: isAnimating
                )
            
            // Middle pulse
            Circle()
                .fill(color.opacity(0.06))
                .frame(width: size * 1.3, height: size * 1.3)
                .scaleEffect(isAnimating ? 1.06 : 0.96)
            
            // Inner circle
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: size, height: size)
        }
        .animation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// Stats Card
struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    var accentColor: Color = AppColors.primary
    var gradient: LinearGradient? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            IconCircle(
                icon: icon,
                size: 36,
                iconSize: 16,
                color: accentColor,
                filled: true,
                gradient: gradient
            )
            
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
        .glassCard()
    }
}

// Progress ring
struct ProgressRing: View {
    var progress: Double
    var color: Color = AppColors.primary
    var lineWidth: CGFloat = 6
    var size: CGFloat = 100
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.08), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
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

// MARK: - Animated Counter (数字弹跳)
struct AnimatedCounter: View {
    let value: Int
    let font: Font
    let color: Color
    
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText())
            .onAppear { 
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Haptic Feedback
enum HapticManager {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Swipe to Delete 行包装
struct SwipeDeleteRow<Content: View>: View {
    let onDelete: () -> Void
    let content: Content
    
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    
    init(onDelete: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onDelete = onDelete
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // 删除按钮（底层）
            HStack(spacing: 0) {
                Spacer()
                Button {
                    HapticManager.medium()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        offset = -UIScreen.main.bounds.width
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        onDelete()
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .medium))
                        Text("删除")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(width: 72)
                    .frame(maxHeight: .infinity)
                    .background(Color.red.opacity(0.85))
                }
            }
            
            // 内容层（可滑动）
            content
                .background(AppColors.surface)
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onChanged { value in
                            let dx = value.translation.width
                            if dx < 0 {
                                // 左滑
                                offset = max(dx, -120)
                            } else if isSwiped {
                                // 右滑回弹
                                offset = min(-72 + dx, 0)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if value.translation.width < -100 && value.velocity.width < -300 {
                                    // 快速全滑 → 直接删除
                                    offset = -UIScreen.main.bounds.width
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        HapticManager.medium()
                                        onDelete()
                                    }
                                } else if value.translation.width < -40 {
                                    // 停留在删除按钮位
                                    offset = -72
                                    isSwiped = true
                                    HapticManager.light()
                                } else {
                                    // 回弹
                                    offset = 0
                                    isSwiped = false
                                }
                            }
                        }
                )
        }
        .clipped()
    }
}
