//
//  ContentView.swift
//  ArmenianKeyboard
//
//  Home screen: whether the keyboards are set up, and which ones.
//  Setup lives in OnboardingView; credits live in AboutView.
//
//  There is deliberately nothing to configure here. Each dialect is its own
//  keyboard extension, picked with the globe key, and each learns from your
//  typing inside its own container — which the app cannot reach without Full
//  Access, and asking a keyboard's users for Full Access to show a word list
//  is a bad trade.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @Environment(\.scenePhase) private var scenePhase

    @State private var added: [ArmenianDialect] = KeyboardPresence.addedDialects
    @State private var showOnboarding = false
    @State private var showAbout = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    setupCard

                    keyboardsSection

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
                refresh()
            }
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
            refresh()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                refresh()
            }
        }
    }

    private func refresh() {
        withAnimation(.easeOut(duration: 0.2)) {
            added = KeyboardPresence.addedDialects
        }
    }

    private var isSetUp: Bool { !added.isEmpty }

    // MARK: - Status

    private var setupCard: some View {
        Card {
            HStack(alignment: .top, spacing: 14) {
                GlyphTile(symbol: isSetUp ? "checkmark" : "keyboard",
                          size: 38,
                          tint: isSetUp ? .green : nil)

                VStack(alignment: .leading, spacing: 4) {
                    Text(isSetUp ? "Ready to type" : "Finish setting up")
                        .font(.headline)

                    Text(isSetUp
                         ? "Hold the globe key in any app and pick your Armenian keyboard."
                         : "Neither Armenian keyboard has been added in Settings yet.")
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
                    Text(isSetUp ? "View setup guide" : "Set up keyboards")
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

    // MARK: - Keyboards

    private var keyboardsSection: some View {
        VStack(spacing: 8) {
            SectionHeader("Keyboards")

            Card {
                ForEach(Array(ArmenianDialect.allCases.enumerated()), id: \.element.id) { index, dialect in
                    if index > 0 {
                        RowDivider(leadingInset: 16)
                    }

                    KeyboardRow(dialect: dialect, isAdded: added.contains(dialect))
                }
            }

            SectionFootnote("Add either, or both. The keys are the same; each keyboard suggests words in its own dialect and learns what you type, on this iPhone only.")
        }
    }

    // MARK: - Footer

    private var footer: some View {
        Text(Bundle.main.versionSummary)
            .font(.caption)
            .foregroundColor(Color(UIColor.tertiaryLabel))
    }
}

// MARK: - Keyboard row

private struct KeyboardRow: View {
    let dialect: ArmenianDialect
    let isAdded: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(dialect.displayName)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(dialect.nativeName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)

            if isAdded {
                HStack(spacing: 5) {
                    Text("Added")
                    Image(systemName: "checkmark.circle.fill")
                }
                .font(.subheadline)
                .foregroundColor(.green)
            } else {
                Text("Not added")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
