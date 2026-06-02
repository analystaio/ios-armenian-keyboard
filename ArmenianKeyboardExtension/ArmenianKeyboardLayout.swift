//
//  ArmenianKeyboardLayout.swift
//  ArmenianKeyboardExtension
//
//  Defines Armenian QWERTY keyboard layout
//

import Foundation

enum ArmenianLayoutType {
    case eastern
    case western
}

enum KeyboardLanguage {
    case armenian
    case english
}

enum KeyType {
    case character(String)
    case delete
    case shift
    case globe
    case space
    case `return`
    case numbers
    case emoji
    case languageToggle
}

struct KeyboardKey {
    let type: KeyType
    let displayText: String
    let width: KeyWidth

    enum KeyWidth {
        case standard
        case wide
        case extraWide
    }
}

class ArmenianKeyboardLayout {

    var language: KeyboardLanguage = .armenian

    // Armenian QWERTY layout — Eastern Armenian
    private let armenianLetterRows: [[String]] = [
        ["է", "թ", "փ", "ձ", "ջ", "ր", "չ", "ճ", "ժ", "ծ"],
        ["ք", "ո", "ե", "ռ", "տ", "ը", "ւ", "ի", "օ", "պ"],
        ["ա", "ս", "դ", "ֆ", "գ", "հ", "յ", "կ", "լ", "խ"],
        ["զ", "ղ", "ց", "վ", "բ", "ն", "մ", "շ"]
    ]

    // English QWERTY
    private let englishLetterRows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"]
    ]

    let numberRows: [[String]] = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["-", "/", ":", ";", "(", ")", "֏", "&", "@", "\""],
        [".", ",", "?", "!", "'", "՝", "՞", "՜", "…"]
    ]

    private var letterRows: [[String]] {
        switch language {
        case .armenian: return armenianLetterRows
        case .english:  return englishLetterRows
        }
    }

    func numberOfRows(numbersMode: Bool) -> Int {
        return (numbersMode ? numberRows : letterRows).count
    }

    func getKeys(forRow row: Int, numbersMode: Bool = false) -> [KeyboardKey] {
        let sourceRows = numbersMode ? numberRows : letterRows

        guard row < sourceRows.count else { return [] }

        let rowChars = sourceRows[row]
        let isLastCharacterRow = row == sourceRows.count - 1

        if isLastCharacterRow {
            var keys: [KeyboardKey] = []
            keys.append(KeyboardKey(type: .shift, displayText: "⇧", width: .wide))
            for char in rowChars {
                keys.append(KeyboardKey(type: .character(char), displayText: char, width: .standard))
            }
            keys.append(KeyboardKey(type: .delete, displayText: "⌫", width: .wide))
            return keys
        }

        return rowChars.map { char in
            KeyboardKey(type: .character(char), displayText: char, width: .standard)
        }
    }

    func getBottomRow(numbersMode: Bool = false, showGlobeKey: Bool = true) -> [KeyboardKey] {
        var keys: [KeyboardKey] = []

        let alphaLabel = (language == .armenian) ? "ԱԲԳ" : "ABC"
        keys.append(KeyboardKey(
            type: .numbers,
            displayText: numbersMode ? alphaLabel : "123",
            width: .wide
        ))

        if showGlobeKey {
            keys.append(KeyboardKey(type: .globe, displayText: "🌐", width: .standard))
        }

        keys.append(KeyboardKey(type: .space, displayText: "space", width: .extraWide))
        keys.append(KeyboardKey(type: .return, displayText: "⏎", width: .wide))

        return keys
    }

    /// Per-row leading/trailing inset (points). Used by the view to indent
    /// rows that have fewer keys (e.g. English row 2 has 9 letters and is
    /// indented from each edge to match the iOS native keyboard).
    func sideInset(forRow row: Int, numbersMode: Bool) -> CGFloat {
        guard !numbersMode, language == .english else { return 0 }
        // English: row 0 (10), row 1 (9), row 2 (shift+7+delete)
        return row == 1 ? 18 : 0
    }

    private static let armenianUppercase: [String: String] = [
        "ա": "Ա", "բ": "Բ", "գ": "Գ", "դ": "Դ", "ե": "Ե",
        "զ": "Զ", "է": "Է", "ը": "Ը", "թ": "Թ", "ժ": "Ժ",
        "ի": "Ի", "լ": "Լ", "խ": "Խ", "ծ": "Ծ", "կ": "Կ",
        "հ": "Հ", "ձ": "Ձ", "ղ": "Ղ", "ճ": "Ճ", "մ": "Մ",
        "յ": "Յ", "ն": "Ն", "շ": "Շ", "ո": "Ո", "չ": "Չ",
        "պ": "Պ", "ջ": "Ջ", "ռ": "Ռ", "ս": "Ս", "վ": "Վ",
        "տ": "Տ", "ր": "Ր", "ց": "Ց", "ւ": "Ւ", "փ": "Փ",
        "ք": "Ք", "օ": "Օ", "ֆ": "Ֆ", "և": "ԵՒ"
    ]

    func uppercased(_ char: String) -> String {
        if let mapped = Self.armenianUppercase[char] {
            return mapped
        }
        return char.uppercased()
    }
}
