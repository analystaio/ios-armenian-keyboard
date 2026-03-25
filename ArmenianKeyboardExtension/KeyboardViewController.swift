//
//  KeyboardViewController.swift
//  ArmenianKeyboardExtension
//
//  Main keyboard extension controller
//

import UIKit

extension UIColor {
    convenience init(hex: String) {
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

class KeyboardViewController: UIInputViewController {

    // MARK: - Properties
    private var keyboardView: ArmenianKeyboardView!
    private var suggestionBar: SuggestionBar!
    private let armenianLayout = ArmenianKeyboardLayout()
    private let wordPredictor = ArmenianWordPredictor()
    private let ngramPredictor = NGramPredictor()
    private let contextTracker = ContextTracker()
    private var isShifted = false
    private var isCapsLocked = false
    private var isNumbersMode = false

    // Auto-correction undo state
    private var lastAutoInsertedWord: String?
    private var lastOriginalWord: String?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateKeyboardAppearance()
        checkAutoCapitalization()
        updateSuggestions()
    }

    override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateSuggestions()
        checkAutoCapitalization()
    }

    // MARK: - Setup
    private func setupKeyboard() {
        // Setup suggestion bar
        suggestionBar = SuggestionBar()
        suggestionBar.translatesAutoresizingMaskIntoConstraints = false
        suggestionBar.onSuggestionTapped = { [weak self] suggestion in
            self?.insertSuggestion(suggestion)
        }
        view.addSubview(suggestionBar)

        // Setup keyboard view
        keyboardView = ArmenianKeyboardView(layout: armenianLayout)
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        keyboardView.delegate = self
        keyboardView.showGlobeKey = false
        view.addSubview(keyboardView)

        // Layout constraints
        NSLayoutConstraint.activate([
            suggestionBar.topAnchor.constraint(equalTo: view.topAnchor),
            suggestionBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionBar.heightAnchor.constraint(equalToConstant: 44),

            keyboardView.topAnchor.constraint(equalTo: suggestionBar.bottomAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Refresh suggestions once n-gram model finishes loading
        ngramPredictor.onReady = { [weak self] in
            self?.updateSuggestions()
        }
    }

    private func updateKeyboardAppearance() {
        view.backgroundColor = KeyboardColors.background
    }

    // MARK: - Auto-Capitalization
    private func checkAutoCapitalization() {
        // Don't interfere with caps lock
        guard !isCapsLocked else { return }

        let context = textDocumentProxy.documentContextBeforeInput

        // Empty document or start of text — capitalize first letter
        if context == nil || context!.isEmpty {
            if !isShifted {
                isShifted = true
                keyboardView.updateShiftState(isShifted: isShifted, isCapsLocked: isCapsLocked)
            }
            return
        }

        // After a newline
        if context!.hasSuffix("\n") {
            if !isShifted {
                isShifted = true
                keyboardView.updateShiftState(isShifted: isShifted, isCapsLocked: isCapsLocked)
            }
            return
        }

        // After sentence-ending punctuation followed by space
        if context!.hasSuffix(" ") {
            let trimmed = context!.dropLast() // remove the trailing space
            if let lastChar = trimmed.last {
                let sentenceEnders: Set<Character> = [".", "!", "?", "։"]
                if sentenceEnders.contains(lastChar) {
                    if !isShifted {
                        isShifted = true
                        keyboardView.updateShiftState(isShifted: isShifted, isCapsLocked: isCapsLocked)
                    }
                    return
                }
            }
        }
    }

    // MARK: - Suggestions
    private func updateSuggestions() {
        // Check if document is completely empty (all text deleted)
        let documentContext = textDocumentProxy.documentContextBeforeInput
        if documentContext != nil && documentContext!.isEmpty {
            suggestionBar.updateSuggestions([])
            return
        }

        var suggestions: [String] = []

        // Scenario 1: User is typing a word (prefix completion)
        if let currentWord = getCurrentWord(), !currentWord.isEmpty {
            suggestions = wordPredictor.getSuggestions(for: currentWord, limit: 3)
        }
        // Scenario 2: User just finished a word (next word prediction)
        else if contextTracker.getLastWord() != nil {
            let context = contextTracker.getLastWords(count: 3)
            suggestions = ngramPredictor.predictNext(context: context, limit: 3)
        }

        suggestionBar.updateSuggestions(suggestions)
    }

    private func getCurrentWord() -> String? {
        guard let documentContext = textDocumentProxy.documentContextBeforeInput else {
            return nil
        }
        let components = documentContext.components(separatedBy: .whitespacesAndNewlines)
        return components.last?.isEmpty == false ? components.last : nil
    }

    private func insertSuggestion(_ suggestion: String) {
        // Clear any pending auto-correct undo
        lastAutoInsertedWord = nil
        lastOriginalWord = nil

        // Delete current word
        if let currentWord = getCurrentWord() {
            for _ in 0..<currentWord.count {
                textDocumentProxy.deleteBackward()
            }
        }

        // Insert suggestion + space
        textDocumentProxy.insertText(suggestion)
        textDocumentProxy.insertText(" ")

        contextTracker.addWord(suggestion)
        updateSuggestions()
        checkAutoCapitalization()
    }
}

// MARK: - ArmenianKeyboardViewDelegate
extension KeyboardViewController: ArmenianKeyboardViewDelegate {
    func didTapKey(_ key: KeyboardKey) {
        switch key.type {
        case .character(let char):
            let output = isShifted || isCapsLocked ? char.uppercased() : char.lowercased()
            textDocumentProxy.insertText(output)

            // Clear context on sentence boundaries (., !, ?, ։)
            if ContextTracker.isSentenceBoundary(char) {
                contextTracker.clear()
            }

            // Reset shift if not caps locked
            if isShifted && !isCapsLocked {
                isShifted = false
                keyboardView.updateShiftState(isShifted: isShifted, isCapsLocked: isCapsLocked)
            }

            // Clear auto-correct undo state (user continued typing)
            lastAutoInsertedWord = nil
            lastOriginalWord = nil

            updateSuggestions()

        case .delete:
            // Check if we should undo an auto-correction (backspace right after auto-correct + space)
            if let autoWord = lastAutoInsertedWord, let originalWord = lastOriginalWord {
                let context = textDocumentProxy.documentContextBeforeInput ?? ""
                if context.hasSuffix(" ") {
                    // Undo: remove space, remove auto-corrected word, restore original
                    textDocumentProxy.deleteBackward() // remove space
                    for _ in 0..<autoWord.count {
                        textDocumentProxy.deleteBackward()
                    }
                    textDocumentProxy.insertText(originalWord)

                    lastAutoInsertedWord = nil
                    lastOriginalWord = nil

                    updateSuggestions()
                    checkAutoCapitalization()
                    return
                }
            }

            // Normal delete
            textDocumentProxy.deleteBackward()
            lastAutoInsertedWord = nil
            lastOriginalWord = nil

            updateSuggestions()
            checkAutoCapitalization()

        case .shift:
            handleShift()

        case .globe:
            advanceToNextInputMode()

        case .space:
            // Auto-insert top suggestion if the user is typing and there's a better match
            if let currentWord = getCurrentWord(), !currentWord.isEmpty {
                let suggestions = wordPredictor.getSuggestions(for: currentWord, limit: 3)

                if let topSuggestion = suggestions.first,
                   topSuggestion.lowercased() != currentWord.lowercased(),
                   currentWord.count >= 2 {
                    // Replace typed word with top suggestion
                    for _ in 0..<currentWord.count {
                        textDocumentProxy.deleteBackward()
                    }
                    textDocumentProxy.insertText(topSuggestion)

                    // Store undo state
                    lastAutoInsertedWord = topSuggestion
                    lastOriginalWord = currentWord

                    contextTracker.addWord(topSuggestion)
                } else {
                    contextTracker.addWord(currentWord)
                    lastAutoInsertedWord = nil
                    lastOriginalWord = nil
                }
            } else {
                lastAutoInsertedWord = nil
                lastOriginalWord = nil
            }

            textDocumentProxy.insertText(" ")
            updateSuggestions()
            checkAutoCapitalization()

        case .return:
            textDocumentProxy.insertText("\n")
            contextTracker.clear()
            lastAutoInsertedWord = nil
            lastOriginalWord = nil
            suggestionBar.updateSuggestions([])
            checkAutoCapitalization()

        case .numbers:
            toggleNumbersMode()

        case .emoji:
            advanceToNextInputMode()
        }
    }

    private func handleShift() {
        if isCapsLocked {
            isCapsLocked = false
            isShifted = false
        } else if isShifted {
            isCapsLocked = true
            isShifted = true
        } else {
            isShifted = true
            isCapsLocked = false
        }

        keyboardView.updateShiftState(isShifted: isShifted, isCapsLocked: isCapsLocked)
    }

    private func toggleNumbersMode() {
        isNumbersMode.toggle()
        keyboardView.setNumbersMode(isNumbersMode)
    }

    func didMoveCursor(byOffset offset: Int) {
        textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
    }
}
