//
//  EmojiData.swift
//  ArmenianKeyboardExtension
//
//  Emoji palette loaded from emoji.json, generated from Unicode's emoji-test.txt
//  by tools/build_emoji_data.py. Entries are in CLDR order, which UTS #51
//  recommends for keyboard palettes.
//

import UIKit
import CoreText

// MARK: - Model

struct EmojiEntry: Codable {
    /// Base emoji, shown when no skin tone is selected.
    let b: String
    /// The five Fitzpatrick variants, present only when the emoji supports them.
    let v: [String]?

    /// The form to display for the given tone, falling back to the base.
    func display(tone: Int?) -> String {
        guard let tone = tone, let variants = v, variants.indices.contains(tone) else {
            return b
        }
        return variants[tone]
    }

    var supportsSkinTone: Bool { v != nil }
}

struct EmojiCategory: Codable {
    let id: String
    let name: String
    /// SF Symbol used for this category's tab.
    let symbol: String
    let emoji: [EmojiEntry]
}

private struct EmojiPalette: Codable {
    let version: String
    let categories: [EmojiCategory]
}

// MARK: - Preferences

/// Recents and skin-tone choice.
///
/// The extension has no app group, so this is its own `UserDefaults.standard`
/// container. That persists across launches but is not shared with the host app.
final class EmojiPreferences {

    private let recentsKey = "emoji.recents"
    private let skinToneKey = "emoji.skinTone"
    private let maxRecents = 32

    private let defaults = UserDefaults.standard

    /// Index into the five variants, or nil for the default yellow form.
    var skinTone: Int? {
        get {
            guard let value = defaults.object(forKey: skinToneKey) as? Int,
                  (0..<5).contains(value) else { return nil }
            return value
        }
        set {
            if let newValue = newValue {
                defaults.set(newValue, forKey: skinToneKey)
            } else {
                defaults.removeObject(forKey: skinToneKey)
            }
        }
    }

    var recents: [String] {
        defaults.stringArray(forKey: recentsKey) ?? []
    }

    func recordUse(of emoji: String) {
        var list = recents
        list.removeAll { $0 == emoji }
        list.insert(emoji, at: 0)
        if list.count > maxRecents {
            list = Array(list.prefix(maxRecents))
        }
        defaults.set(list, forKey: recentsKey)
    }
}

// MARK: - Store

final class EmojiStore {

    private(set) var categories: [EmojiCategory] = []
    private(set) var isReady = false

    let preferences = EmojiPreferences()

    /// Called on the main thread once the palette finishes loading.
    var onReady: (() -> Void)?

    init() {
        loadAsync()
    }

    private func loadAsync() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let url = Bundle.main.url(forResource: "emoji", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let palette = try? JSONDecoder().decode(EmojiPalette.self, from: data)
            else {
                return
            }

            let filtered = EmojiStore.dropUnrenderable(palette.categories)

            DispatchQueue.main.async {
                self?.categories = filtered
                self?.isReady = true
                self?.onReady?()
            }
        }
    }

    /// Removes emoji this OS cannot draw.
    ///
    /// The bundled data tracks the latest Unicode release, which runs ahead of
    /// what a given iOS version has glyphs for; without this the palette would
    /// show tofu boxes for anything newer. A supported sequence shapes into a
    /// single glyph, so anything that shapes into more than one is missing.
    private static func dropUnrenderable(_ categories: [EmojiCategory]) -> [EmojiCategory] {
        let font = CTFontCreateWithName("AppleColorEmoji" as CFString, 24, nil)
        var cache: [String: Bool] = [:]

        func canRender(_ text: String) -> Bool {
            if let known = cache[text] { return known }
            let attributed = NSAttributedString(string: text, attributes: [.font: font])
            let line = CTLineCreateWithAttributedString(attributed)
            guard let runs = CTLineGetGlyphRuns(line) as? [CTRun], runs.count == 1 else {
                cache[text] = false
                return false
            }
            let result = CTRunGetGlyphCount(runs[0]) == 1
            cache[text] = result
            return result
        }

        return categories.compactMap { category in
            let kept = category.emoji.filter { canRender($0.b) }
            guard !kept.isEmpty else { return nil }
            return EmojiCategory(id: category.id,
                                 name: category.name,
                                 symbol: category.symbol,
                                 emoji: kept)
        }
    }
}
