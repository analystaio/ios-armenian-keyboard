//
//  ArmenianKeyboardView.swift
//  ArmenianKeyboardExtension
//
//  Custom keyboard UI matching iOS native styling
//

import UIKit

protocol ArmenianKeyboardViewDelegate: AnyObject {
    func didTapKey(_ key: KeyboardKey)
}

class ArmenianKeyboardView: UIView {

    // MARK: - Properties
    weak var delegate: ArmenianKeyboardViewDelegate?
    private let layout: ArmenianKeyboardLayout
    private var keyButtons: [UIButton] = []
    private var isShifted = false
    private var isCapsLocked = false
    private var isNumbersMode = false

    private let keySpacing: CGFloat = 6
    private let rowSpacing: CGFloat = 12
    private let horizontalPadding: CGFloat = 3

    private var deleteTimer: Timer?
    private var deleteButton: UIButton?
    private var isDeleteButtonHeld = false
    private var shiftButton: UIButton?

    // MARK: - Initialization
    init(layout: ArmenianKeyboardLayout) {
        self.layout = layout
        super.init(frame: .zero)
        setupKeyboard()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupKeyboard() {
        backgroundColor = .clear
        setupRows()
    }

    private func setupRows() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = rowSpacing
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalPadding),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        // Row 1
        stackView.addArrangedSubview(createRow(0))

        // Row 2
        stackView.addArrangedSubview(createRow(1))

        // Row 3
        stackView.addArrangedSubview(createRow(2))

        // Row 4 - Additional letters
        stackView.addArrangedSubview(createRow(3))

