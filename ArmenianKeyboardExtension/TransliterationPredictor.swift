//
//  TransliterationPredictor.swift
//  ArmenianKeyboardExtension
//
//  Suggests Armenian words for a word typed with Latin letters. Backed by a
//  sorted "key<TAB>word<TAB>score" index (translit_<dialect>.tsv) held as
//  byte blobs, searched by binary search on the folded prefix, the same way
//  SortedWordList handles the Western dictionary. Learned words are folded at
//  run time so names the user types become suggestible too.
//

import Foundation

final class TransliterationPredictor {

    let dialect: ArmenianDialect
    private let learning: UserLearningStore

    private var keyBlob: [UInt8] = []
    private var keyOffsets: [UInt32] = []
    private var wordBlob: [UInt8] = []
    private var wordOffsets: [UInt32] = []
    private var scores: [UInt8] = []
    private var learnedKeys: [String: [String]] = [:]

    var onReady: (() -> Void)?
    var isReady: Bool { !scores.isEmpty }

    init(dialect: ArmenianDialect, learning: UserLearningStore) {
        self.dialect = dialect
        self.learning = learning
        loadAsync()
    }

    private func loadAsync() {
        let resource = "translit_\(dialect.rawValue)"
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let url = Bundle.main.url(forResource: resource, withExtension: "tsv"),
                  let data = try? Data(contentsOf: url) else { return }
            let parsed = TransliterationPredictor.parse([UInt8](data))
            DispatchQueue.main.async {
                guard let self = self else { return }
                (self.keyBlob, self.keyOffsets, self.wordBlob, self.wordOffsets, self.scores) = parsed
                self.onReady?()
            }
        }
    }

    private static func parse(_ b: [UInt8]) -> ([UInt8], [UInt32], [UInt8], [UInt32], [UInt8]) {
        var kb: [UInt8] = [], ko: [UInt32] = [], wb: [UInt8] = [], wo: [UInt32] = [], sc: [UInt8] = []
        kb.reserveCapacity(b.count / 3); wb.reserveCapacity(b.count / 2)
        var i = 0
        let n = b.count
        while i < n {
            let ks = i
            while i < n && b[i] != 0x09 && b[i] != 0x0A { i += 1 }
            let ke = i
            if i < n && b[i] == 0x09 { i += 1 }
            let ws = i
            while i < n && b[i] != 0x09 && b[i] != 0x0A { i += 1 }
            let we = i
            var s = 0
            if i < n && b[i] == 0x09 {
                i += 1
                while i < n && b[i] >= 0x30 && b[i] <= 0x39 { s = s * 10 + Int(b[i] - 0x30); i += 1 }
            }
            while i < n && b[i] != 0x0A { i += 1 }
            i += 1
            if ke > ks && we > ws {
                ko.append(UInt32(kb.count)); kb.append(contentsOf: b[ks..<ke])
                wo.append(UInt32(wb.count)); wb.append(contentsOf: b[ws..<we])
                sc.append(UInt8(clamping: max(1, s)))
            }
        }
        ko.append(UInt32(kb.count)); wo.append(UInt32(wb.count))
        return (kb, ko, wb, wo, sc)
    }

    // MARK: - Byte search over keys

    private func compareKey(_ i: Int, _ key: [UInt8]) -> Int {
        var a = Int(keyOffsets[i]); let end = Int(keyOffsets[i + 1]); var b = 0
        while a < end && b < key.count {
            if keyBlob[a] != key[b] { return keyBlob[a] < key[b] ? -1 : 1 }
            a += 1; b += 1
        }
        if a == end && b == key.count { return 0 }
        return a == end ? -1 : 1
    }

    private func keyHasPrefix(_ i: Int, _ key: [UInt8]) -> Bool {
        let start = Int(keyOffsets[i]); let end = Int(keyOffsets[i + 1])
        guard end - start >= key.count else { return false }
        for b in 0..<key.count where keyBlob[start + b] != key[b] { return false }
        return true
    }

    private func lowerBound(_ key: [UInt8]) -> Int {
        var lo = 0, hi = scores.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if compareKey(mid, key) < 0 { lo = mid + 1 } else { hi = mid }
        }
        return lo
    }

    private func word(_ i: Int) -> String {
        String(decoding: wordBlob[Int(wordOffsets[i])..<Int(wordOffsets[i + 1])], as: UTF8.self)
    }

    // MARK: - API

    /// Armenian suggestions for a Latin-typed prefix, best first. Keeps the
    /// typed capitalization on the first letter.
    func suggestions(for typed: String, limit: Int = 3) -> [String] {
        guard isReady else { return [] }
        let folded = TransliterationRules.foldLatin(typed)
        guard !folded.isEmpty else { return [] }
        let key = Array(folded.utf8)

        var best: [String: Int] = [:]
        var i = lowerBound(key)
        var scanned = 0
        while i < scores.count && keyHasPrefix(i, key) && scanned < 20_000 {
            let exact = Int(keyOffsets[i + 1] - keyOffsets[i]) == key.count
            let w = word(i)
            let s = Int(scores[i]) + (exact ? 300 : 0)
            if s > (best[w] ?? 0) { best[w] = s }
            i += 1; scanned += 1
        }

        // Learned words: boost known ones, surface unknown ones after two uses
        for (w, s) in best { best[w] = s + learning.boost(for: w) }
        for l in learning.learnedWords(prefix: "", minCount: 2, limit: 400) where best[l.word] == nil {
            let ks = learnedKeys[l.word] ?? {
                let k = TransliterationRules.keys(forArmenian: l.word)
                learnedKeys[l.word] = k
                return k
            }()
            if ks.contains(where: { $0.hasPrefix(folded) }) {
                best[l.word] = UserLearningStore.boost(forCount: l.count) + (ks.contains(folded) ? 300 : 0)
            }
        }

        let ranked = best.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .prefix(limit).map { $0.key }
        if let first = typed.first, first.isUppercase {
            return ranked.map { $0.prefix(1).uppercased() + $0.dropFirst() }
        }
        return ranked
    }
}
