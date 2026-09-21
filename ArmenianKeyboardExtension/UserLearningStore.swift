//
//  UserLearningStore.swift
//  ArmenianKeyboard / ArmenianKeyboardExtension
//
//  On-device learning of what the user actually types. Counts committed and
//  accepted words plus word pairs, and turns them into score boosts that the
//  predictors layer over the shipped dictionary and n-gram model.
//
//  Kept per dialect in the app group container as a small JSON file, so the
//  container app can reset it. Never leaves the device.
//

import Foundation

final class UserLearningStore {

    private struct Payload: Codable {
        var words: [String: Int] = [:]
        var bigrams: [String: [String: Int]] = [:]
    }

    let dialect: ArmenianDialect

    private var payload = Payload()
    private let fileURL: URL
    private let queue = DispatchQueue(label: "io.analysta.ArmenianKeyboard.learning", qos: .utility)
    private var pendingSave: DispatchWorkItem?

    private let maxWords = 4000
    private let maxContexts = 2000
    private let maxNextPerContext = 8

    // Score boost per count: 0 → 0, 1 → 40, 3 → 80, 7 → 120, 15 → 160, capped at 200.
    static func boost(forCount count: Int) -> Int {
        guard count > 0 else { return 0 }
        return min(200, Int(40.0 * log2(Double(1 + count))))
    }

    init(dialect: ArmenianDialect) {
        self.dialect = dialect
        self.fileURL = UserLearningStore.fileURL(for: dialect)
        load()
    }

    // MARK: - Location

    /// Learned data lives in the bundle's own container. Each keyboard
    /// extension keeps its own, which is all a keyboard can reach without Full
    /// Access — and all it needs, since each one only predicts its dialect.
    static func fileURL(for dialect: ArmenianDialect) -> URL {
        directory().appendingPathComponent("\(dialect.rawValue).json")
    }

    private static func directory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("Learning", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Deletes learned data for every dialect in this bundle's container.
    static func resetAll() {
        for d in ArmenianDialect.allCases {
            try? FileManager.default.removeItem(at: fileURL(for: d))
        }
    }

    // MARK: - Normalization

    private static let allowed: Set<Character> = {
        var s = Set<Character>()
        for v in 0x0561...0x0587 { s.insert(Character(UnicodeScalar(v)!)) }
        s.insert("\u{055A}") // ՚ Western apostrophe (կ՚ըսէ)
        s.insert("-")
        return s
    }()

    /// Lowercases, decomposes և, unifies apostrophes and strips surrounding
    /// punctuation. Returns nil for anything that is not a plain Armenian word.
    static func normalize(_ raw: String) -> String? {
        var s = raw.lowercased()
            .replacingOccurrences(of: "\u{0587}", with: "\u{0565}\u{0582}")
            .replacingOccurrences(of: "'", with: "\u{055A}")
            .replacingOccurrences(of: "\u{2019}", with: "\u{055A}")
        s = s.trimmingCharacters(in: .punctuationCharacters.union(.symbols).union(.whitespacesAndNewlines))
        guard s.count >= 2, let last = s.last, last != "\u{055A}", last != "-" else { return nil }
        guard s.allSatisfy({ allowed.contains($0) }) else { return nil }
        return s
    }

    // MARK: - Recording

    /// A word the user committed with the space bar.
    func recordTyped(_ raw: String, after previous: String?) {
        record(raw, after: previous, weight: 1)
    }

    /// A word the user picked from the suggestion bar. Counts double.
    func recordAccepted(_ raw: String, after previous: String?) {
        record(raw, after: previous, weight: 2)
    }

    private func record(_ raw: String, after previous: String?, weight: Int) {
        guard let word = UserLearningStore.normalize(raw) else { return }
        payload.words[word, default: 0] += weight
        if let p = previous, let prev = UserLearningStore.normalize(p) {
            payload.bigrams[prev, default: [:]][word, default: 0] += weight
            if payload.bigrams[prev]!.count > maxNextPerContext {
                let keep = payload.bigrams[prev]!.sorted { $0.value > $1.value }.prefix(maxNextPerContext)
                payload.bigrams[prev] = Dictionary(uniqueKeysWithValues: keep.map { ($0.key, $0.value) })
            }
        }
        pruneIfNeeded()
        scheduleSave()
    }

    // MARK: - Querying

    func count(of word: String) -> Int {
        payload.words[word] ?? 0
    }

    func boost(for word: String) -> Int {
        UserLearningStore.boost(forCount: count(of: word))
    }

    /// Learned words starting with `prefix` with at least `minCount` uses.
    /// The count threshold keeps one-off typos out of the suggestion bar.
    func learnedWords(prefix: String, minCount: Int = 2, limit: Int = 10) -> [(word: String, count: Int)] {
        var out: [(String, Int)] = []
        for (w, c) in payload.words where c >= minCount && w.hasPrefix(prefix) {
            out.append((w, c))
        }
        out.sort { $0.1 > $1.1 }
        return Array(out.prefix(limit))
    }

    /// How many distinct words have been learned. Used by the container app.
    var learnedWordCount: Int {
        payload.words.count
    }

    /// Every learned word, most used first, ties broken alphabetically.
    /// Used by the container app to show what the keyboard has picked up.
    func allLearnedWords() -> [(word: String, count: Int)] {
        payload.words
            .map { (word: $0.key, count: $0.value) }
            .sorted { $0.count == $1.count ? $0.word < $1.word : $0.count > $1.count }
    }

    /// Forgets one word: its own count, the pairs it starts and the pairs it
    /// ends. Written straight through, since the app may be dismissed right
    /// after. Used by the container app.
    func forget(_ word: String) {
        let key = UserLearningStore.normalize(word) ?? word
        payload.words.removeValue(forKey: key)
        payload.bigrams.removeValue(forKey: key)

        for (context, nexts) in payload.bigrams where nexts[key] != nil {
            var remaining = nexts
            remaining.removeValue(forKey: key)
            if remaining.isEmpty {
                payload.bigrams.removeValue(forKey: context)
            } else {
                payload.bigrams[context] = remaining
            }
        }

        flush()
    }

    /// Words the user has typed after `previous`, most frequent first.
    func nextWords(after previous: String, minCount: Int = 2, limit: Int = 3) -> [String] {
        guard let prev = UserLearningStore.normalize(previous), let nexts = payload.bigrams[prev] else { return [] }
        return nexts.filter { $0.value >= minCount }
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(Payload.self, from: data) else { return }
        payload = decoded
    }

    private func scheduleSave() {
        pendingSave?.cancel()
        let snapshot = payload
        let url = fileURL
        let item = DispatchWorkItem {
            if let data = try? JSONEncoder().encode(snapshot) {
                try? data.write(to: url, options: .atomic)
            }
        }
        pendingSave = item
        queue.asyncAfter(deadline: .now() + 2, execute: item)
    }

    /// Writes immediately. Call when the keyboard is about to disappear.
    func flush() {
        pendingSave?.cancel()
        pendingSave = nil
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func pruneIfNeeded() {
        if payload.words.count > maxWords {
            let keep = payload.words.sorted { $0.value > $1.value }.prefix(maxWords * 3 / 4)
            payload.words = Dictionary(uniqueKeysWithValues: keep.map { ($0.key, $0.value) })
        }
        if payload.bigrams.count > maxContexts {
            let keep = payload.bigrams
                .sorted { $0.value.values.reduce(0, +) > $1.value.values.reduce(0, +) }
                .prefix(maxContexts * 3 / 4)
            payload.bigrams = Dictionary(uniqueKeysWithValues: keep.map { ($0.key, $0.value) })
        }
    }
}
