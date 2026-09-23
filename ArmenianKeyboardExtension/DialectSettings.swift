//
//  DialectSettings.swift
//  ArmenianKeyboard / ArmenianKeyboardExtension
//
//  Which dialect a bundle predicts for.
//
//  There are four keyboard extensions — Eastern and Western, each with
//  Armenian keys or Latin keys — and each declares its dialect and key set in
//  its Info.plist. They share every line of code and differ only in the
//  dictionary, index and n-gram model they carry. This is deliberate: a keyboard
//  extension cannot read a setting written by the container app without Full
//  Access, and asking for Full Access to move one enum across a process
//  boundary is a bad trade for a keyboard.
//

import Foundation

enum ArmenianDialect: String, CaseIterable, Identifiable {
    case eastern
    case western

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .eastern: return "Eastern Armenian"
        case .western: return "Western Armenian"
        }
    }

    var nativeName: String {
        switch self {
        case .eastern: return "Արևելահայերեն"
        case .western: return "Արեւմտահայերէն"
        }
    }

    /// Bundle resource (without extension) holding the n-gram model.
    var ngramResource: String {
        switch self {
        case .eastern: return "armenian_ngram"
        case .western: return "western_ngram"
        }
    }

}

/// What the keys are. Armenian keys type Armenian directly; Latin keys type
/// Armenian phonetically ("barev") and the suggestion bar offers the Armenian
/// spelling to tap.
enum KeyboardMode: String, CaseIterable {
    case armenian
    case transliteration
}

/// One keyboard extension: a dialect and a key set. Each is its own bundle
/// with its own Info.plist, container, and learned words.
struct KeyboardVariant: Identifiable, Equatable {
    let dialect: ArmenianDialect
    let mode: KeyboardMode

    var id: String { "\(dialect.rawValue)-\(mode.rawValue)" }

    static let all: [KeyboardVariant] = [
        KeyboardVariant(dialect: .eastern, mode: .armenian),
        KeyboardVariant(dialect: .western, mode: .armenian),
        KeyboardVariant(dialect: .eastern, mode: .transliteration),
        KeyboardVariant(dialect: .western, mode: .transliteration),
    ]

    /// What the keyboard is called in Settings → Keyboards.
    var keyboardName: String {
        switch (dialect, mode) {
        case (.eastern, .armenian): return "Armenian (Eastern)"
        case (.western, .armenian): return "Armenian (Western)"
        case (.eastern, .transliteration): return "Armenian (Eastern, Latin keys)"
        case (.western, .transliteration): return "Armenian (Western, Latin keys)"
        }
    }

    var extensionBundleID: String {
        switch (dialect, mode) {
        case (.eastern, .armenian): return "io.analysta.ArmenianKeyboard.Extension"
        case (.western, .armenian): return "io.analysta.ArmenianKeyboard.WesternExtension"
        case (.eastern, .transliteration): return "io.analysta.ArmenianKeyboard.LatinExtension"
        case (.western, .transliteration): return "io.analysta.ArmenianKeyboard.WesternLatinExtension"
        }
    }

    /// Second line in the app's keyboard list.
    var detail: String {
        switch mode {
        case .armenian: return dialect.nativeName
        case .transliteration: return "\(dialect.nativeName) · type barev, tap բարեւ"
        }
    }
}

enum DialectSettings {

    /// The dialect this bundle was built for. The container app carries no
    /// dialect of its own and reads as Eastern, which it never uses.
    static let dialect: ArmenianDialect = {
        let raw = Bundle.main.object(forInfoDictionaryKey: "ArmenianDialect") as? String ?? ""
        return ArmenianDialect(rawValue: raw) ?? .eastern
    }()

    /// The key set this bundle was built for. Absent means Armenian keys.
    static let mode: KeyboardMode = {
        let raw = Bundle.main.object(forInfoDictionaryKey: "KeyboardMode") as? String ?? ""
        return KeyboardMode(rawValue: raw) ?? .armenian
    }()
}

/// Which keyboards the user has added, as far as the container app can tell.
/// iOS lists the enabled keyboard bundle IDs in the app's own defaults.
enum KeyboardPresence {

    static func isAdded(_ variant: KeyboardVariant) -> Bool {
        enabledKeyboardIDs.contains(variant.extensionBundleID)
    }

    static var addedVariants: [KeyboardVariant] {
        KeyboardVariant.all.filter(isAdded)
    }

    private static var enabledKeyboardIDs: [String] {
        UserDefaults.standard.object(forKey: "AppleKeyboards") as? [String] ?? []
    }
}
