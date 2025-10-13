//
//  SuggestionBar.swift
//  ArmenianKeyboardExtension
//
//  Suggestion bar for word predictions
//

import UIKit

class SuggestionBar: UIView {

    // MARK: - Properties
    var onSuggestionTapped: ((String) -> Void)?

    private var suggestionButtons: [UIButton] = []
    private let stackView = UIStackView()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup
    private func setup() {
        // Custom background color
        backgroundColor = UIColor(hex: "#2B2B2B")

        // Setup stack view
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 0.5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Create 3 suggestion buttons
        for i in 0..<3 {
            let button = createSuggestionButton(tag: i)
            suggestionButtons.append(button)
            stackView.addArrangedSubview(button)
        }
    }

    private func createSuggestionButton(tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
        button.setTitleColor(.white, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.tag = tag
        button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)

        // Remove background color - transparent
        button.backgroundColor = .clear

        return button
    }

    // MARK: - Actions
    @objc private func suggestionTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        onSuggestionTapped?(title)

        // Visual feedback with opacity change instead of background color
        UIView.animate(withDuration: 0.1, animations: {
            sender.alpha = 0.5
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.alpha = 1.0
            }
        }
    }

    // MARK: - Public Methods
    func updateSuggestions(_ suggestions: [String]) {
        for (index, button) in suggestionButtons.enumerated() {
            if index < suggestions.count {
                button.setTitle(suggestions[index], for: .normal)
                button.isHidden = false
            } else {
                button.setTitle("", for: .normal)
                button.isHidden = true
            }
        }
    }
}
