//
//  ArmenianKeyboardView.swift
//  ArmenianKeyboardExtension
//
//  Custom keyboard UI matching iOS native styling
//

import UIKit
import AudioToolbox

protocol ArmenianKeyboardViewDelegate: AnyObject {
    func didTapKey(_ key: KeyboardKey)
    func didMoveCursor(byOffset offset: Int)
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

    // Key popup
    private var keyPopupView: UIView?

    // Space bar trackpad mode
    private var spaceButton: UIButton?
    private var isTrackpadMode = false
    private var wasTrackpadMode = false // Prevents space insertion after trackpad use
    private var trackpadLastX: CGFloat = 0
    private var trackpadLastTime: TimeInterval = 0
    private var trackpadAccumulatedOffset: CGFloat = 0
    private let trackpadBaseSensitivity: CGFloat = 12 // Base points per character (slower)
    private let trackpadMinSensitivity: CGFloat = 4   // Min points per character (faster)
    private var originalKeyBackgrounds: [UIButton: UIColor] = [:]
    private let trackpadGreyColor = UIColor(red: 81/255, green: 81/255, blue: 81/255, alpha: 1.0)

    // Haptic feedback
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    // MARK: - Initialization
    init(layout: ArmenianKeyboardLayout) {
        self.layout = layout
        super.init(frame: .zero)
        setupKeyboard()
        hapticGenerator.prepare()
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

        // Row 4 - Additional letters (only in letter mode, not in numbers mode)
        if !isNumbersMode {
            stackView.addArrangedSubview(createRow(3))
        }

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

        // All rows extend the full width
        NSLayoutConstraint.activate([
            rowView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            rowView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            rowView.topAnchor.constraint(equalTo: containerView.topAnchor),
            rowView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

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

        // Set display text or image
        if case .space = key.type {
            button.setTitle("", for: .normal)
        } else if case .emoji = key.type {
            // Use SF Symbol for emoji button (black and white)
            if let emojiImage = UIImage(systemName: "face.smiling")?.withRenderingMode(.alwaysTemplate) {
                button.setImage(emojiImage, for: .normal)
                button.tintColor = .label
            } else {
                // Fallback to simple text if SF Symbol not available
                button.setTitle("☺︎", for: .normal)
            }
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
        } else if case .emoji = key.type {
            // No font setting needed for image
        } else {
            button.titleLabel?.font = .systemFont(ofSize: 22, weight: .regular)
        }

        // Text/image color - all keys use standard label color
        button.setTitleColor(.label, for: .normal)
        button.tintColor = .label

        // Background styling - match iOS appearance
        button.backgroundColor = getKeyBackgroundColor(for: key.type)
        button.layer.cornerRadius = 5
        button.layer.shadowColor = KeyboardColors.keyShadow.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.3
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
                button.backgroundColor = KeyboardColors.shiftActiveBackground
            }
        }

        // For space key, add long press gesture for trackpad mode
        if case .space = key.type {
            spaceButton = button
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleSpaceLongPress(_:)))
            longPressGesture.minimumPressDuration = 0.5
            longPressGesture.allowableMovement = .greatestFiniteMagnitude
            button.addGestureRecognizer(longPressGesture)
        }

        // Store key data
        button.tag = keyButtons.count

        return button
    }

    private func getKeyBackgroundColor(for keyType: KeyType) -> UIColor {
        switch keyType {
        case .shift, .delete, .numbers, .emoji, .return:
            return KeyboardColors.specialKeyBackground
        case .character, .space, .globe:
            return KeyboardColors.keyBackground
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

        // Skip space key if we just exited trackpad mode
        if case .space = key.type, wasTrackpadMode {
            return
        }

        delegate?.didTapKey(key)
    }

    @objc private func keyPressed(_ sender: UIButton) {
        // Skip if in trackpad mode (space bar long press)
        if isTrackpadMode && sender == spaceButton {
            return
        }

        // Haptic feedback on every key press
        hapticGenerator.impactOccurred()
        hapticGenerator.prepare()

        // Key click sound (skip for shift and globe to match Apple behavior)
        let allKeys = getAllKeys()
        if sender.tag < allKeys.count {
            switch allKeys[sender.tag].type {
            case .shift, .globe:
                break
            default:
                AudioServicesPlaySystemSound(1104)
            }
        }

        // If delete key, handle it immediately for instant response
        if sender == deleteButton {
            sender.alpha = 0.3
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
            return
        }

        // For other keys, show visual feedback
        UIView.animate(withDuration: 0.05) {
            sender.alpha = 0.3
        }

        // Show popup with the key's text
        if let text = sender.currentTitle, !text.isEmpty {
            showKeyPopup(for: sender, with: text)
        }
    }

    @objc private func keyReleased(_ sender: UIButton) {
        // If delete button, handle instantly for rapid taps
        if sender == deleteButton {
            sender.alpha = 1.0  // No animation for instant response
            isDeleteButtonHeld = false
            deleteTimer?.invalidate()
            deleteTimer = nil
            return
        }

        // For other keys, animate the release
        UIView.animate(withDuration: 0.05) {
            sender.alpha = 1.0
        }

        // Hide the popup
        hideKeyPopup()
    }

    // MARK: - Space Bar Trackpad Mode
    @objc private func handleSpaceLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard spaceButton != nil else { return }

        let location = gesture.location(in: self)

        switch gesture.state {
        case .began:
            // Enter trackpad mode
            isTrackpadMode = true
            trackpadLastX = location.x
            trackpadLastTime = Date.timeIntervalSinceReferenceDate
            trackpadAccumulatedOffset = 0

            // Store original backgrounds and grey out entire keyboard
            originalKeyBackgrounds.removeAll()
            UIView.animate(withDuration: 0.1) {
                for keyButton in self.keyButtons {
                    self.originalKeyBackgrounds[keyButton] = keyButton.backgroundColor
                    keyButton.backgroundColor = self.trackpadGreyColor
                    keyButton.setTitleColor(.clear, for: .normal)
                }
            }

            // Provide haptic feedback (1519 = peek, 1520 = pop, 1521 = nope)
            AudioServicesPlaySystemSound(1520)

        case .changed:
            guard isTrackpadMode else { return }

            let currentTime = Date.timeIntervalSinceReferenceDate
            let deltaTime = currentTime - trackpadLastTime
            let deltaX = location.x - trackpadLastX

            // Calculate velocity (points per second)
            let velocity = deltaTime > 0 ? abs(deltaX) / CGFloat(deltaTime) : 0

            // Calculate dynamic sensitivity based on velocity
            // Faster movement = lower sensitivity = more characters per point
            // velocity of ~100 pts/sec = base sensitivity, ~500+ pts/sec = min sensitivity
            let velocityFactor = min(1.0, max(0.0, (velocity - 100) / 400))
            let sensitivity = trackpadBaseSensitivity - (velocityFactor * (trackpadBaseSensitivity - trackpadMinSensitivity))

            trackpadAccumulatedOffset += deltaX

            // Calculate character offset based on dynamic sensitivity
            let characterOffset = Int(trackpadAccumulatedOffset / sensitivity)

            if characterOffset != 0 {
                delegate?.didMoveCursor(byOffset: characterOffset)
                // Reset accumulated offset, keeping remainder
                trackpadAccumulatedOffset -= CGFloat(characterOffset) * sensitivity
            }

            trackpadLastX = location.x
            trackpadLastTime = currentTime

        case .ended, .cancelled, .failed:
            // Exit trackpad mode
            isTrackpadMode = false
            wasTrackpadMode = true // Prevent space insertion
            trackpadAccumulatedOffset = 0

            // Restore entire keyboard appearance
            UIView.animate(withDuration: 0.1) {
                for keyButton in self.keyButtons {
                    if let originalColor = self.originalKeyBackgrounds[keyButton] {
                        keyButton.backgroundColor = originalColor
                    }
                    keyButton.setTitleColor(.label, for: .normal)
                }
            }
            originalKeyBackgrounds.removeAll()

            // Reset the flag after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.wasTrackpadMode = false
            }

        default:
            break
        }
    }

    // MARK: - State Updates
    func updateShiftState(isShifted: Bool, isCapsLocked: Bool) {
        self.isShifted = isShifted
        self.isCapsLocked = isCapsLocked

        // Update button titles in-place instead of rebuilding the entire keyboard
        let allKeys = getAllKeys()
        for (index, button) in keyButtons.enumerated() {
            guard index < allKeys.count else { break }
            switch allKeys[index].type {
            case .character(let char):
                let displayText = (isShifted || isCapsLocked) ? layout.uppercased(char) : char
                button.setTitle(displayText, for: .normal)
            case .shift:
                button.setTitle(isCapsLocked ? "⇪" : "⇧", for: .normal)
                button.backgroundColor = (isShifted || isCapsLocked)
                    ? KeyboardColors.shiftActiveBackground
                    : KeyboardColors.specialKeyBackground
            default:
                break
            }
        }
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

    // MARK: - Key Popup
    private func showKeyPopup(for button: UIButton, with text: String) {
        hideKeyPopup()

        // Only show popup for character keys (not space, shift, delete, etc.)
        let keys = getAllKeys()
        guard button.tag < keys.count else { return }
        guard case .character = keys[button.tag].type else { return }

        let buttonFrame = button.convert(button.bounds, to: self)

        // Popup dimensions — wider than the key, with a stem connecting to it
        let popupWidth: CGFloat = max(buttonFrame.width + 16, 48)
        let popupHeight: CGFloat = 54
        let stemHeight: CGFloat = buttonFrame.height * 0.45
        let cornerRadius: CGFloat = 8
        let totalHeight = popupHeight + stemHeight

        // Position popup centered above button, clamped to keyboard edges
        var popupX = buttonFrame.midX - popupWidth / 2
        popupX = max(2, min(popupX, bounds.width - popupWidth - 2))

        let popup = UIView(frame: CGRect(
            x: popupX,
            y: buttonFrame.minY - totalHeight,
            width: popupWidth,
            height: totalHeight
        ))
        popup.backgroundColor = .clear

        // Build balloon shape with stem
        let path = UIBezierPath()
        let stemWidth: CGFloat = buttonFrame.width
        let stemLeft = buttonFrame.midX - popup.frame.minX - stemWidth / 2
        let stemRight = stemLeft + stemWidth
        let stemCR: CGFloat = 4 // stem corner radius

        path.move(to: CGPoint(x: stemLeft + stemCR, y: totalHeight))
        path.addLine(to: CGPoint(x: stemRight - stemCR, y: totalHeight))
        path.addQuadCurve(to: CGPoint(x: stemRight, y: totalHeight - stemCR),
                          controlPoint: CGPoint(x: stemRight, y: totalHeight))

        // Right stem curves into popup body
        path.addCurve(to: CGPoint(x: popupWidth, y: popupHeight - cornerRadius),
                      controlPoint1: CGPoint(x: stemRight, y: popupHeight + stemHeight * 0.2),
                      controlPoint2: CGPoint(x: popupWidth, y: popupHeight))
        // Top-right corner
        path.addArc(withCenter: CGPoint(x: popupWidth - cornerRadius, y: cornerRadius),
                    radius: cornerRadius, startAngle: 0, endAngle: -.pi / 2, clockwise: false)
        // Top-left corner
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius),
                    radius: cornerRadius, startAngle: -.pi / 2, endAngle: -.pi, clockwise: false)
        // Left side curves into stem
        path.addCurve(to: CGPoint(x: stemLeft, y: totalHeight - stemCR),
                      controlPoint1: CGPoint(x: 0, y: popupHeight),
                      controlPoint2: CGPoint(x: stemLeft, y: popupHeight + stemHeight * 0.2))
        path.addQuadCurve(to: CGPoint(x: stemLeft + stemCR, y: totalHeight),
                          controlPoint: CGPoint(x: stemLeft, y: totalHeight))
        path.close()

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = KeyboardColors.popupBackground.resolvedColor(with: traitCollection).cgColor
        shapeLayer.shadowColor = UIColor.black.cgColor
        shapeLayer.shadowOffset = CGSize(width: 0, height: 2)
        shapeLayer.shadowOpacity = 0.25
        shapeLayer.shadowRadius = 4
        popup.layer.addSublayer(shapeLayer)

        // Character label centered in the balloon body (above stem)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: popupWidth, height: popupHeight))
        label.text = text
        label.textColor = KeyboardColors.popupText
        label.font = .systemFont(ofSize: 32, weight: .light)
        label.textAlignment = .center
        popup.addSubview(label)

        addSubview(popup)
        keyPopupView = popup

        // Animate in
        popup.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            .concatenating(CGAffineTransform(translationX: 0, y: 10))
        popup.alpha = 0
        UIView.animate(withDuration: 0.06, delay: 0, options: .curveEaseOut) {
            popup.transform = .identity
            popup.alpha = 1.0
        }
    }

    private func hideKeyPopup() {
        guard let popup = keyPopupView else { return }

        UIView.animate(withDuration: 0.08, delay: 0, options: .curveEaseIn, animations: {
            popup.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            popup.alpha = 0
        }) { _ in
            popup.removeFromSuperview()
        }

        keyPopupView = nil
    }
}
