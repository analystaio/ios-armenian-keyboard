//
//  SortedWordList.swift
//  ArmenianKeyboardExtension
//
//  Prefix dictionary backed by one UTF-8 byte blob plus offsets, for word
//  lists far too large for the per-node Trie (the Western list is 120K
//  forms). Because the file is sorted by code point and UTF-8 preserves code
//  point order, prefix lookup is a binary search over raw bytes.
//
//  File format: "word<TAB>score\n" per line, score 1...255, sorted.
//

import Foundation

final class SortedWordList {

    private var blob: [UInt8] = []
    private var offsets: [UInt32] = []   // count + 1 entries
    private var scores: [UInt8] = []

    var count: Int { scores.count }

    init?(contentsOf url: URL) {
        guard let data = try? Data(contentsOf: url) else { return nil }
        parse([UInt8](data))
        if scores.isEmpty { return nil }
    }

    private func parse(_ bytes: [UInt8]) {
        blob.reserveCapacity(bytes.count)
        var i = 0
        let n = bytes.count
        while i < n {
            let wordStart = i
            while i < n && bytes[i] != 0x09 && bytes[i] != 0x0A { i += 1 }
            let wordEnd = i
            var score = 0
            if i < n && bytes[i] == 0x09 {
                i += 1
                while i < n && bytes[i] >= 0x30 && bytes[i] <= 0x39 {
                    score = score * 10 + Int(bytes[i] - 0x30)
                    i += 1
                }
            }
            while i < n && bytes[i] != 0x0A { i += 1 }
            i += 1
            if wordEnd > wordStart {
                offsets.append(UInt32(blob.count))
                blob.append(contentsOf: bytes[wordStart..<wordEnd])
                scores.append(UInt8(clamping: max(1, score)))
            }
        }
        offsets.append(UInt32(blob.count))
    }

    // MARK: - Byte helpers

    @inline(__always) private func range(_ i: Int) -> Range<Int> {
        Int(offsets[i])..<Int(offsets[i + 1])
    }

    /// -1, 0, 1 comparing word i against `key`, byte-wise.
    private func compare(_ i: Int, _ key: [UInt8]) -> Int {
        let r = range(i)
        var a = r.lowerBound
        var b = 0
        while a < r.upperBound && b < key.count {
            if blob[a] != key[b] { return blob[a] < key[b] ? -1 : 1 }
            a += 1; b += 1
        }
        if a == r.upperBound && b == key.count { return 0 }
        return a == r.upperBound ? -1 : 1
    }

    private func hasPrefix(_ i: Int, _ key: [UInt8]) -> Bool {
        let r = range(i)
        guard r.count >= key.count else { return false }
        var a = r.lowerBound
        for b in 0..<key.count {
            if blob[a] != key[b] { return false }
            a += 1
        }
        return true
    }

    private func lowerBound(_ key: [UInt8]) -> Int {
        var lo = 0, hi = count
        while lo < hi {
            let mid = (lo + hi) / 2
            if compare(mid, key) < 0 { lo = mid + 1 } else { hi = mid }
        }
        return lo
    }

    private func word(_ i: Int) -> String {
        String(decoding: blob[range(i)], as: UTF8.self)
    }

    // MARK: - API

    func contains(_ word: String) -> Bool {
        let key = Array(word.utf8)
        let i = lowerBound(key)
        return i < count && compare(i, key) == 0
    }

    /// Highest-scoring words starting with `prefix`.
    func candidates(prefix: String, limit: Int) -> [(word: String, score: Int)] {
        guard !prefix.isEmpty, limit > 0 else { return [] }
        let key = Array(prefix.utf8)
        var i = lowerBound(key)
        var top: [(index: Int, score: Int)] = []
        top.reserveCapacity(limit + 1)
        var scanned = 0
        while i < count && hasPrefix(i, key) && scanned < 60_000 {
            let s = Int(scores[i])
            if top.count < limit || s > top[top.count - 1].score {
                var pos = top.count
                while pos > 0 && top[pos - 1].score < s { pos -= 1 }
                top.insert((i, s), at: pos)
                if top.count > limit { top.removeLast() }
            }
            i += 1; scanned += 1
        }
        return top.map { (word($0.index), $0.score) }
    }
}
