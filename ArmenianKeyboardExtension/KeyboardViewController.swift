//
//  KeyboardViewController.swift
//  ArmenianKeyboardExtension
//
//  Main keyboard extension controller
//

import UIKit

class KeyboardViewController: UIInputViewController {

    // MARK: - Properties
    private var keyboardView: ArmenianKeyboardView!
    private var suggestionBar: SuggestionBar!
    private let armenianLayout = ArmenianKeyboardLayout()
    private let wordPredictor = ArmenianWordPredictor()
    private var isShifted = false
    private var isCapsLocked = false
    private var isNumbersMode = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateKeyboardAppearance()
    }

    override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateSuggestions()
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
    }

    private func updateKeyboardAppearance() {
        // Match system keyboard appearance (light/dark mode)
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
                    : UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1.0)
            }
        } else {
            view.backgroundColor = UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1.0)
        }
    }

    // MARK: - Suggestions
    private func updateSuggestions() {
        guard let currentWord = getCurrentWord() else {
            suggestionBar.updateSuggestions([])
            return
        }

        // Only get suggestions if the word is at least 1 character
        guard !currentWord.isEmpty else {
            suggestionBar.updateSuggestions([])
            return
        }

        let suggestions = wordPredictor.getSuggestions(for: currentWord, limit: 3)
        suggestionBar.updateSuggestions(suggestions)

        // Debug: print to console
        print("Current word: '\(currentWord)', Suggestions: \(suggestions)")
    }

    private func getCurrentWord() -> String? {
        guard let documentContext = textDocumentProxy.documentContextBeforeInput else {
            return nil
        }

        let components = documentContext.components(separatedBy: .whitespacesAndNewlines)
        return components.last?.isEmpty == false ? components.last : nil
    }

    private func insertSuggestion(_ suggestion: String) {
        // Delete current word
        if let currentWord = getCurrentWord() {
            for _ in 0..<currentWord.count {
                textDocumentProxy.deleteBackward()
            }
        }

        // Insert suggestion
        textDocumentProxy.insertText(suggestion)
        textDocumentProxy.insertText(" ")

        // Update suggestions
        suggestionBar.updateSuggestions([])
    }
}

// MARK: - ArmenianKeyboardViewDelegate
extension KeyboardViewController: ArmenianKeyboardViewDelegate {
    func didTapKey(_ key: KeyboardKey) {
        switch key.type {
        case .character(let char):
            let output = isShifted || isCapsLocked ? char.uppercased() : char.lowercased()
            textDocumentProxy.insertText(output)

            // Reset shift if not caps locked
            if isShifted && !isCapsLocked {
                isShifted = false
                keyboardView.updateShiftState(isShifted: isShifted, isCapsLocked: isCapsLocked)
            }

        case .delete:
            textDocumentProxy.deleteBackward()

        case .shift:
            handleShift()

        case .globe:
            advanceToNextInputMode()

        case .space:
            textDocumentProxy.insertText(" ")

        case .return:
            textDocumentProxy.insertText("\n")

        case .numbers:
            toggleNumbersMode()
        }
    }

    private func handleShift() {
        if isShifted {
            // Second tap = caps lock
            isCapsLocked = true
            isShifted = true
        } else {
            // First tap = shift
            isShifted = true
            isCapsLocked = false
        }

        keyboardView.updateShiftState(isShifted: isShifted, isCapsLocked: isCapsLocked)
    }

    private func toggleNumbersMode() {
        isNumbersMode.toggle()
        keyboardView.setNumbersMode(isNumbersMode)
    }
}
