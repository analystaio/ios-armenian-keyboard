//
//  DialectSettings.swift
//  ArmenianKeyboard / ArmenianKeyboardExtension
//
//  The dialect the keyboard predicts for. Chosen in the container app, read by
//  the extension through the shared app group. The key layout is the same for
//  both; only the completion dictionary, the n-gram model and the learned
//  words differ.
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

enum DialectSettings {

    /// Must match the App Groups capability on both targets.
    static let appGroupID = "group.io.analysta.ArmenianKeyboard"

    private static let dialectKey = "dialect"

    /// Falls back to the process's own defaults if the app group is missing
    /// (e.g. entitlement not yet provisioned), so the keyboard still works.
    static let sharedDefaults: UserDefaults = UserDefaults(suiteName: appGroupID) ?? .standard

    static var dialect: ArmenianDialect {
        get {
            let raw = sharedDefaults.string(forKey: dialectKey) ?? ""
            return ArmenianDialect(rawValue: raw) ?? .eastern
        }
        set {
            sharedDefaults.set(newValue.rawValue, forKey: dialectKey)
        }
    }

    /// Shared container for files both the app and the extension can see.
    static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }
}
