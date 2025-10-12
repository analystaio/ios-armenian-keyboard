# Armenian Keyboard for iOS

A custom iOS keyboard extension that provides Armenian (հայերեն) typing with QWERTY layout and intelligent word suggestions.

## Features

- ✨ **System-wide keyboard** - Works in all iOS apps
- ⌨️ **QWERTY-based layout** - Standard Armenian character mapping
- 🤖 **Smart word suggestions** - Predictive text with 250+ common Armenian words
- 🎨 **Native iOS design** - Matches the built-in keyboard appearance
- 🔒 **Privacy-focused** - All processing happens on your device
- 📱 **iOS 15+ support** - Compatible with modern iOS versions

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

3. Update the bundle identifiers if needed:
   - Main app: `com.yourcompany.ArmenianKeyboard`
   - Extension: `com.yourcompany.ArmenianKeyboard.Extension`

4. Build and run on your device (keyboard extensions don't work in simulator for full testing)

### Enabling the Keyboard

1. After installing the app, go to **Settings** → **General** → **Keyboard** → **Keyboards**
2. Tap **Add New Keyboard...**
3. Select **Armenian** under "Third-Party Keyboards"
4. (Optional) Enable **Allow Full Access** for word suggestions
5. To use the keyboard, tap and hold the 🌐 globe icon and select Armenian

## Project Structure

```
ArmenianKeyboard/
├── ArmenianKeyboard/              # Main container app
│   ├── ArmenianKeyboardApp.swift  # App entry point
│   ├── ContentView.swift          # Setup instructions UI
│   └── Info.plist                 # App configuration
│
└── ArmenianKeyboardExtension/     # Keyboard extension
    ├── KeyboardViewController.swift      # Main keyboard controller
    ├── ArmenianKeyboardLayout.swift      # Key layout definitions
    ├── ArmenianKeyboardView.swift        # Keyboard UI
    ├── SuggestionBar.swift               # Word suggestion bar
    ├── Trie.swift                        # Trie data structure
    ├── ArmenianWordPredictor.swift       # Prediction logic
    ├── ArmenianDictionary.swift          # Word dictionary
    └── Info.plist                        # Extension configuration
```

## Keyboard Layout

The keyboard uses a standard QWERTY-based Armenian layout:

**Row 1:** ք փ ե ր տ ը ւ ի ո պ
**Row 2:** ա ս դ ֆ գ հ ջ կ լ
**Row 3:** զ խ ծ վ բ ն մ շ ղ ճ

### Special Keys

- **Shift (⇧)**: Single tap for uppercase, double tap for caps lock
- **Delete (⌫)**: Delete previous character
- **Globe (🌐)**: Switch between keyboards
- **123**: Switch to numbers/symbols
- **Space**: Insert space
- **Return**: Insert newline

## Word Suggestions

The keyboard includes 250+ common Armenian words with frequency-based ranking:

- Pronouns: ես, դու, նա, մենք, դուք, նրանք
- Common verbs: լինել, ունեմ, տալ, ասել, գալ, գնալ
- Time words: օր, գիշեր, առավոտ, երեկո
- And many more...

The suggestion bar shows up to 3 word predictions as you type, ordered by frequency and relevance.

## Customization

### Adding More Words

Edit `ArmenianDictionary.swift` to add more words:

```swift
static let commonWords: [(String, Int)] = [
    ("yourword", 70),  // word, frequency (1-100)
    // ... more words
]
```

### Modifying the Layout

Edit `ArmenianKeyboardLayout.swift` to change key positions:

```swift
let letterRows: [[String]] = [
    ["ք", "փ", "ե", /* ... */],
    // ... more rows
]
```

### Styling

Modify `ArmenianKeyboardView.swift` to customize colors, sizes, and animations.

## Technical Details

### Architecture

- **UIKit** for keyboard extension (better performance and reliability)
- **SwiftUI** for main app UI
- **Trie data structure** for efficient prefix-based word lookups
- **Frequency-based ranking** for relevant suggestions

### Privacy

- No network requests
- All data stored locally
- No keystroke logging
- Optional "Full Access" only for word suggestions

### Performance

- Lazy-loaded dictionary
- Optimized Trie for O(m) lookup time (m = prefix length)
- Efficient UI updates with minimal redraws

## Known Limitations

- Keyboard extensions have memory constraints (~48MB)
- Some iOS apps may restrict third-party keyboards
- Autocorrect is not implemented (shows suggestions only)

## Future Improvements

- [ ] Add Western Armenian layout option
- [ ] Implement autocorrect
- [ ] Add more words to dictionary (expand to 5000+)
- [ ] Support for Armenian punctuation shortcuts
- [ ] Themes and customization options
- [ ] Learn from user typing patterns

## Contributing

Feel free to contribute by:
- Adding more Armenian words to the dictionary
- Improving the UI/UX
- Fixing bugs
- Adding new features

## License

This project is provided as-is for educational and personal use.

## Support

For issues or questions:
- Check Xcode build errors
- Ensure your device is iOS 15+
- Verify signing & capabilities are configured
- Try cleaning the build folder (Shift+Cmd+K)

---

**Հաջողություն!** (Good luck!)
