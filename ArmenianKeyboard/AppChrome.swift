//
//  AppChrome.swift
//  ArmenianKeyboard
//
//  Shared look of the container app: the app mark, cards and the primary
//  button. Kept in one place so the home screen, onboarding and about sheet
//  stay visually identical.
//

import SwiftUI
import UIKit

enum AppTheme {
    /// Taken from the app icon.
    static let accentTop = Color(red: 0.36, green: 0.62, blue: 0.91)
    static let accentBottom = Color(red: 0.13, green: 0.40, blue: 0.75)

    static let accent = LinearGradient(
        colors: [accentTop, accentBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let groupedBackground = Color(UIColor.systemGroupedBackground)
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let separator = Color(UIColor.separator)
}

/// The app icon, drawn rather than loaded, so it can be sized freely.
struct AppMark: View {
    var size: CGFloat = 72

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
            .fill(AppTheme.accent)
            .frame(width: size, height: size)
            .overlay(
                Text("Ա")
                    .font(.system(size: size * 0.56, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            )
            .shadow(color: AppTheme.accentBottom.opacity(0.28), radius: size * 0.12, x: 0, y: size * 0.06)
    }
}

/// A rounded symbol tile used to head a card or an onboarding page.
struct GlyphTile: View {
    let symbol: String
    var size: CGFloat = 40
    var tint: Color?

    var body: some View {
        ZStack {
            if let tint = tint {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(tint)
            } else {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(AppTheme.accent)
            }

            Image(systemName: symbol)
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

/// Section label above a card, in the style of iOS settings.
struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.footnote.weight(.semibold))
            .tracking(0.6)
            .foregroundColor(.secondary)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Explanatory text below a card.
struct SectionFootnote: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Card<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }
}

/// Hairline between rows of a card, inset like a table view's.
struct RowDivider: View {
    var leadingInset: CGFloat = 16

    var body: some View {
        AppTheme.separator
            .frame(height: 0.5)
            .padding(.leading, leadingInset)
            .opacity(0.6)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(AppTheme.accentTop)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// A card row that behaves like a button but keeps the row's own colors.
struct PlainRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .background(configuration.isPressed ? Color(UIColor.tertiarySystemFill) : Color.clear)
    }
}

extension Bundle {
    /// The name people see on the Home Screen, so the app never calls itself
    /// something different from what it is called everywhere else.
    var appDisplayName: String {
        (infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (infoDictionary?["CFBundleName"] as? String)
            ?? "Armenian Keyboard +"
    }

    var versionSummary: String {
        let short = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(short) (\(build))"
    }
}
