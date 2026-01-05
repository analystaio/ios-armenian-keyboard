//
//  MLPredictor.swift
//  ArmenianKeyboardExtension
//
//  Predicts next word using CoreML LSTM model
//

import Foundation
import CoreML

class MLPredictor {

    private let model: ArmenianPredictor?
    private let word2idx: [String: Int]
    private let idx2word: [Int: String]
    private let sequenceLength = 5
    private let padToken = 0
    private let unkToken = 1
    private let startToken = 2

    init() {
        // Load the CoreML model
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuOnly  // Use CPU for keyboard extension
            self.model = try ArmenianPredictor(configuration: config)
            print("DEBUG: MLPredictor CoreML model loaded successfully")
        } catch {
            print("DEBUG: Failed to load CoreML model: \(error)")
            self.model = nil
        }

        // Load vocabulary
        var tempWord2idx: [String: Int] = [:]
        var tempIdx2word: [Int: String] = [:]

        if let vocabURL = Bundle.main.url(forResource: "vocabulary", withExtension: "json"),
           let vocabData = try? Data(contentsOf: vocabURL),
           let vocabJSON = try? JSONSerialization.jsonObject(with: vocabData) as? [String: Any],
           let w2i = vocabJSON["word2idx"] as? [String: Int] {
            tempWord2idx = w2i
            // Build reverse mapping
            for (word, idx) in w2i {
                tempIdx2word[idx] = word
            }
            print("DEBUG: Loaded vocabulary with \(w2i.count) words")
        } else {
            print("DEBUG: Failed to load vocabulary.json")
        }

        self.word2idx = tempWord2idx
        self.idx2word = tempIdx2word
    }

    /// Predicts next words based on context
    /// - Parameters:
    ///   - context: Array of recent words (last words typed)
    ///   - limit: Maximum number of predictions to return
    /// - Returns: Array of predicted next words, sorted by probability
    func predictNext(context: [String], limit: Int = 3) -> [String] {
        guard let model = model, !word2idx.isEmpty else {
            print("DEBUG: MLPredictor not ready")
            return []
        }

        // Convert context words to token IDs
        var tokenIds = context.map { word -> Int in
            let normalized = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return word2idx[normalized] ?? unkToken
        }

        // Pad or truncate to sequence length
        if tokenIds.isEmpty {
            tokenIds = [startToken]
        }

        // Take last sequenceLength tokens
        if tokenIds.count > sequenceLength {
            tokenIds = Array(tokenIds.suffix(sequenceLength))
        }

        // Pad at the beginning if needed
        while tokenIds.count < sequenceLength {
            tokenIds.insert(padToken, at: 0)
        }

        // Create MLMultiArray for input
        guard let inputArray = try? MLMultiArray(shape: [1, NSNumber(value: sequenceLength)], dataType: .int32) else {
            print("DEBUG: Failed to create input array")
            return []
        }

        for (i, tokenId) in tokenIds.enumerated() {
            inputArray[[0, NSNumber(value: i)]] = NSNumber(value: tokenId)
        }

        // Run inference
        do {
            let input = ArmenianPredictorInput(input_sequence: inputArray)
            let output = try model.prediction(input: input)
            let logits = output.logits

            // Get top-k predictions
            return getTopPredictions(from: logits, limit: limit)
        } catch {
            print("DEBUG: Prediction failed: \(error)")
            return []
        }
    }

    /// Extract top predictions from logits
    private func getTopPredictions(from logits: MLMultiArray, limit: Int) -> [String] {
        let vocabSize = logits.count

        // Convert to array of (index, score) tuples
        var scores: [(Int, Float)] = []
        for i in 0..<vocabSize {
            let score = logits[i].floatValue
            scores.append((i, score))
        }

        // Sort by score descending
        scores.sort { $0.1 > $1.1 }

        // Get top predictions, filtering out special tokens
        var predictions: [String] = []
        for (idx, _) in scores {
            // Skip special tokens (PAD, UNK, START, END)
            if idx < 4 { continue }

            if let word = idx2word[idx] {
                // Skip words with punctuation attached (like "է," or "է։")
                // These are handled separately
                predictions.append(word)
                if predictions.count >= limit {
                    break
                }
            }
        }

        return predictions
    }

    /// Check if the predictor is ready to use
    var isReady: Bool {
        return model != nil && !word2idx.isEmpty
    }

    /// Returns statistics about the loaded model
    func getStats() -> (vocabSize: Int, modelLoaded: Bool) {
        return (word2idx.count, model != nil)
    }
}
