//
//  AboutView.swift
//  ArmenianKeyboard
//
//  Reached from the ⓘ button on the home screen: what the app is, where its
//  data comes from, and the licences that data carries.
//

import SwiftUI
import UIKit

struct AboutView: View {
    @Environment(\.presentationMode) private var presentationMode

    private let privacyURL = URL(string: "https://analystaio.github.io/ios-armenian-keyboard/privacy.html")

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        AppMark(size: 84)

                        Text(Bundle.main.appDisplayName)
                            .font(.title2.weight(.bold))

                        Text(Bundle.main.versionSummary)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    Text("An Armenian keyboard for iOS with a suggestion bar that completes the word you are typing and predicts the next one, in Eastern or Western Armenian, on Armenian keys or Latin keys. Everything runs on your iPhone — the keyboard has no network code and sends nothing anywhere.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 28)

                    VStack(spacing: 8) {
                        SectionHeader("Acknowledgements")

                        Card {
                            CreditBlock(
                                title: "Nayiri Armenian Lexicon",
                                detail: "Western Armenian word forms © Serouj Ourishian, Nayiri Institute for Armenian Language Computing. Licensed under CC BY 4.0.",
                                link: "nayiri.com",
                                url: URL(string: "https://nayiri.com")
                            )

                            RowDivider()

                            CreditBlock(
                                title: "Western Armenian Wikipedia",
                                detail: "Western Armenian phrase statistics derived from the Wikipedia text dump. Licensed under CC BY-SA 4.0.",
                                link: nil,
                                url: nil
                            )

                            RowDivider()

                            CreditBlock(
                                title: "UD Western Armenian ArmTDP",
                                detail: "Word and phrase frequencies derived from the Universal Dependencies treebank. Licensed under CC BY-SA 4.0.",
                                link: nil,
                                url: nil
                            )
                        }
                    }

                    VStack(spacing: 8) {
                        SectionHeader("Privacy")

                        Card {
                            Button {
                                if let privacyURL = privacyURL {
                                    UIApplication.shared.open(privacyURL)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    GlyphTile(symbol: "hand.raised.fill", size: 30)

                                    Text("Privacy Policy")
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Image(systemName: "arrow.up.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(PlainRowButtonStyle())
                        }

                        SectionFootnote("What you type is never collected, stored off-device or shared.")
                    }
                }
                .padding(.bottom, 32)
            }
            .background(AppTheme.groupedBackground.ignoresSafeArea())
            .navigationBarTitle("About", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.body.weight(.semibold))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

private struct CreditBlock: View {
    let title: String
    let detail: String
    let link: String?
    let url: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(detail)
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let link = link, let url = url {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    Text(link)
                        .font(.footnote.weight(.medium))
                        .foregroundColor(AppTheme.accentTop)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
