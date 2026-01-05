//
//  KeyboardColors.swift
//  ArmenianKeyboardExtension
//
//  Dynamic colors for light and dark keyboard appearance
//

import UIKit

struct KeyboardColors {

    /// Keyboard background color
    static var background: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#2B2B2B")
                : UIColor(hex: "#D1D4DB")
        }
    }

    /// Regular key background (letters, space)
    static var keyBackground: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#6b6b6b")
                : UIColor.white
        }
    }

    /// Special key background (shift, delete, numbers, return)
    static var specialKeyBackground: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#464646")
                : UIColor(hex: "#ACB0B8")
        }
    }

    /// Shift key when active
    static var shiftActiveBackground: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#8b8b8b")
                : UIColor.white
        }
    }

    /// Key text color
    static var keyText: UIColor {
        .label
    }

    /// Suggestion bar text color
    static var suggestionText: UIColor {
        .label
    }

    /// Suggestion divider color
    static var suggestionDivider: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.2)
                : UIColor.black.withAlphaComponent(0.2)
        }
    }

    /// Key popup background
    static var popupBackground: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#6b6b6b")
                : UIColor.white
        }
    }

    /// Key popup text color
    static var popupText: UIColor {
        .label
    }

    /// Key shadow color
    static var keyShadow: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.black
                : UIColor.black.withAlphaComponent(0.3)
        }
    }
}
