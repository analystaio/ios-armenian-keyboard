# Armenian Keyboard+

A custom iOS keyboard extension for typing Armenian (հայերեն) with a standard Armenian layout and a word suggestion bar. It supports Eastern and Western Armenian and is published on the App Store by Analysta.

**[Download on the App Store](https://apps.apple.com/us/app/armenian-keyboard/id6753932933)**

## Features

- System-wide keyboard that works in all iOS apps
- Standard Eastern Armenian phonetic layout with a numbers and punctuation layer
- Word completion while typing and next-word prediction after a space
- Eastern and Western Armenian as two keyboards, Armenian (Eastern) and Armenian (Western), with identical keys and dialect-specific suggestions
- Latin-key keyboards for each dialect: type Armenian phonetically (barev) and tap the Armenian spelling (բարև) in the suggestion bar
- On-device learning of the words you type and accept, kept per keyboard
- Emoji keyboard
- Native iOS appearance with light and dark mode support
- All processing happens on the device; no network access
- iOS 15 and later

## Installation

### Requirements

- Xcode 15.0 or later
- iOS 15.0 or later
- macOS for development

### Building the Project

1. Open the project in Xcode:
   ```bash
   open ArmenianKeyboard.xcodeproj
   ```

2. Select your development team:
   - Click on the project in the navigator
   - Select both targets (ArmenianKeyboard and ArmenianKeyboardExtension)
   - Under "Signing & Capabilities", select your team

3. Update the bundle identifiers if you are building your own copy:
   - Main app: `io.analysta.ArmenianKeyboard`
   - Eastern keyboard: `io.analysta.ArmenianKeyboard.Extension`
   - Western keyboard: `io.analysta.ArmenianKeyboard.WesternExtension`
   - Eastern, Latin keys: `io.analysta.ArmenianKeyboard.LatinExtension`
   - Western, Latin keys: `io.analysta.ArmenianKeyboard.WesternLatinExtension`

4. Build and run on a physical device. Keyboard extensions cannot be fully tested in the simulator.

### Enabling the Keyboard

1. After installing the app, go to Settings > General > Keyboard > Keyboards
2. Tap Add New Keyboard...
3. Select the keyboards you want under Third-Party Keyboards: Armenian (Eastern), Armenian (Western), or their Latin-keys versions. Add several to switch between them with the globe key.
4. To use a keyboard, tap and hold the globe key and select it

The keyboard does not request Full Access. Suggestions and learning work without it.

## Project Structure

```
ArmenianKeyboard/
├── ArmenianKeyboard/              # Container app (SwiftUI)
│   ├── ArmenianKeyboardApp.swift  # App entry point
│   ├── ContentView.swift          # Setup status
│   ├── OnboardingView.swift       # Setup instructions
│   ├── AboutView.swift            # About and credits
│   ├── AppChrome.swift            # Shared app styling
│   └── Info.plist                 # App configuration
│
├── ArmenianKeyboardExtension/     # Keyboard extensions (UIKit); one source tree, four targets
│   ├── KeyboardViewController.swift   # Main keyboard controller
│   ├── ArmenianKeyboardLayout.swift   # Key layout definitions
│   ├── ArmenianKeyboardView.swift     # Keyboard UI
│   ├── EmojiKeyboardView.swift        # Emoji layer
│   ├── SuggestionBar.swift            # Word suggestion bar
│   ├── ArmenianWordPredictor.swift    # Prediction logic
│   ├── NGramPredictor.swift           # Next-word n-gram model
│   ├── ContextTracker.swift           # Tracks recent words for context
│   ├── UserLearningStore.swift        # On-device learned words
│   ├── DialectSettings.swift          # Which dialect this bundle was built for
│   ├── Trie.swift                     # Prefix lookup (Eastern)
│   ├── SortedWordList.swift           # Prefix lookup (Western)
│   ├── TransliterationRules.swift     # Folds Latin typing and Armenian words to one key alphabet
│   ├── TransliterationPredictor.swift # Latin-typed word → Armenian suggestions
│   ├── ArmenianDictionary.swift       # Eastern word list
│   ├── armenian_ngram.json            # Eastern n-gram model
│   ├── western_words.tsv              # Western word list
│   ├── western_ngram.json             # Western n-gram model
│   ├── translit_eastern.tsv           # Latin key → Eastern word index
│   ├── translit_western.tsv           # Latin key → Western word index
│   ├── Info.plist                     # Armenian (Eastern) configuration
│   ├── Info-Western.plist             # Armenian (Western) configuration
│   ├── Info-Latin.plist               # Armenian (Eastern, Latin keys) configuration
│   └── Info-WesternLatin.plist        # Armenian (Western, Latin keys) configuration
│
└── docs/                          # Project website and privacy policy
```

## Keyboard Layout

The keyboard uses the standard Eastern Armenian phonetic layout:

**Row 1:** է թ փ ձ ջ ր չ ճ ժ ծ
**Row 2:** ք ո ե ռ տ ը ւ ի օ պ
**Row 3:** ա ս դ ֆ գ հ յ կ լ խ
**Row 4:** զ ղ ց վ բ ն մ շ

The numbers layer includes Armenian punctuation (։ ՝ ՞ ՜) and the dram sign (֏).

### Special Keys

- **Shift**: Single tap for uppercase, double tap for caps lock
- **Delete**: Delete previous character
- **Globe**: Switch between keyboards
- **123**: Switch to numbers and punctuation
- **Emoji**: Open the emoji keyboard
- **Space**: Insert space
- **Return**: Insert newline

## Word Suggestions

The suggestion bar shows up to three predictions and uses two modes:

- **Prefix completion** while typing a word. Eastern Armenian uses a trie built from a dictionary of about 1,500 common words. Western Armenian uses a sorted word list of about 120,000 inflected forms.
- **Next-word prediction** after a space. A 4-gram model with backoff to 3-gram, 2-gram, and unigram counts, trained on native Armenian text.

On the Latin-key keyboards the current word is instead matched against a transliteration index. Typed letters and dictionary words are both folded to one reduced alphabet, so barev, parev and barew all reach բարեւ, and frequency decides the order. Tapping a suggestion replaces the Latin word; space leaves it as typed.

Words you type and accept are learned on the device, separately for each keyboard, and ranked higher in future suggestions.

## Privacy

- No network requests
- All data stored locally on the device
- No keystroke logging
- Full Access is not requested

The privacy policy is in `docs/privacy.html`.

## Data and Credits

The Western Armenian word list is derived from the Nayiri Armenian Lexicon, © Serouj Ourishian, licensed under CC BY 4.0. The Western n-gram model is trained on the Western Armenian Wikipedia and the UD Western Armenian ArmTDP treebank, both CC BY-SA 4.0.

## License

The source code is licensed under the GNU General Public License v3.0 or later. See `LICENSE` for the full text.

Bundled language data (word lists and n-gram models) is licensed separately under Creative Commons and other terms. See `NOTICE` for the sources and their licenses.

The source is published for transparency so anyone can verify what the keyboard does with typed text. The project is not accepting contributions.

