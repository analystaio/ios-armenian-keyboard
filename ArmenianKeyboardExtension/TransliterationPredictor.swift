//
//  TransliterationPredictor.swift
//  ArmenianKeyboardExtension
//
//  Latin-to-Armenian transliteration suggestions backed by a precomputed
//  inverse index built from the n-gram corpus + curated dictionary.
//
//  Lookup is a binary-search prefix range over the sorted Latin keys, with
//  candidates aggregated per Armenian word and ranked by frequency. Exact
//  matches are boosted so the canonical spelling wins when the user has
//  typed the full word.
//

import Foundation

class TransliterationPredictor {

    private struct Candidate {
        let word: String
        let freq: Int
    }

    private var index: [String: [Candidate]] = [:]
    private var sortedKeys: [String] = []

    var onReady: (() -> Void)?

    init() {
        loadAsync()
    }

    private func loadAsync() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let url = Bundle.main.url(forResource: "english_to_armenian", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: [[String: Any]]]
            else {
                return
            }

            var idx: [String: [Candidate]] = [:]
            idx.reserveCapacity(json.count)

            for (latin, candidates) in json {
                var parsed: [Candidate] = []
                parsed.reserveCapacity(candidates.count)
                for entry in candidates {
                    guard let word = entry["w"] as? String,
                          let freq = entry["f"] as? Int else { continue }
                    parsed.append(Candidate(word: word, freq: freq))
                }
                if !parsed.isEmpty {
                    idx[latin] = parsed
                }
            }

            let keys = idx.keys.sorted()

            DispatchQueue.main.async {
                self?.index = idx
                self?.sortedKeys = keys
                self?.onReady?()
            }
        }
    }

    var isReady: Bool {
        return !sortedKeys.isEmpty
    }

    /// Returns top Armenian candidates for a Latin prefix.
    /// - Exact matches dominate via a frequency boost so a fully-typed word
    ///   doesn't get out-ranked by a longer-prefix relative.
    /// - Iteration is capped to bound latency on short prefixes.
    func suggestions(for prefix: String, limit: Int = 3) -> [String] {
        guard isReady else { return [] }
        let key = prefix.lowercased()
        guard !key.isEmpty else { return [] }

        var bestPerWord: [String: Int] = [:]

        // Prefix range scan via binary search
        let start = lowerBound(of: key)
        var i = start
        var scanned = 0
        let maxScan = 400
        while i < sortedKeys.count, sortedKeys[i].hasPrefix(key), scanned < maxScan {
            if let cands = index[sortedKeys[i]] {
                for c in cands {
                    let prev = bestPerWord[c.word] ?? 0
                    if c.freq > prev {
                        bestPerWord[c.word] = c.freq
                    }
                }
            }
            i += 1
            scanned += 1
        }

        // Boost exact-match candidates so the canonical spelling wins.
        let exactBoost = 10_000_000
        if let exactCands = index[key] {
            for c in exactCands {
                bestPerWord[c.word] = (bestPerWord[c.word] ?? 0) + exactBoost
            }
        }

        return bestPerWord
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }

    private func lowerBound(of prefix: String) -> Int {
        var lo = 0
        var hi = sortedKeys.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if sortedKeys[mid] < prefix {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        return lo
    }
}
