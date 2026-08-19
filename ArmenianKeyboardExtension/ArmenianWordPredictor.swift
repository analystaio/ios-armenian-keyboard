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

    private func loadDictionary() {
        guard !isLoaded else { return }

        let words = ArmenianDictionary.commonWords
        for (word, frequency) in words {
            trie.insert(word, frequency: frequency)
        }

        isLoaded = true
    }

    /// Normalize the ech-yiwn ligature և (U+0587) → ե + ւ (U+0565 + U+0582).
    ///
    /// The dictionary stores the two letters separately, matching what the keys
    /// produce, so a և typed from the hold-for-alternates popup has to be
    /// decomposed before it will match anything.
    private func normalize(_ s: String) -> String {
        return s.replacingOccurrences(of: "\u{0587}", with: "\u{0565}\u{0582}")
    }

    func getSuggestions(for prefix: String, limit: Int = 3) -> [String] {
        guard !prefix.isEmpty else { return [] }

        let prefix = normalize(prefix)
        let suggestions = trie.findWordsWithPrefix(prefix, limit: limit)

        if suggestions.isEmpty {
            return trie.findWordsWithPrefix(prefix.lowercased(), limit: limit)
        }

        return suggestions
    }

    func wordExists(_ word: String) -> Bool {
        return trie.search(normalize(word))
    }
}
