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
        // Match iOS suggestion bar background
        if #available(iOS 13.0, *) {
            backgroundColor = UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
                    : UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1.0)
            }
        } else {
            backgroundColor = UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1.0)
        }

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
        button.setTitleColor(.label, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.tag = tag
        button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)

        // Match iOS suggestion button background
        if #available(iOS 13.0, *) {
            button.backgroundColor = UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(white: 0.22, alpha: 1.0)
                    : UIColor.white
            }
        } else {
            button.backgroundColor = .white
        }

        button.layer.cornerRadius = 6
        button.clipsToBounds = true

        return button
    }

    // MARK: - Actions
    @objc private func suggestionTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        onSuggestionTapped?(title)

        // Visual feedback
        UIView.animate(withDuration: 0.1, animations: {
            sender.backgroundColor = .systemGray4
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                if #available(iOS 13.0, *) {
                    sender.backgroundColor = .systemBackground
                } else {
                    sender.backgroundColor = .white
                }
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
