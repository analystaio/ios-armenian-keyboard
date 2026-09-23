//
//  TransliterationRules.swift
//  ArmenianKeyboardExtension
//
//  Folding rules for Armenian typed with Latin letters. The user's input and
//  every Armenian dictionary word are reduced to the same key alphabet, so
//  spelling variation (barev / parev / barew, ch / j, kh / x, ou / u)
//  collapses onto one key and frequency decides the ranking.
//
//  Mirror of translit_rules.py in the armenian-nlp repo, which builds the
//  index. Change both or neither.
//
//  Key alphabet: a e i o u  p t k c j x q w  s z f h l m n r v y
//    p = բ/պ/փ   t = դ/տ/թ   k = գ/կ/ք   c = ծ/ձ/ց   j = ճ/ջ/չ/ժ
//    x = խ       q = ղ       w = շ       y = յ (and ը typed as y)
//

import Foundation

enum TransliterationRules {

    private static let latinMulti: [(String, String)] = [
        ("tch", "j"), ("sh", "w"), ("ch", "j"), ("zh", "j"), ("kh", "x"), ("gh", "q"),
        ("th", "t"), ("ph", "p"), ("ts", "c"), ("tz", "c"), ("dz", "c"), ("dj", "j"),
        ("ck", "k"), ("ou", "u"), ("oo", "u"), ("iu", "yu"), ("ia", "ya"),
    ]
    private static let latinStart: [(String, String)] = [("ye", "e"), ("vo", "o")]
    private static let latinSingle: [Character: String] = ["b": "p", "g": "k", "q": "k", "d": "t", "w": "v"]
    private static let latinKeep: Set<Character> = Set("aeioupktcjxsqzfhlmnrvy")

    /// Folds Latin input to a key. Anything that is not a letter is dropped.
    static func foldLatin(_ input: String) -> String {
        let s = Array(input.lowercased())
        var out = ""
        var i = 0
        for (pat, rep) in latinStart where s.starts(with: Array(pat)) {
            out += rep
            i = pat.count
            break
        }
        while i < s.count {
            var matched = false
            for (pat, rep) in latinMulti {
                let p = Array(pat)
                if i + p.count <= s.count && Array(s[i..<i + p.count]) == p {
                    out += rep
                    i += p.count
                    matched = true
                    break
                }
            }
            if matched { continue }
            let ch = s[i]
            if let r = latinSingle[ch] {
                out += r
            } else if latinKeep.contains(ch) {
                out.append(ch)
            }
            i += 1
        }
        return out
    }

    private static let armenian: [Character: String] = [
        "ա": "a", "բ": "p", "գ": "k", "դ": "t", "ե": "e", "զ": "z", "է": "e",
        "թ": "t", "ժ": "j", "ի": "i", "լ": "l", "խ": "x", "ծ": "c", "կ": "k",
        "հ": "h", "ձ": "c", "ղ": "q", "ճ": "j", "մ": "m", "յ": "y", "ն": "n",
        "շ": "w", "ո": "o", "չ": "j", "պ": "p", "ջ": "j", "ռ": "r", "ս": "s",
        "վ": "v", "տ": "t", "ր": "r", "ց": "c", "ւ": "v", "փ": "p", "ք": "k",
        "օ": "o", "ֆ": "f", "և": "ev",
    ]
    private static let schwaVariants = ["", "e", "u", "y"]
    private static let maxVariants = 8

    /// Every key a typist might produce for an Armenian word. ը is the only
    /// letter that fans out (omitted, e, u or y). Empty if the word contains
    /// something the table cannot map.
    static func keys(forArmenian word: String) -> [String] {
        let w = Array(word.lowercased().replacingOccurrences(of: "\u{0587}", with: "\u{0565}\u{0582}"))
        var parts: [[String]] = []
        var i = 0
        while i < w.count {
            let ch = w[i]
            let next: Character? = i + 1 < w.count ? w[i + 1] : nil
            if ch == "ո" && next == "ւ" { parts.append(["u"]); i += 2; continue }
            if ch == "ի" && next == "ւ" { parts.append(["yu"]); i += 2; continue }
            if (ch == "ե" || ch == "ի") && next == "ա" { parts.append(["ya"]); i += 2; continue }
            if ch == "ը" { parts.append(schwaVariants); i += 1; continue }
            if ch == "\u{055A}" || ch == "-" || ch == "'" { i += 1; continue }
            guard let m = armenian[ch] else { return [] }
            parts.append([m])
            i += 1
        }
        var keys = [""]
        for var opts in parts {
            if keys.count * opts.count > maxVariants {
                opts = Array(opts.prefix(max(1, maxVariants / keys.count)))
            }
            keys = keys.flatMap { k in opts.map { k + $0 } }
        }
        var seen = Set<String>()
        return keys.filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}
