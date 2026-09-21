//
//  ContentView.swift
//  ArmenianKeyboard
//
//  Home screen: setup status, dialect, and the learned-words control.
//  Setup itself lives in OnboardingView; credits live in AboutView.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @Environment(\.scenePhase) private var scenePhase

    @State private var dialect: ArmenianDialect = DialectSettings.dialect
    @State private var setup: SetupState = .check()
    @State private var showOnboarding = false
    @State private var showAbout = false
    @State private var showClearConfirmation = false
    @State private var didClear = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    setupSection

                    dialectSection

                    learningSection

                    footer
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(AppTheme.groupedBackground.ignoresSafeArea())
            .navigationBarTitle(Bundle.main.appDisplayName)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAbout = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.body.weight(.regular))
                    }
                    .accessibilityLabel("About")
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                hasCompletedOnboarding = true
                showOnboarding = false
                setup = .check()
            }
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
            setup = .check()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                setup = .check()
                dialect = DialectSettings.dialect
            }
        }
    }

    // MARK: - Setup

    private var setupSection: some View {
        VStack(spacing: 8) {
            setupCard

            if let hint = setup.hint {
                VStack(alignment: .leading, spacing: 6) {
                    Text(hint)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Open Settings", action: openSettings)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(AppTheme.accentTop)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var setupCard: some View {
        Card {
            HStack(alignment: .top, spacing: 14) {
                GlyphTile(symbol: setup.symbol, size: 38, tint: setup.tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(setup.title)
                        .font(.headline)

                    Text(setup.detail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)

            RowDivider(leadingInset: 0)

            Button {
                showOnboarding = true
            } label: {
                HStack {
                    Text(setup.isAdded ? "View setup guide" : "Set up keyboard")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.accentTop)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(PlainRowButtonStyle())
        }
    }

    // MARK: - Dialect

    private var dialectSection: some View {
        VStack(spacing: 8) {
            SectionHeader("Dialect")

            Card {
                ForEach(Array(ArmenianDialect.allCases.enumerated()), id: \.element.id) { index, option in
                    if index > 0 {
                        RowDivider(leadingInset: 16)
                    }

                    Button {
                        select(option)
                    } label: {
                        DialectRow(dialect: option, isSelected: option == dialect)
                    }
                    .buttonStyle(PlainRowButtonStyle())
                }
            }

            SectionFootnote("The keys are the same in both. This changes which words and phrases the suggestion bar predicts, and takes effect the next time the keyboard opens.")
        }
    }

    private func select(_ option: ArmenianDialect) {
        guard option != dialect else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            dialect = option
        }
        DialectSettings.dialect = option
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // MARK: - Learned words

    private var learningSection: some View {
        VStack(spacing: 8) {
            SectionHeader("Learning")

            Card {
                HStack(alignment: .top, spacing: 14) {
                    GlyphTile(symbol: "brain.head.profile", size: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Learned words")
                            .font(.subheadline.weight(.semibold))

                        Text("The keyboard remembers the words and phrases you type, so your own vocabulary rises to the front of the suggestion bar. It stays on this iPhone.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                RowDivider(leadingInset: 0)

                Button {
                    showClearConfirmation = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: didClear ? "checkmark" : "trash")
                            .font(.subheadline.weight(.semibold))

                        Text(didClear ? "Learned words cleared" : "Clear learned words")
                            .font(.subheadline.weight(.semibold))

                        Spacer()
                    }
                    .foregroundColor(didClear ? .secondary : .red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(PlainRowButtonStyle())
                .disabled(didClear)
            }
            .confirmationDialog(
                "Clear learned words?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear", role: .destructive) {
                    UserLearningStore.resetAll()
                    withAnimation { didClear = true }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This forgets everything the keyboard has learned from your typing, in both dialects. The built-in dictionary is unaffected.")
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        Text(Bundle.main.versionSummary)
            .font(.caption)
            .foregroundColor(Color(UIColor.tertiaryLabel))
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Dialect row

private struct DialectRow: View {
    let dialect: ArmenianDialect
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(dialect.displayName)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(.primary)

                Text(dialect.nativeName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(isSelected ? AppTheme.accentTop : Color(UIColor.quaternaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Setup state

/// What the container app can actually tell about the keyboard's setup.
///
/// Being added in Settings is visible from here. Full Access is not — the only
/// evidence is that the extension managed to write to the shared app group,
/// which it can only do once Full Access is on and the keyboard has been
/// opened at least once. So its absence is a hint, never a blocked state.
enum SetupState {
    case notAdded
    case added
    case ready

    static func check() -> SetupState {
        if KeyboardPresence.hasRunWithFullAccess { return .ready }
        return KeyboardPresence.isAdded ? .added : .notAdded
    }

    var isAdded: Bool { self != .notAdded }

    var symbol: String {
        switch self {
        case .notAdded: return "keyboard"
        case .added, .ready: return "checkmark"
        }
    }

    var tint: Color? {
        switch self {
        case .notAdded: return nil
        case .added, .ready: return .green
        }
    }

    var title: String {
        switch self {
        case .notAdded: return "Finish setting up"
        case .added, .ready: return "Ready to type"
        }
    }

    var detail: String {
        switch self {
        case .notAdded:
            return "The Armenian keyboard has not been added in Settings yet."
        case .added:
            return "Hold the globe key in any app and choose Armenian."
        case .ready:
            return "Hold the globe key in any app and choose Armenian. Word suggestions are on."
        }
    }

    /// Shown while the keyboard has never reported back, since that usually
    /// means Full Access is still off.
    var hint: String? {
        self == .added
            ? "Word suggestions and the dialect setting need Allow Full Access, under Keyboards in this app's settings."
            : nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
