//
//  DialectSettings.swift
//  ArmenianKeyboard / ArmenianKeyboardExtension
//
//  Which dialect a bundle predicts for.
//
//  There are two keyboard extensions, one per dialect, and each declares its
//  own in its Info.plist. They share every line of code and differ only in the
//  dictionary and n-gram model they carry. This is deliberate: a keyboard
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

    /// The keyboard extension that carries this dialect.
    var extensionBundleID: String {
        switch self {
        case .eastern: return "io.analysta.ArmenianKeyboard.Extension"
        case .western: return "io.analysta.ArmenianKeyboard.WesternExtension"
        }
    }

    /// What the keyboard is called in Settings → Keyboards.
    var keyboardName: String {
        switch self {
        case .eastern: return "Armenian (Eastern)"
        case .western: return "Armenian (Western)"
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
}

/// Which keyboards the user has added, as far as the container app can tell.
/// iOS lists the enabled keyboard bundle IDs in the app's own defaults.
enum KeyboardPresence {

    static func isAdded(_ dialect: ArmenianDialect) -> Bool {
        enabledKeyboardIDs.contains(dialect.extensionBundleID)
    }

    static var addedDialects: [ArmenianDialect] {
        ArmenianDialect.allCases.filter(isAdded)
    }

    private static var enabledKeyboardIDs: [String] {
        UserDefaults.standard.object(forKey: "AppleKeyboards") as? [String] ?? []
    }
}