        // Bottom row
        stackView.addArrangedSubview(createBottomRow())
    }

    private func createRow(_ rowIndex: Int) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let rowView = UIStackView()
        rowView.axis = .horizontal
        rowView.spacing = keySpacing
        rowView.distribution = .fillEqually
        rowView.translatesAutoresizingMaskIntoConstraints = false

        let keys = layout.getKeys(forRow: rowIndex, numbersMode: isNumbersMode)

        for key in keys {
            let button = createKeyButton(for: key)
            keyButtons.append(button)
            rowView.addArrangedSubview(button)
        }

        containerView.addSubview(rowView)

        // For row 2 (index 1), which has 9 keys, add padding to center it
        if rowIndex == 1 {
            let sidePadding: CGFloat = 15 // Half a key width approximately
            NSLayoutConstraint.activate([
                rowView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: sidePadding),
                rowView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -sidePadding),
                rowView.topAnchor.constraint(equalTo: containerView.topAnchor),
                rowView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                rowView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                rowView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                rowView.topAnchor.constraint(equalTo: containerView.topAnchor),
                rowView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }

        return containerView
    }

    private func createBottomRow() -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let rowView = UIStackView()
        rowView.axis = .horizontal
        rowView.spacing = keySpacing
        rowView.distribution = .fill
        rowView.translatesAutoresizingMaskIntoConstraints = false

        let keys = layout.getBottomRow(numbersMode: isNumbersMode)

        for key in keys {
            let button = createKeyButton(for: key)
            keyButtons.append(button)
            rowView.addArrangedSubview(button)

            // Set width constraints based on key type
            switch key.width {
            case .standard:
                button.widthAnchor.constraint(equalToConstant: 50).isActive = true
            case .wide:
                button.widthAnchor.constraint(equalToConstant: 80).isActive = true
            case .extraWide:
                break // Will expand to fill available space
            }
        }

        containerView.addSubview(rowView)

        // Add padding to center the bottom row
        let sidePadding: CGFloat = 3
        NSLayoutConstraint.activate([
            rowView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: sidePadding),
            rowView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -sidePadding),
            rowView.topAnchor.constraint(equalTo: containerView.topAnchor),
            rowView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        return containerView
    }

    private func createKeyButton(for key: KeyboardKey) -> UIButton {
        let button = UIButton(type: .system)

        // Set display text
        if case .space = key.type {
            button.setTitle("", for: .normal)
        } else {
            var displayText = key.displayText
            // Apply shift/caps if it's a character
            if case .character = key.type, (isShifted || isCapsLocked) {
                displayText = layout.uppercased(displayText)
            }
            // Update shift symbol based on state
            if case .shift = key.type {
                if isCapsLocked {
                    displayText = "⇪"  // Caps lock symbol
                } else {
                    displayText = "⇧"  // Regular shift symbol
                }
            }
            button.setTitle(displayText, for: .normal)
        }

        // Styling to match iOS keyboard
        // Smaller font for numbers button
        if case .numbers = key.type {
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        } else {
            button.titleLabel?.font = .systemFont(ofSize: 22, weight: .regular)
        }

        // Text color - all keys use standard label color
        button.setTitleColor(.label, for: .normal)

        // Background styling - match iOS appearance
        button.backgroundColor = getKeyBackgroundColor(for: key.type)
        button.layer.cornerRadius = 8
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.15
        button.layer.shadowRadius = 0.5

        // Add touch handlers
        button.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(keyReleased(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        // For delete key, add long press support
        if case .delete = key.type {
            deleteButton = button
        }

        // For shift key, track it and highlight when active
        if case .shift = key.type {
            shiftButton = button
            // Highlight if shift or caps lock is active
            if isShifted || isCapsLocked {
                button.backgroundColor = UIColor(hex: "#8b8b8b")
            }
        }

        // Store key data
        button.tag = keyButtons.count

        return button
    }

    private func getKeyBackgroundColor(for keyType: KeyType) -> UIColor {
        // Special keys use darker color
        switch keyType {
        case .shift, .delete, .numbers, .emoji, .return:
            return UIColor(hex: "#464646")
        case .character, .space, .globe:
            return UIColor(hex: "#6b6b6b")
        }
    }

    // MARK: - Actions
    @objc private func keyTapped(_ sender: UIButton) {
        let keys = getAllKeys()
        guard sender.tag < keys.count else { return }

        let key = keys[sender.tag]

        // Skip delete key - it's handled in keyPressed for instant response
        if case .delete = key.type {
            return
        }

        delegate?.didTapKey(key)
    }

    @objc private func keyPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05) {
            sender.alpha = 0.3
        }

        // If delete key, delete immediately and schedule continuous deletion
        if sender == deleteButton {
            isDeleteButtonHeld = true

            // Delete immediately on press
            delegate?.didTapKey(KeyboardKey(type: .delete, displayText: "⌫", width: .wide))

            // Start timer after 0.5 second delay for continuous deletion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self, self.isDeleteButtonHeld, self.deleteTimer == nil else { return }

                // Start repeating timer
                self.deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak self] _ in
                    self?.delegate?.didTapKey(KeyboardKey(type: .delete, displayText: "⌫", width: .wide))
                }
            }
        }
    }

    @objc private func keyReleased(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05) {
            sender.alpha = 1.0
        }

        // If delete button, stop continuous deletion
        if sender == deleteButton {
            isDeleteButtonHeld = false
            deleteTimer?.invalidate()
            deleteTimer = nil
        }
    }

    // MARK: - State Updates
    func updateShiftState(isShifted: Bool, isCapsLocked: Bool) {
        self.isShifted = isShifted
        self.isCapsLocked = isCapsLocked
        refreshKeyboard()
    }

    func setNumbersMode(_ enabled: Bool) {
        isNumbersMode = enabled
        refreshKeyboard()
    }

    private func refreshKeyboard() {
        // Remove all subviews
        subviews.forEach { $0.removeFromSuperview() }
        keyButtons.removeAll()

        // Recreate keyboard
        setupRows()
    }

    private func getAllKeys() -> [KeyboardKey] {
        var allKeys: [KeyboardKey] = []

        for i in 0..<4 {
            allKeys.append(contentsOf: layout.getKeys(forRow: i, numbersMode: isNumbersMode))
        }

        allKeys.append(contentsOf: layout.getBottomRow(numbersMode: isNumbersMode))

        return allKeys
    }
}
