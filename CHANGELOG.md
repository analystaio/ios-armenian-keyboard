# Changelog

## [Unreleased]

### Changed
- **Container app redesigned**
  - Setup instructions replaced by a four-page onboarding flow, shown on first launch and reachable again from the home screen
  - Home screen shows setup status: the keyboard counts as ready once it is added in Settings, with a Full Access hint until the extension first stamps the app group (which it can only do with Full Access granted)
  - App calls itself by its Home Screen name, "Armenian Keyboard +"
  - Dialect switcher is now a two-row card naming both dialects in English and Armenian, next to the learned-words control
  - Features list removed; acknowledgements moved into an About sheet behind the ⓘ button
  - "Open Keyboard Settings" button removed; the Full Access hint carries its own Settings link, which is the one case the shortcut helps
  - `UIRequiredDeviceCapabilities` corrected from `armv7` to `arm64`

### Added
- **Western Armenian dialect** (setting in the app, shared with the keyboard via an app group)
  - Same key layout; switches the completion dictionary and next-word model
  - `western_words.tsv` (120K inflected forms from the Nayiri Armenian Lexicon, ranked with UD ArmTDP treebank counts) loaded by a new byte-blob `SortedWordList` instead of the per-node Trie
  - `western_ngram.json` (4-gram backoff, 3.3 MB) built from Western Armenian Wikipedia + treebank, seeded with Nayiri periphrastic verb pairs
  - Build pipeline documented in CLAUDE.md ("Western Armenian mode")
- **On-device learning** (`UserLearningStore`, both dialects)
  - Counts words committed with space and suggestions tapped, plus word pairs
  - Boosts completion ranking, surfaces unknown words after two uses, and puts the user's own next-word pairs ahead of the model
  - Stored per dialect in the app group container; "Clear learned words" in the app
- Suggestions keep the capitalization of what the user typed
- Apostrophes (' and ’) are normalized to the Armenian ՚ so Western forms like կ՚ըսէ complete

- **CoreML LSTM Model for Word Prediction**
  - Trained LSTM language model on 5,000 synthetic Armenian conversations (~124K lines)
  - Conversations generated via Gemini 2.5 Flash batch API with diverse personas and topics
  - Model achieves 30.4% top-1 accuracy, 47.7% top-3 accuracy on conversational text
  - 41.7% accuracy on common Armenian phrases (up from 25% with formal training data)

- **MLPredictor.swift**
  - CoreML wrapper class for LSTM inference
  - Loads ArmenianPredictor.mlpackage and vocabulary.json from bundle
  - Converts word context to token IDs, runs inference, returns top predictions
  - Works without Full Access permission

- **Model Files**
  - `ArmenianPredictor.mlpackage` (7.5 MB) - CoreML model targeting iOS 15+
  - `vocabulary.json` (0.28 MB) - 5,000 word vocabulary with word-to-index mapping

### Changed
- **KeyboardViewController.swift**
  - Now uses MLPredictor for next-word prediction after space
  - Falls back to NGramPredictor if ML model returns no results
  - Uses up to 5 words of context for better predictions

- **ContextTracker.swift**
  - Increased word history from 3 to 5 words to match LSTM sequence length

### Technical Details
- Model architecture: LSTM with embedding layer, trained for 25 epochs
- Sequence length: 5 tokens
- Vocabulary size: 5,000 words
- Training data: Synthetic conversational Armenian (not formal/translated text)
- Inference: CPU-only for keyboard extension compatibility
