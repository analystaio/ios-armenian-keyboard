//
//  OnboardingView.swift
//  ArmenianKeyboard
//
//  The setup flow. Shown on first launch and reachable again from the home
//  screen, since adding a keyboard is a trip through Settings that people
//  often start and abandon.
//

import SwiftUI

struct OnboardingView: View {
    /// Called when the flow is finished or skipped.
    var onFinish: () -> Void

    @State private var page = 0

    private let pages = OnboardingPage.all

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            PageDots(count: pages.count, current: page)
                .padding(.bottom, 20)

            footer
        }
        .background(AppTheme.groupedBackground.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            if page > 0 {
                Button {
                    withAnimation { page -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            Button(isLastPage ? "Close" : "Skip", action: onFinish)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .frame(height: 44)
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Button(action: advance) {
                Text(pages[page].primaryButton)
            }
            .buttonStyle(PrimaryButtonStyle())

            if pages[page].opensSettings {
                Button("Not now") {
                    withAnimation { advancePage() }
                }
                .buttonStyle(QuietButtonStyle())
            } else {
                Color.clear.frame(height: 44)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private var isLastPage: Bool { page == pages.count - 1 }

    private func advance() {
        if pages[page].opensSettings, let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
            withAnimation { advancePage() }
            return
        }

        if isLastPage {
            onFinish()
        } else {
            withAnimation { advancePage() }
        }
    }

    private func advancePage() {
        page = min(page + 1, pages.count - 1)
    }
}

// MARK: - Page model

struct OnboardingPage {
    let symbol: String
    let title: String
    let body: String
    /// Optional numbered path through Settings.
    let steps: [String]
    let primaryButton: String
    let opensSettings: Bool
    var showsSuggestionPreview: Bool = false

    static let all: [OnboardingPage] = [
        OnboardingPage(
            symbol: "keyboard",
            title: "Type in Armenian\nanywhere",
            body: "An Armenian keyboard for every app on your iPhone, with a suggestion bar that finishes words and predicts the next one.",
            steps: [],
            primaryButton: "Get Started",
            opensSettings: false,
            showsSuggestionPreview: true
        ),
        OnboardingPage(
            symbol: "plus.square.on.square",
            title: "Add the keyboard",
            body: "iOS keeps third-party keyboards in Settings. It takes about thirty seconds.",
            steps: [
                "Open Settings → General → Keyboard",
                "Tap Keyboards, then Add New Keyboard…",
                "Choose Armenian under Third-Party Keyboards"
            ],
            primaryButton: "Open Settings",
            opensSettings: true
        ),
        OnboardingPage(
            symbol: "lock.open",
            title: "Allow Full Access",
            body: "Word suggestions and the dialect setting need Full Access. Nothing you type leaves your iPhone — the keyboard has no network code at all.",
            steps: [
                "In Keyboards, tap Armenian",
                "Turn on Allow Full Access"
            ],
            primaryButton: "Open Settings",
            opensSettings: true
        ),
        OnboardingPage(
            symbol: "globe",
            title: "Start typing",
            body: "In any app, press and hold the globe key on the keyboard and pick Armenian. Tap a suggestion to accept it — the keyboard learns the words you use most.",
            steps: [],
            primaryButton: "Done",
            opensSettings: false
        )
    ]
}

// MARK: - Page

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                content
                    .frame(minHeight: geo.size.height)
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
                Spacer(minLength: 24)

                ZStack {
                    Circle()
                        .fill(AppTheme.accentTop.opacity(0.14))
                        .frame(width: 132, height: 132)

                    Image(systemName: page.symbol)
                        .font(.system(size: 52, weight: .regular))
                        .foregroundColor(AppTheme.accentTop)
                }

                Text(page.title)
                    .font(.system(size: 30, weight: .bold, design: .default))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 28)
                    .padding(.horizontal, 24)

                Text(page.body)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                    .padding(.horizontal, 28)

                if page.showsSuggestionPreview {
                    SuggestionBarPreview()
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                }

                if !page.steps.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(page.steps.enumerated()), id: \.offset) { index, step in
                            if index > 0 {
                                RowDivider(leadingInset: 56)
                            }
                            StepRow(number: index + 1, text: step)
                        }
                    }
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                }

                Spacer(minLength: 24)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A still of the real suggestion bar, so the welcome page shows the point of
/// the app rather than describing it.
private struct SuggestionBarPreview: View {
    private let words = ["բարև", "ինչպես", "ես"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                if index > 0 {
                    Capsule()
                        .fill(Color(UIColor.separator))
                        .frame(width: 1, height: 18)
                }

                Text(word)
                    .font(.system(size: 17))
                    .foregroundColor(index == 1 ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(index == 1 ? Color(UIColor.tertiarySystemFill) : Color.clear)
                            .padding(.horizontal, 6)
                    )
            }
        }
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Text("\(number)")
                .font(.footnote.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(AppTheme.accent))

            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? AppTheme.accentTop : Color(UIColor.tertiaryLabel))
                    .frame(width: index == current ? 22 : 7, height: 7)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: current)
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onFinish: {})
    }
}
