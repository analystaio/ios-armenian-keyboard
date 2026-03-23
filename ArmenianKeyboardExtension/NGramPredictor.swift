//
//  NGramPredictor.swift
//  ArmenianKeyboardExtension
//
//  Next-word prediction using a 4-gram JSON model with backoff:
//  4-gram → 3-gram → 2-gram → 1-gram (most common words)
//

import Foundation

class NGramPredictor {

    private var fourgram: [String: [String]] = [:]  // "w1 w2 w3" -> [next words]
    private var trigram:  [String: [String]] = [:]  // "w1 w2"    -> [next words]
    private var bigram:   [String: [String]] = [:]  // "w1"       -> [next words]
    private var unigram:  [String] = []             // top words overall

    /// Called on main thread once the model finishes loading
    var onReady: (() -> Void)?

    init() {
        loadModelAsync()
    }

    private func loadModelAsync() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let url = Bundle.main.url(forResource: "armenian_ngram", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                print("DEBUG: NGramPredictor - failed to load armenian_ngram.json")
                return
            }

            let fg = json["4gram"] as? [String: [String]] ?? [:]
            let tg = json["3gram"] as? [String: [String]] ?? [:]
            let bg = json["2gram"] as? [String: [String]] ?? [:]
            let ug = json["1gram"] as? [String] ?? []

            DispatchQueue.main.async {
                self?.fourgram = fg
                self?.trigram  = tg
                self?.bigram   = bg
                self?.unigram  = ug
                print("DEBUG: NGramPredictor loaded async — 4g:\(fg.count) 3g:\(tg.count) 2g:\(bg.count) vocab:\(ug.count)")
                self?.onReady?()
            }
        }
    }

    // Normalize Armenian ligature ев (U+0587) → ե+վ (U+0565+U+057E)
    // Keyboards output the two letters separately; model is built the same way.
    private func normalize(_ s: String) -> String {
        return s.replacingOccurrences(of: "\u{0587}", with: "\u{0565}\u{057E}")
    }

    /// Predicts next words given recent context words, with backoff.
    /// - Parameters:
    ///   - context: Recent words in order (oldest → newest), e.g. ["ես", "քեզ", "շատ"]
    ///   - limit: Max suggestions to return
    func predictNext(context: [String], limit: Int = 3) -> [String] {
        guard isReady else { return [] }
        let words = context.map { normalize($0).lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
                           .filter { !$0.isEmpty }

        // Try 4-gram (3-word context)
        if words.count >= 3 {
            let key = words.suffix(3).joined(separator: " ")
            if let preds = fourgram[key], !preds.isEmpty {
                return Array(preds.prefix(limit))
            }
        }

        // Try 3-gram (2-word context)
        if words.count >= 2 {
            let key = words.suffix(2).joined(separator: " ")
            if let preds = trigram[key], !preds.isEmpty {
                return Array(preds.prefix(limit))
            }
        }

        // Try 2-gram (1-word context)
        if let lastWord = words.last {
            if let preds = bigram[lastWord], !preds.isEmpty {
                return Array(preds.prefix(limit))
            }
        }

        // Fall back to most common words
        return Array(unigram.prefix(limit))
    }

    /// Backward-compatible single-word interface
    func predictNext(after previousWord: String, limit: Int = 3) -> [String] {
        return predictNext(context: [previousWord], limit: limit)
    }

    var isReady: Bool {
        return !bigram.isEmpty
    }
}
