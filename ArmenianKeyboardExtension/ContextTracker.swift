//
//  ContextTracker.swift
//  ArmenianKeyboardExtension
//
//  Tracks recent word history for context-aware predictions
//

import Foundation

class ContextTracker {

    // Store last N words for context
    private var wordHistory: [String] = []
    private let maxHistorySize = 5  // Track last 5 words for LSTM context

    /// Adds a word to the context history
    /// - Parameter word: The word to add (should be complete word, not partial)
    func addWord(_ word: String) {
        let cleanWord = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanWord.isEmpty else { return }

        // Add to history
        wordHistory.append(cleanWord)

        // Keep only last N words
        if wordHistory.count > maxHistorySize {
            wordHistory.removeFirst()
        }

    }

    /// Returns the most recent word (for bigram predictions)
    func getLastWord() -> String? {
        return wordHistory.last
    }

    /// Returns the last N words (for trigram+ predictions in future)
    func getLastWords(count: Int) -> [String] {
        let actualCount = min(count, wordHistory.count)
        return Array(wordHistory.suffix(actualCount))
    }

    /// Clears the context (e.g., on sentence boundary)
    func clear() {
        wordHistory.removeAll()
    }

    /// Returns the current word history for debugging
    func getHistory() -> [String] {
        return wordHistory
    }

    /// Checks if a character marks a sentence boundary
    static func isSentenceBoundary(_ char: String) -> Bool {
        let sentenceEnders: Set<Character> = [".", "!", "?", "\n", "։"]  // Include Armenian full stop ։
        return sentenceEnders.contains(char.first ?? " ")
    }
}
