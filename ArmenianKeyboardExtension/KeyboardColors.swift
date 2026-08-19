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
    /// Both values sampled from the native iOS 26 keyboard: #161617 over a black
    /// host app, #E4E6EE over a white one.
    static var background: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#161617")
                : UIColor(hex: "#E4E6EE")
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
    /// The native iOS 26 keyboard draws special keys in the same shade as letter
    /// keys in both appearances, so this deliberately matches `keyBackground`.
    /// The two-tone treatment belongs to older iOS.
    static var specialKeyBackground: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#3C3C3D")
                : UIColor.white
        }
    }

    /// Regular key background while held down
    ///
    /// Dark keys lighten and light keys darken; fading a #3C3C3D key toward the
    /// #161617 background would make it vanish on press.
    static var keyHighlight: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#5B5B5D")
                : UIColor(hex: "#D1D3DA")
        }
    }

    /// Special key background while held down
    ///
    /// Special keys now rest at the same shade as letter keys, so they press the
    /// same way rather than inverting to white as they did when they were gray.
    static var specialKeyHighlight: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#5B5B5D")
                : UIColor(hex: "#D1D3DA")
        }
    }

    /// Shift key when active
    ///
    /// Light mode cannot use white any more, since that is now the resting colour
    /// of every key; it darkens instead, mirroring how dark mode lightens.
    static var shiftActiveBackground: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#8B8B8D")
                : UIColor(hex: "#C7C9D0")
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
