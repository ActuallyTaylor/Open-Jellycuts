//
//  RunestoneEditor.swift
//  Jellycuts
//
//  Created by Taylor Lineman on 5/17/23.
//

import UIKit
import SwiftUI
import Runestone
import TreeSitterJellyRunestone
import RunestoneThemes

struct RunestoneEditor: UIViewRepresentable {
    final class EditorCharacterPair: CharacterPair {
        let leading: String
        let trailing: String

        init(leading: String, trailing: String) {
            self.leading = leading
            self.trailing = trailing
        }
    }

    @StateObject var config: RunestoneEditorConfig
    @Binding var text: String
    @State var lastTheme: EditorTheme
    var interactionEnabled: Bool = false
    
    init(text: Binding<String>, config: RunestoneEditorConfig, interactionEnabled: Bool = true) {
        self._text = text
        self._config = StateObject(wrappedValue: config)
        lastTheme = config.currentTheme
        self.interactionEnabled = interactionEnabled
    }
    
    func makeUIView(context: Context) -> TextView {
        let textView: TextView = TextView()
        setState(text: text, textView: textView)
        setCustomization(textView: textView)
        textView.editorDelegate = context.coordinator
        textView.isUserInteractionEnabled = interactionEnabled
        
        return textView
    }
    
    func updateUIView(_ uiView: TextView, context: Context) {
        if text != uiView.text {
            setState(text: text, textView: uiView)
        }
        
        if config.currentTheme.id != lastTheme.id {
            DispatchQueue.main {
                lastTheme = config.currentTheme
            }
            setState(text: text, textView: uiView)
            uiView.backgroundColor = config.currentTheme.backgroundColor
        }
        
        if config.insertText != nil {
            uiView.insertText(config.consumeInsert())
        }
        
        if config.redoFlag > 0 {
            config.consumeRedo()
            uiView.undoManager?.redo()
        }
        
        if config.undoFlag > 0 {
            config.consumeUndo()
            uiView.undoManager?.undo()
        }
    }
    
    private func setState(text: String, textView: TextView) {
        let state = TextViewState(text: text, theme: config.currentTheme.runestoneTheme, language: .jelly)
        textView.setState(state)
    }
    
    private func setCustomization(textView: TextView) {
        textView.backgroundColor = config.currentTheme.backgroundColor
        textView.selectionHighlightColor = config.currentTheme.tintColor.withAlphaComponent(0.2)
        textView.selectionBarColor = config.currentTheme.tintColor
        textView.insertionPointColor = config.currentTheme.tintColor
        
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        textView.showLineNumbers = true
        textView.lineHeightMultiplier = 1.2
        textView.kern = 0.3
        textView.showSpaces = true
        textView.showNonBreakingSpaces = true
        textView.showTabs = true
        textView.showLineBreaks = true
        textView.showSoftLineBreaks = true
        textView.isLineWrappingEnabled = false
        textView.showPageGuide = true
        textView.pageGuideColumn = 80
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.isEditable = true
        textView.characterPairs = [
            EditorCharacterPair(leading: "\"", trailing: "\""),
            EditorCharacterPair(leading: "'", trailing: "'"),
            EditorCharacterPair(leading: "{", trailing: "}"),
            EditorCharacterPair(leading: "(", trailing: ")")
        ]
        textView.characterPairTrailingComponentDeletionMode = .immediatelyFollowingLeadingComponent
        textView.indentStrategy = .space(length: 4)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: TextViewDelegate {
        let parent: RunestoneEditor

        init(_ parent: RunestoneEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: TextView) {
            DispatchQueue.main {
                self.parent.text = textView.text
                self.updateRedoAndUndoButtons(textView)
            }
        }
        
        func updateRedoAndUndoButtons(_ textView: TextView) {
            self.parent.config.canRedo = textView.undoManager?.canRedo ?? false
            self.parent.config.canUndo = textView.undoManager?.canUndo ?? false
        }
    }
}
