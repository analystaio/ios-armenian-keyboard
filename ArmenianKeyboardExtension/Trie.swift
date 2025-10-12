//
//  Trie.swift
//  ArmenianKeyboardExtension
//
//  Trie data structure for efficient word lookups
//

import Foundation

class TrieNode {
    var children: [Character: TrieNode] = [:]
    var isEndOfWord: Bool = false
    var frequency: Int = 0
}

class Trie {
    private let root = TrieNode()

    // Insert a word with optional frequency
    func insert(_ word: String, frequency: Int = 1) {
        var currentNode = root
        let lowercasedWord = word.lowercased()

        for char in lowercasedWord {
            if currentNode.children[char] == nil {
                currentNode.children[char] = TrieNode()
            }
            currentNode = currentNode.children[char]!
        }

        currentNode.isEndOfWord = true
        currentNode.frequency = max(currentNode.frequency, frequency)
    }

    // Search for exact word match
    func search(_ word: String) -> Bool {
        let node = findNode(for: word)
        return node?.isEndOfWord ?? false
    }

    // Find words with given prefix
    func findWordsWithPrefix(_ prefix: String, limit: Int = 10) -> [String] {
        guard !prefix.isEmpty else { return [] }

        let lowercasedPrefix = prefix.lowercased()
        guard let prefixNode = findNode(for: lowercasedPrefix) else {
            return []
        }

        var results: [(word: String, frequency: Int)] = []
        findAllWords(from: prefixNode, prefix: lowercasedPrefix, results: &results)

        // Sort by frequency (descending) and return top results
        return results
            .sorted { $0.frequency > $1.frequency }
            .prefix(limit)
            .map { $0.word }
    }

    // Helper: Find node for a given prefix
    private func findNode(for prefix: String) -> TrieNode? {
        var currentNode = root

        for char in prefix.lowercased() {
            guard let nextNode = currentNode.children[char] else {
                return nil
            }
            currentNode = nextNode
        }

        return currentNode
    }

    // Helper: Find all words from a node (DFS)
    private func findAllWords(from node: TrieNode, prefix: String, results: inout [(word: String, frequency: Int)]) {
        if node.isEndOfWord {
            results.append((word: prefix, frequency: node.frequency))
        }

        for (char, childNode) in node.children {
            findAllWords(from: childNode, prefix: prefix + String(char), results: &results)
        }
    }
}
