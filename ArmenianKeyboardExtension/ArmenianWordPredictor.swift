//
//  ArmenianWordPredictor.swift
//  ArmenianKeyboardExtension
//
//  Prefix completion for the active dialect, re-ranked by what the user has
//  typed before.
//
//  Eastern: the 1,500-word `ArmenianDictionary` in a Trie (built in-memory).
//  Western: the 120K-form `western_words.tsv` in a `SortedWordList`, loaded
//  off the main thread because it is a few megabytes.
//

import Foundation

class ArmenianWordPredictor {

    let dialect: ArmenianDialect
    private let learning: UserLearningStore

    private var trie: Trie?
    private var wordList: SortedWordList?

    /// Called on the main thread once an asynchronously loaded dictionary is in.
    var onReady: (() -> Void)?

    init(dialect: ArmenianDialect, learning: UserLearningStore) {
        self.dialect = dialect
        self.learning = learning
        load()
    }

    private func load() {
        switch dialect {
        case .eastern:
            let t = Trie()
            for (word, frequency) in ArmenianDictionary.commonWords {
                t.insert(word, frequency: frequency)
            }
            trie = t
        case .western:
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let url = Bundle.main.url(forResource: "western_words", withExtension: "tsv"),
                      let list = SortedWordList(contentsOf: url) else { return }
                DispatchQueue.main.async {
                    self?.wordList = list
                    self?.onReady?()
                }
            }
        }
    }

    var isReady: Bool {
        trie != nil || wordList != nil
    }

    /// Lowercase, decompose the և ligature (U+0587 → ե + ւ, matching what the
    /// keys produce) and unify apostrophes to the Armenian ՚ (U+055A) that the
    /// Western dictionary uses for forms like կ՚ըսէ.
    private func normalize(_ s: String) -> String {
        return s.lowercased()
            .replacingOccurrences(of: "\u{0587}", with: "\u{0565}\u{0582}")
            .replacingOccurrences(of: "'", with: "\u{055A}")
            .replacingOccurrences(of: "\u{2019}", with: "\u{055A}")
    }

    private func dictionaryCandidates(_ prefix: String, limit: Int) -> [(word: String, score: Int)] {
        if let t = trie {
            return t.findScoredWordsWithPrefix(prefix, limit: limit).map { ($0.word, $0.frequency) }
        }
        if let l = wordList {
            return l.candidates(prefix: prefix, limit: limit)
        }
        return []
    }

    func getSuggestions(for rawPrefix: String, limit: Int = 3) -> [String] {
        guard !rawPrefix.isEmpty else { return [] }
        let prefix = normalize(rawPrefix)

        // Dictionary words, boosted by how often the user has typed them
        var scored: [String: Int] = [:]
        for c in dictionaryCandidates(prefix, limit: max(12, limit * 4)) {
            scored[c.word] = c.score + learning.boost(for: c.word)
        }
        // Words the user types that the dictionary does not know (names, slang)
        for l in learning.learnedWords(prefix: prefix) where scored[l.word] == nil {
            scored[l.word] = UserLearningStore.boost(forCount: l.count)
        }

        let ranked = scored.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .prefix(limit)
            .map { $0.key }

        // Keep the user's capitalization
        if let first = rawPrefix.first, first.isUppercase {
            return ranked.map { $0.prefix(1).uppercased() + $0.dropFirst() }
        }
        return ranked
    }

    func wordExists(_ word: String) -> Bool {
        let w = normalize(word)
        if let t = trie { return t.search(w) }
        if let l = wordList { return l.contains(w) }
        return false
    }
}
