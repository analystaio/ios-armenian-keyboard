# Armenian Keyboard for iOS

A custom iOS keyboard extension for typing Armenian (հայերեն) with a standard Armenian layout and a word suggestion bar. It supports Eastern and Western Armenian and is published on the App Store by Analysta.

## Features

- System-wide keyboard that works in all iOS apps
- Standard Eastern Armenian phonetic layout with a numbers and punctuation layer
- Word completion while typing and next-word prediction after a space
- Eastern and Western Armenian dialects, selected in the container app
- On-device learning of the words you type and accept
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

3. Update the bundle identifiers and app group if you are building your own copy:
   - Main app: `io.analysta.ArmenianKeyboard`
   - Extension: `io.analysta.ArmenianKeyboard.Extension`

4. Build and run on a physical device. Keyboard extensions cannot be fully tested in the simulator.

### Enabling the Keyboard

1. After installing the app, go to Settings > General > Keyboard > Keyboards
2. Tap Add New Keyboard...
3. Select Armenian under Third-Party Keyboards
4. To use the keyboard, tap and hold the globe key and select Armenian

The keyboard does not request Full Access. Suggestions and learning work without it.

## Project Structure

```
ArmenianKeyboard/
├── ArmenianKeyboard/              # Container app (SwiftUI)
│   ├── ArmenianKeyboardApp.swift  # App entry point
│   ├── ContentView.swift          # Status and settings
│   ├── OnboardingView.swift       # Setup instructions
│   ├── AboutView.swift            # About and credits
│   └── Info.plist                 # App configuration
│
├── ArmenianKeyboardExtension/     # Keyboard extension (UIKit)
│   ├── KeyboardViewController.swift   # Main keyboard controller
│   ├── ArmenianKeyboardLayout.swift   # Key layout definitions
│   ├── ArmenianKeyboardView.swift     # Keyboard UI
│   ├── EmojiKeyboardView.swift        # Emoji layer
│   ├── SuggestionBar.swift            # Word suggestion bar
│   ├── ArmenianWordPredictor.swift    # Prediction logic
│   ├── NGramPredictor.swift           # Next-word n-gram model
│   ├── ContextTracker.swift           # Tracks recent words for context
│   ├── UserLearningStore.swift        # On-device learned words
│   ├── DialectSettings.swift          # Eastern/Western selection
│   ├── Trie.swift                     # Prefix lookup (Eastern)
│   ├── SortedWordList.swift           # Prefix lookup (Western)
│   ├── ArmenianDictionary.swift       # Eastern word list
│   ├── armenian_ngram.json            # Eastern n-gram model
│   ├── western_words.tsv              # Western word list
│   ├── western_ngram.json             # Western n-gram model
│   └── Info.plist                     # Extension configuration
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

Words you type and accept are learned on the device and ranked higher in future suggestions.

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

