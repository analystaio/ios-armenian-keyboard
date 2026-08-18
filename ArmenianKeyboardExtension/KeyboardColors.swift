//
//  KeyboardColors.swift
//  ArmenianKeyboardExtension
//
//  Dynamic colors for light and dark keyboard appearance
//

import UIKit

struct KeyboardColors {

    /// Corner radius of a key cap, matched to the native iOS keyboard (8pt).
    static let keyCornerRadius: CGFloat = 8

    /// Keyboard background color
    ///
    /// Dark value sampled from the native iOS 26 keyboard rendered over a black
    /// host app: #161617.
    static var background: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#161617")
                : UIColor(hex: "#D1D4DB")
        }
    }

    /// Regular key background (letters, space)
    ///
    /// Dark value sampled from the native keyboard: #3C3C3D.
    static var keyBackground: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#3C3C3D")
                : UIColor.white
        }
    }

    /// Special key background (shift, delete, numbers, return)
    ///
    /// In dark mode the native keyboard draws special keys in the same shade as
    /// letter keys, so this deliberately matches `keyBackground`. Light mode
    /// still uses the darker gray Apple applies there.
    static var specialKeyBackground: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#3C3C3D")
                : UIColor(hex: "#ACB0B8")
        }
    }

    /// Regular key background while held down
    ///
    /// Dark keys are lightened rather than faded; fading a #3C3C3D key toward the
    /// #161617 background would make it vanish on press.
    static var keyHighlight: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#5B5B5D")
                : UIColor(hex: "#ACB0B8")
        }
    }

    /// Special key background while held down
    static var specialKeyHighlight: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#5B5B5D")
                : UIColor.white
        }
    }

    /// Shift key when active
    static var shiftActiveBackground: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#8B8B8D")
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
                ? UIColor(hex: "#6B6B6D")
                : UIColor.white
        }
    }

    /// Key popup text color
    static var popupText: UIColor {
        .label
    }

}
