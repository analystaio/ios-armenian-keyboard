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

enum KeyType {
    case character(String)
    case delete
    case shift
    case globe
    case space
    case `return`
    case numbers
    case emoji
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

    // Armenian QWERTY layout mapping
    // Based on standard Eastern Armenian keyboard layout

    let letterRows: [[String]] = [
        // Row 1 - Standard Eastern Armenian layout
        ["է", "թ", "փ", "ձ", "ջ", "ր", "չ", "ճ", "ժ", "ծ"],
        // Row 2
        ["ք", "ո", "ե", "ռ", "տ", "ը", "ւ", "ի", "օ", "պ"],
        // Row 3
        ["ա", "ս", "դ", "ֆ", "գ", "հ", "յ", "կ", "լ", "խ"],
        // Row 4
        ["զ", "ղ", "ց", "վ", "բ", "ն", "մ", "շ"]
    ]

    let numberRows: [[String]] = [
        // Row 1
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        // Row 2
        ["-", "/", "։", ";", "(", ")", "֏", "&", "@", "\""],
        // Row 3
        [".", ",", "?", "!", "'", "՝", "՞", "՜", "…"]
    ]

    func getKeys(forRow row: Int, numbersMode: Bool = false) -> [KeyboardKey] {
        let sourceRows = numbersMode ? numberRows : letterRows

        guard row < sourceRows.count else { return [] }

        let rowChars = sourceRows[row]

        // In letter mode: row 3 (4th row) has shift and delete
        // In numbers mode: row 2 (3rd row) has shift and delete
        let isLastCharacterRow = numbersMode ? (row == 2) : (row == 3)

        if isLastCharacterRow {
            var keys: [KeyboardKey] = []

            // Shift key
            keys.append(KeyboardKey(type: .shift, displayText: "⇧", width: .wide))

            // Character keys
            for char in rowChars {
                keys.append(KeyboardKey(type: .character(char), displayText: char, width: .standard))
            }

            // Delete key
            keys.append(KeyboardKey(type: .delete, displayText: "⌫", width: .wide))

            return keys
        }

        // Standard rows
        return rowChars.map { char in
            KeyboardKey(type: .character(char), displayText: char, width: .standard)
        }
    }

    func getBottomRow(numbersMode: Bool = false, showGlobeKey: Bool = true) -> [KeyboardKey] {
        var keys: [KeyboardKey] = []

        keys.append(KeyboardKey(
            type: .numbers,
            displayText: numbersMode ? "ԱԲԳ" : "123",
            width: .wide
        ))

        keys.append(KeyboardKey(type: .emoji, displayText: "", width: .standard))

        if showGlobeKey {
            keys.append(KeyboardKey(type: .globe, displayText: "🌐", width: .standard))
        }

        keys.append(KeyboardKey(type: .space, displayText: "space", width: .extraWide))
        keys.append(KeyboardKey(type: .return, displayText: "⏎", width: .wide))

        return keys
    }

    /// Characters reachable by holding a key, as on the system Armenian keyboard.
    ///
    /// The ech-yiwn ligature և (U+0587) has no key of its own; it is held behind ե.
    private let alternateKeys: [String: [String]] = [
        "ե": ["և"]
    ]

    func alternates(for char: String) -> [String] {
        return alternateKeys[char.lowercased()] ?? []
    }

    /// The form of an alternate to insert for the current shift state.
    ///
    /// և capitalizes to the two-letter "Եւ" in a sentence and to "ԵՒ" in all caps,
    /// since Unicode has no single uppercase ligature for it.
    func alternateOutput(_ alternate: String, isShifted: Bool, isCapsLocked: Bool) -> String {
        if isCapsLocked {
            return uppercased(alternate)
        }
        if isShifted {
            let upper = uppercased(alternate)
            return upper.prefix(1) + upper.dropFirst().lowercased()
        }
        return alternate
    }

    // Uppercase mapping for Armenian letters
    func uppercased(_ char: String) -> String {
        let lowercaseToUppercase: [String: String] = [
            "ա": "Ա", "բ": "Բ", "գ": "Գ", "դ": "Դ", "ե": "Ե",
            "զ": "Զ", "է": "Է", "ը": "Ը", "թ": "Թ", "ժ": "Ժ",
            "ի": "Ի", "լ": "Լ", "խ": "Խ", "ծ": "Ծ", "կ": "Կ",
            "հ": "Հ", "ձ": "Ձ", "ղ": "Ղ", "ճ": "Ճ", "մ": "Մ",
            "յ": "Յ", "ն": "Ն", "շ": "Շ", "ո": "Ո", "չ": "Չ",
            "պ": "Պ", "ջ": "Ջ", "ռ": "Ռ", "ս": "Ս", "վ": "Վ",
            "տ": "Տ", "ր": "Ր", "ց": "Ց", "ւ": "Ւ", "փ": "Փ",
            "ք": "Ք", "օ": "Օ", "ֆ": "Ֆ", "և": "ԵՒ"
        ]

        return lowercaseToUppercase[char] ?? char.uppercased()
    }
}
