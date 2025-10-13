//
//  BigramDictionary.swift
//  ArmenianKeyboardExtension
//
//  Curated Armenian bigram data for next word prediction
//

import Foundation

struct Bigram {
    let firstWord: String
    let secondWord: String
    let frequency: Int
}

class BigramDictionary {

    // Curated list of common Armenian word pairs
    // Format: (first word, second word, frequency score)
    static let bigrams: [(String, String, Int)] = [
        // Greetings and salutations (high frequency)
        ("բարի", "լույս", 100),
        ("բարի", "երեկո", 95),
        ("բարի", "առավոտ", 90),
        ("բարի", "գիշեր", 85),
        ("բարև", "ձեզ", 100),
        ("բարև", "քեզ", 95),

        // Courtesy phrases
        ("շնորհակալ", "եմ", 100),
        ("շնորհակալություն", "մեծ", 80),
        ("խնդրում", "եմ", 100),
        ("կներեք", "խնդրեմ", 85),

        // Common "to be" conjugations
        ("ես", "եմ", 100),
        ("դու", "ես", 95),
        ("նա", "է", 90),
        ("մենք", "ենք", 85),
        ("դուք", "եք", 85),
        ("նրանք", "են", 85),

        // Questions
        ("ինչպես", "ես", 90),
        ("ինչպես", "եք", 85),
        ("ինչպես", "են", 80),
        ("ինչ", "է", 90),
        ("ինչ", "եք", 85),
        ("որտեղ", "է", 85),
        ("որտեղ", "ես", 80),
        ("երբ", "է", 85),
        ("ինչու", "է", 80),
        ("ում", "է", 75),
        ("ինչու", "ես", 75),

        // Common verbs with pronouns
        ("գնում", "եմ", 90),
        ("գնում", "ես", 85),
        ("գալիս", "եմ", 85),
        ("գալիս", "ես", 80),
        ("ուզում", "եմ", 90),
        ("ուզում", "ես", 85),
        ("կարող", "եմ", 90),
        ("կարող", "ես", 85),
        ("սիրում", "եմ", 90),
        ("սիրում", "ես", 85),
        ("տեսնում", "եմ", 85),
        ("լսում", "եմ", 85),
        ("գիտեմ", "որ", 80),

        // Common phrases
        ("շատ", "լավ", 90),
        ("շատ", "շնորհակալ", 85),
        ("շատ", "կարևոր", 80),
        ("շատ", "գեղեցիկ", 80),
        ("շատ", "հետաքրքիր", 75),
        ("անհրաժեշտ", "է", 85),
        ("հնարավոր", "է", 85),

        // Time expressions
        ("այս", "օր", 85),
        ("այս", "գիշեր", 80),
        ("այսօր", "շատ", 75),
        ("վաղը", "կգա", 70),
        ("երեկ", "եկա", 70),

        // Location/direction
        ("այստեղ", "եմ", 80),
        ("այնտեղ", "է", 75),
        ("տան", "մեջ", 80),
        ("տուն", "եմ", 85),

        // Family and people
        ("իմ", "անուն", 85),
        ("իմ", "ծնողները", 75),
        ("քո", "անուն", 80),
        ("նրա", "անուն", 75),

        // Common conjunctions and connectors
        ("և", "նա", 80),
        ("բայց", "ես", 85),
        ("եթե", "դու", 80),
        ("որպեսզի", "ես", 75),
        ("որովհետև", "ես", 75),

        // Negations
        ("չեմ", "գիտեմ", 90),
        ("չեմ", "ուզում", 85),
        ("չեմ", "կարող", 85),
        ("չես", "գիտեմ", 80),
        ("չի", "կարող", 80),

        // Modal verbs
        ("պետք", "է", 90),
        ("պիտի", "գնա", 80),
        ("կարող", "է", 85),

        // Work and school
        ("աշխատանք", "եմ", 80),
        ("աշխատում", "եմ", 85),
        ("սովորում", "եմ", 85),
        ("ուսումնասիրում", "եմ", 75),

        // Food and dining
        ("ուտում", "եմ", 85),
        ("խմում", "եմ", 85),
        ("սիրում", "եմ", 85),

        // Common adjectives with nouns
        ("մեծ", "շնորհակալություն", 85),
        ("լավ", "օր", 85),
        ("գեղեցիկ", "օր", 80),

        // Possession
        ("իմ", "տունը", 80),
        ("քո", "տունը", 75),
        ("նրա", "տունը", 70),

        // Communication
        ("ասում", "եմ", 85),
        ("ասում", "ես", 80),
        ("խոսում", "եմ", 85),
        ("պատմում", "եմ", 80),

        // Feelings and emotions
        ("ուրախ", "եմ", 85),
        ("երջանիկ", "եմ", 80),
        ("տխուր", "եմ", 75),

        // Additional common pairs
        ("այո", "շնորհակալ", 70),
        ("ոչ", "շնորհակալ", 70),
        ("լավ", "եմ", 85),
        ("վատ", "եմ", 75),
    ]

    // Convert raw bigram data into optimized lookup structure
    static func buildBigramMap() -> [String: [(word: String, probability: Double)]] {
        var bigramMap: [String: [(word: String, probability: Double)]] = [:]

        // Group bigrams by first word
        var grouped: [String: [(String, Int)]] = [:]
        for (first, second, freq) in bigrams {
            if grouped[first] == nil {
                grouped[first] = []
            }
            grouped[first]?.append((second, freq))
        }

        // Convert frequencies to probabilities
        for (firstWord, candidates) in grouped {
            let totalFrequency = candidates.reduce(0) { $0 + $1.1 }
            let probabilities = candidates.map { word, freq in
                (word: word, probability: Double(freq) / Double(totalFrequency))
            }
            // Sort by probability descending
            bigramMap[firstWord] = probabilities.sorted { $0.probability > $1.probability }
        }

        return bigramMap
    }
}
