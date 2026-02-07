import SwiftUI

struct SettingsView: View {
    @AppStorage("fontSizeFactor") private var fontSizeFactor: Double = 1.0
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // 预览卡片
                        VStack(spacing: AppSpacing.md) {
                            Text("预览效果")
                                .font(AppTypography.subheadMedium)
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: AppSpacing.sm) {
                                Text("这是一段预览文字")
                                    .font(AppTypography.title2)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text("调整下方的滑块可以改变全屏文字的大小。")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(AppSpacing.lg)
                            .frame(maxWidth: .infinity)
                            .background(AppColors.surface)
                            .cornerRadius(AppRadius.lg)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        
                        // 调节滑块
                        VStack(spacing: AppSpacing.md) {
                            Text("文字大小调节")
                                .font(AppTypography.subheadMedium)
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: AppSpacing.lg) {
                                HStack {
                                    Image(systemName: "textformat.size.smaller")
                                        .font(.system(size: 14))
                                    
                                    Slider(value: $fontSizeFactor, in: 0.8...1.5, step: 0.1)
                                        .tint(AppColors.primary)
                                    
                                    Image(systemName: "textformat.size.larger")
                                        .font(.system(size: 20))
                                }
                                
                                Text(String(format: "当前缩放: %.1fx", fontSizeFactor))
                                    .font(AppTypography.footnoteMedium)
                                    .foregroundColor(AppColors.primary)
                            }
                            .padding(AppSpacing.lg)
                            .background(AppColors.surface)
                            .cornerRadius(AppRadius.lg)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        
                        // 说明
                        Text("调整后，App 内的所有文字大小将随之变化。")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.horizontal, AppSpacing.xl)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, AppSpacing.xl)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
