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
    private var isShifted = false
    private var isCapsLocked = false
    private var isNumbersMode = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()

        // TEST: Comprehensive debug test
        print("===== COMPREHENSIVE TEST START =====")
        print("Testing Trie directly...")
        let testTrie = Trie()
        testTrie.insert("ես", frequency: 100)
        testTrie.insert("երեխա", frequency: 90)
        testTrie.insert("եղել", frequency: 85)
        let trieResults = testTrie.findWordsWithPrefix("ե", limit: 3)
        print("Direct Trie test for 'ե': \(trieResults)")

        print("\nTesting word predictor...")
        let predictorResults = wordPredictor.getSuggestions(for: "ե", limit: 3)
        print("Word predictor test for 'ե': \(predictorResults)")

        print("\nTesting with uppercase...")
        let uppercaseResults = wordPredictor.getSuggestions(for: "Ե", limit: 3)
        print("Word predictor test for 'Ե': \(uppercaseResults)")

        print("===== COMPREHENSIVE TEST END =====")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateKeyboardAppearance()

        // TEST: Verify word predictor works
        print("DEBUG: viewWillAppear - testing word predictor")
        let testSuggestions = wordPredictor.getSuggestions(for: "ե", limit: 3)
        print("DEBUG: Test suggestions for 'ե': \(testSuggestions)")

        // Show initial suggestions
        if testSuggestions.isEmpty {
            suggestionBar.updateSuggestions(["բարև", "ողջույն", "շնորհակալ"])
        } else {
            suggestionBar.updateSuggestions(testSuggestions)
        }
    }

    override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        print("DEBUG: textDidChange called")
        print("DEBUG: documentContextBeforeInput = '\(textDocumentProxy.documentContextBeforeInput ?? "nil")'")
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
        // Custom background color
        view.backgroundColor = UIColor(hex: "#2B2B2B")
    }

    // MARK: - Suggestions
    private func updateSuggestions() {
        print("DEBUG: updateSuggestions() called")

        guard let currentWord = getCurrentWord() else {
            print("DEBUG: getCurrentWord() returned nil - not clearing suggestions")
            // Don't clear suggestions when there's no context (e.g., empty text field)
            return
        }

        print("DEBUG: currentWord = '\(currentWord)' (length: \(currentWord.count))")

        // Only get suggestions if the word is at least 1 character
        guard !currentWord.isEmpty else {
            print("DEBUG: currentWord is empty - clearing suggestions")
            suggestionBar.updateSuggestions([])
            return
        }

        print("DEBUG: Calling wordPredictor.getSuggestions(for: '\(currentWord)')")
        let suggestions = wordPredictor.getSuggestions(for: currentWord, limit: 3)
        print("DEBUG: Got \(suggestions.count) suggestions: \(suggestions)")

        suggestionBar.updateSuggestions(suggestions)
        print("DEBUG: Updated suggestion bar with suggestions")

        // Debug: print to console
        print("Current word: '\(currentWord)', Suggestions: \(suggestions)")
    }

    private func getCurrentWord() -> String? {
        guard let documentContext = textDocumentProxy.documentContextBeforeInput else {
            print("DEBUG: getCurrentWord() - documentContextBeforeInput is nil")
            return nil
        }

        print("DEBUG: getCurrentWord() - documentContext = '\(documentContext)'")
        let components = documentContext.components(separatedBy: .whitespacesAndNewlines)
        print("DEBUG: getCurrentWord() - components = \(components)")
        let lastComponent = components.last?.isEmpty == false ? components.last : nil
        print("DEBUG: getCurrentWord() - returning '\(lastComponent ?? "nil")'")
        return lastComponent
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

            // Update suggestions after inserting character
            updateSuggestions()

        case .delete:
            textDocumentProxy.deleteBackward()

            // Update suggestions after deleting character
            updateSuggestions()

        case .shift:
            handleShift()

        case .globe:
            advanceToNextInputMode()

        case .space:
            textDocumentProxy.insertText(" ")

            // Clear suggestions after space
            suggestionBar.updateSuggestions([])

        case .return:
            textDocumentProxy.insertText("\n")

            // Clear suggestions after return
            suggestionBar.updateSuggestions([])

        case .numbers:
            toggleNumbersMode()

        case .emoji:
            // Open emoji keyboard
            if #available(iOS 10.0, *) {
                performSelector(inBackground: #selector(advanceToNextInputMode), with: nil)
            }
        }
    }

    private func handleShift() {
        if isCapsLocked {
            // Third tap = turn off caps lock
            isCapsLocked = false
            isShifted = false
        } else if isShifted {
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
