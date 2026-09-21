//
//  LearnedWordsView.swift
//  ArmenianKeyboard
//
//  What the keyboard has picked up from your typing, most used first.
//  Browsable so that clearing is an informed choice, and so a single bad
//  word can be forgotten without throwing away the rest.
//

import SwiftUI
import UIKit

struct LearnedWordsView: View {
    let dialect: ArmenianDialect

    /// Kept in step with the count on the home screen.
    @Binding var count: Int

    @State private var store: UserLearningStore?
    @State private var entries: [LearnedWord] = []
    @State private var query = ""

    var body: some View {
        Group {
            if entries.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationBarTitle("Learned Words", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !entries.isEmpty {
                    EditButton()
                }
            }
        }
        .onAppear(perform: load)
    }

    // MARK: - List

    private var list: some View {
        List {
            Section {
                ForEach(filtered) { entry in
                    HStack(spacing: 12) {
                        Text(entry.word)
                            .font(.body)

                        Spacer(minLength: 8)

                        Text("\(entry.count)")
                            .font(.footnote.weight(.medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(Color(UIColor.tertiarySystemFill))
                            )
                    }
                    .padding(.vertical, 2)
                }
                .onDelete(perform: delete)
            } header: {
                Text("\(dialect.displayName) · \(entries.count) \(entries.count == 1 ? "word" : "words")")
            } footer: {
                Text(filtered.isEmpty
                     ? "No learned word matches “\(query)”."
                     : "The number is how often you have typed or accepted the word. Swipe a word away to forget it, along with the pairs it appears in.")
            }
        }
        .listStyle(InsetGroupedListStyle())
        .searchable(text: $query, prompt: "Search learned words")
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 44))
                .foregroundColor(Color(UIColor.tertiaryLabel))

            Text("Nothing learned yet")
                .font(.headline)

            Text("As you type in \(dialect.displayName), the keyboard remembers the words you use and moves them up the suggestion bar.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.groupedBackground.ignoresSafeArea())
    }

    // MARK: - Data

    private var filtered: [LearnedWord] {
        let needle = UserLearningStore.normalize(query) ?? query.lowercased()
        guard !needle.isEmpty else { return entries }
        return entries.filter { $0.word.contains(needle) }
    }

    private func load() {
        let store = self.store ?? UserLearningStore(dialect: dialect)
        self.store = store
        entries = store.allLearnedWords().map { LearnedWord(word: $0.word, count: $0.count) }
        count = entries.count
    }

    private func delete(at offsets: IndexSet) {
        let words = offsets.map { filtered[$0].word }
        for word in words {
            store?.forget(word)
        }
        entries.removeAll { words.contains($0.word) }
        count = entries.count
    }
}

struct LearnedWord: Identifiable {
    let word: String
    let count: Int

    var id: String { word }
}

struct LearnedWordsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LearnedWordsView(dialect: .eastern, count: .constant(0))
        }
    }
}
