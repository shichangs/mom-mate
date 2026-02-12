//
//  NotesView.swift
//  MomMate
//
//  Notes view — 现代极简风格
//

import SwiftUI

struct NotesView: View {
    @ObservedObject var notesManager: NotesManager
    @Environment(\.dismiss) var dismiss
    @State private var isEditing = false
    @State private var editedNotes: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                if isEditing {
                    ScrollView {
                        TextEditor(text: $editedNotes)
                            .font(.system(.body, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .cornerRadius(AppRadius.lg)
                            .focused($isFocused)
                            .frame(minHeight: 400)
                            .padding(AppSpacing.lg)
                    }
                } else {
                    ScrollView {
                        MarkdownTextView(text: notesManager.notes)
                            .padding(AppSpacing.lg)
                    }
                }
            }
            .navigationTitle("开发者文档")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("取消") {
                            editedNotes = notesManager.notes
                            isEditing = false
                            isFocused = false
                        }
                    } else {
                        Button("完成") {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("保存") {
                            notesManager.notes = editedNotes
                            notesManager.saveNotes()
                            isEditing = false
                            isFocused = false
                        }
                        .fontWeight(.semibold)
                    } else {
                        Button(action: {
                            editedNotes = notesManager.notes
                            isEditing = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isFocused = true
                            }
                        }) {
                            Image(systemName: "pencil")
                        }
                    }
                }
            }
            .onAppear {
                editedNotes = notesManager.notes
            }
        }
    }
}

// MARK: - Markdown 文本视图
struct MarkdownTextView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ForEach(parseMarkdown(text), id: \.id) { block in
                renderBlock(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.xl)
    }

    private func parseMarkdown(_ text: String) -> [TextBlock] {
        var blocks: [TextBlock] = []
        let lines = text.components(separatedBy: .newlines)
        var currentBlock: TextBlock?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                if let block = currentBlock {
                    blocks.append(block)
                    currentBlock = nil
                }
                continue
            }

            if trimmed.hasPrefix("# ") {
                if let block = currentBlock { blocks.append(block) }
                currentBlock = TextBlock(type: .h1, content: String(trimmed.dropFirst(2)))
            } else if trimmed.hasPrefix("## ") {
                if let block = currentBlock { blocks.append(block) }
                currentBlock = TextBlock(type: .h2, content: String(trimmed.dropFirst(3)))
            } else if trimmed.hasPrefix("### ") {
                if let block = currentBlock { blocks.append(block) }
                currentBlock = TextBlock(type: .h3, content: String(trimmed.dropFirst(4)))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                if let block = currentBlock, block.type == .list {
                    currentBlock?.content += "\n" + String(trimmed.dropFirst(2))
                } else {
                    if let block = currentBlock { blocks.append(block) }
                    currentBlock = TextBlock(type: .list, content: String(trimmed.dropFirst(2)))
                }
            } else if trimmed.hasPrefix("```") {
                continue
            } else {
                if let block = currentBlock, block.type == .paragraph {
                    currentBlock?.content += "\n" + trimmed
                } else {
                    if let block = currentBlock { blocks.append(block) }
                    currentBlock = TextBlock(type: .paragraph, content: trimmed)
                }
            }
        }

        if let block = currentBlock {
            blocks.append(block)
        }

        return blocks
    }

    @ViewBuilder
    private func renderBlock(_ block: TextBlock) -> some View {
        switch block.type {
        case .h1:
            Text(block.content)
                .font(AppTypography.title1)
                .foregroundColor(AppColors.textPrimary)
                .padding(.bottom, AppSpacing.xs)
        case .h2:
            Text(block.content)
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, AppSpacing.xs)
                .padding(.bottom, AppSpacing.xxs)
        case .h3:
            Text(block.content)
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, AppSpacing.xxs)
        case .paragraph:
            Text(block.content)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(6)
                .padding(.vertical, AppSpacing.xxs)
        case .list:
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(block.content.components(separatedBy: "\n"), id: \.self) { item in
                    HStack(alignment: .top, spacing: AppSpacing.xs) {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(item)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(.vertical, AppSpacing.xxs)
        }
    }
}

// MARK: - 文本块类型
enum TextBlockType {
    case h1, h2, h3, paragraph, list
}

struct TextBlock: Identifiable {
    let id = UUID()
    let type: TextBlockType
    var content: String
}
