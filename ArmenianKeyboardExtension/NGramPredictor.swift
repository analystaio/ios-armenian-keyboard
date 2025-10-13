//
//  NGramPredictor.swift
//  ArmenianKeyboardExtension
//
//  Predicts next word based on previous word context using bigrams
//

import Foundation

class NGramPredictor {

    // HashMap for O(1) lookup: firstWord -> [(nextWord, probability)]
    private let bigramMap: [String: [(word: String, probability: Double)]]

    init() {
        // Build bigram lookup map on initialization
        self.bigramMap = BigramDictionary.buildBigramMap()

        print("DEBUG: NGramPredictor initialized with \(bigramMap.count) unique starting words")
    }

    /// Predicts next words based on the previous word
    /// - Parameters:
    ///   - previousWord: The last word typed by the user
    ///   - limit: Maximum number of predictions to return (default 3)
    /// - Returns: Array of predicted next words, sorted by probability
    func predictNext(after previousWord: String, limit: Int = 3) -> [String] {
        // Normalize to lowercase for matching
        let normalizedWord = previousWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedWord.isEmpty else {
            print("DEBUG: Empty previous word, no predictions")
            return []
        }

        // Look up bigrams starting with this word
        guard let candidates = bigramMap[normalizedWord] else {
            print("DEBUG: No bigrams found for word: \(normalizedWord)")
            return []
        }

        // Return top N predictions
        let predictions = Array(candidates.prefix(limit)).map { $0.word }

        print("DEBUG: Predictions for '\(normalizedWord)': \(predictions)")
        return predictions
    }

    /// Returns all possible next words for a given word (for debugging)
    func getAllPredictions(after previousWord: String) -> [(word: String, probability: Double)] {
        let normalizedWord = previousWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return bigramMap[normalizedWord] ?? []
    }

    /// Returns statistics about the loaded bigram data
    func getStats() -> (uniqueFirstWords: Int, totalBigrams: Int) {
        let uniqueWords = bigramMap.count
        let totalBigrams = bigramMap.values.reduce(0) { $0 + $1.count }
        return (uniqueWords, totalBigrams)
    }
}
