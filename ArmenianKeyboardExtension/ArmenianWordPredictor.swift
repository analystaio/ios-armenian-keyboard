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
        for (word, frequency) in words {
            trie.insert(word, frequency: frequency)
        }

        isLoaded = true
    }

    // Get word suggestions for a prefix
    func getSuggestions(for prefix: String, limit: Int = 3) -> [String] {
        guard !prefix.isEmpty else { return [] }

        let suggestions = trie.findWordsWithPrefix(prefix, limit: limit)

        // If no suggestions, try lowercase
        if suggestions.isEmpty {
            return trie.findWordsWithPrefix(prefix.lowercased(), limit: limit)
        }

        return suggestions
    }

    // Check if word exists in dictionary
    func wordExists(_ word: String) -> Bool {
        return trie.search(word)
    }
}
