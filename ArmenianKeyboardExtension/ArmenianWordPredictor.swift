//
//  ArmenianWordPredictor.swift
//  ArmenianKeyboardExtension
//
//  Armenian word prediction using Trie
//

import Foundation

class ArmenianWordPredictor {
    private let trie = Trie()
    private var isLoaded = false

    init() {
        loadDictionary()
    }

    // Load Armenian dictionary
    private func loadDictionary() {
        guard !isLoaded else { return }

        // Load from embedded dictionary
        let words = ArmenianDictionary.commonWords
        print("DEBUG: Loading \(words.count) words into dictionary")
        for (word, frequency) in words {
            trie.insert(word, frequency: frequency)
        }

        isLoaded = true
        print("DEBUG: Dictionary loaded successfully")
    }

    // Get word suggestions for a prefix
    func getSuggestions(for prefix: String, limit: Int = 3) -> [String] {
        print("DEBUG: getSuggestions called with prefix: '\(prefix)'")
        guard !prefix.isEmpty else {
            print("DEBUG: Prefix is empty, returning []")
            return []
        }

        let suggestions = trie.findWordsWithPrefix(prefix, limit: limit)
        print("DEBUG: Trie returned \(suggestions.count) suggestions: \(suggestions)")

        // If no suggestions, try lowercase
        if suggestions.isEmpty {
            let lowercaseSuggestions = trie.findWordsWithPrefix(prefix.lowercased(), limit: limit)
            print("DEBUG: Tried lowercase, got \(lowercaseSuggestions.count) suggestions: \(lowercaseSuggestions)")
            return lowercaseSuggestions
        }

        return suggestions
    }

    // Check if word exists in dictionary
    func wordExists(_ word: String) -> Bool {
        return trie.search(word)
    }
}
