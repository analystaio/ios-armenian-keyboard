//
//  EmojiKeyboardView.swift
//  ArmenianKeyboardExtension
//
//  Emoji palette panel: a scrolling grid grouped by category, a category tab bar
//  along the bottom, and a long-press skin-tone picker.
//

import UIKit

protocol EmojiKeyboardViewDelegate: AnyObject {
    func emojiKeyboardView(_ view: EmojiKeyboardView, didSelect emoji: String)
    func emojiKeyboardViewDidTapDelete(_ view: EmojiKeyboardView)
    func emojiKeyboardViewDidTapLetters(_ view: EmojiKeyboardView)
}

// MARK: - Cell

private final class EmojiCell: UICollectionViewCell {
    static let reuseID = "EmojiCell"

    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 30)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            label.heightAnchor.constraint(equalTo: contentView.heightAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { contentView.alpha = isHighlighted ? 0.4 : 1.0 }
    }
}

// MARK: - Section header

private final class EmojiSectionHeader: UICollectionReusableView {
    static let reuseID = "EmojiSectionHeader"

    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - View

final class EmojiKeyboardView: UIView {

    weak var delegate: EmojiKeyboardViewDelegate?

    private let store: EmojiStore
    private var sections: [(title: String, symbol: String, entries: [EmojiEntry])] = []

    private var collectionView: UICollectionView!
    private let bottomBar = UIView()
    private let lettersButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private let tabStack = UIStackView()
    private var tabButtons: [UIButton] = []

    private var skinTonePicker: UIView?

    private var deleteTimer: Timer?
    private var isDeleteHeld = false

    private let bottomBarHeight: CGFloat = 44
    private let headerHeight: CGFloat = 26
    private let targetCellWidth: CGFloat = 42

    // MARK: Init

    init(store: EmojiStore) {
        self.store = store
        super.init(frame: .zero)
        setup()

        if store.isReady {
            reloadSections()
        } else {
            store.onReady = { [weak self] in self?.reloadSections() }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Setup

    private func setup() {
        backgroundColor = .clear  // system backdrop shows through

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 0, left: 6, bottom: 8, right: 6)
        layout.headerReferenceSize = CGSize(width: 0, height: headerHeight)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delaysContentTouches = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.reuseID)
        collectionView.register(EmojiSectionHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: EmojiSectionHeader.reuseID)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.35
        collectionView.addGestureRecognizer(longPress)

        setupBottomBar()

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: bottomBarHeight)
        ])
    }

    private func setupBottomBar() {
        bottomBar.backgroundColor = .clear
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomBar)

        lettersButton.setTitle("ԱԲԳ", for: .normal)
        lettersButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        lettersButton.tintColor = .label
        lettersButton.setTitleColor(.label, for: .normal)
        lettersButton.addTarget(self, action: #selector(lettersTapped), for: .touchUpInside)
        lettersButton.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(lettersButton)

        deleteButton.setImage(UIImage(systemName: "delete.left"), for: .normal)
        deleteButton.tintColor = .label
        deleteButton.addTarget(self, action: #selector(deletePressed), for: .touchDown)
        deleteButton.addTarget(self, action: #selector(deleteReleased),
                               for: [.touchUpInside, .touchUpOutside, .touchCancel])
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(deleteButton)

        tabStack.axis = .horizontal
        tabStack.distribution = .fillEqually
        tabStack.spacing = 0
        tabStack.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(tabStack)

        NSLayoutConstraint.activate([
            lettersButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 8),
            lettersButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            lettersButton.widthAnchor.constraint(equalToConstant: 48),

            deleteButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -8),
            deleteButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 48),

            tabStack.leadingAnchor.constraint(equalTo: lettersButton.trailingAnchor, constant: 4),
            tabStack.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -4),
            tabStack.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 4),
            tabStack.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -4)
        ])
    }

    // MARK: Data

    /// Rebuilds sections, including the recents list, which changes as emoji are used.
    func reloadSections() {
        var built: [(title: String, symbol: String, entries: [EmojiEntry])] = []

        let recents = store.preferences.recents
        if !recents.isEmpty {
            built.append((title: "Frequently Used",
                          symbol: "clock",
                          entries: recents.map { EmojiEntry(b: $0, v: nil) }))
        }

        for category in store.categories {
            built.append((title: category.name, symbol: category.symbol, entries: category.emoji))
        }

        sections = built
        rebuildTabs()
        collectionView.reloadData()
    }

    private func rebuildTabs() {
        tabButtons.forEach { $0.removeFromSuperview() }
        tabStack.arrangedSubviews.forEach { tabStack.removeArrangedSubview($0) }
        tabButtons = []

        for (index, section) in sections.enumerated() {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: section.symbol), for: .normal)
            button.tintColor = index == 0 ? .label : .secondaryLabel
            button.tag = index
            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            tabStack.addArrangedSubview(button)
            tabButtons.append(button)
        }
    }

    private func entry(at indexPath: IndexPath) -> EmojiEntry? {
        guard sections.indices.contains(indexPath.section),
              sections[indexPath.section].entries.indices.contains(indexPath.item)
        else { return nil }
        return sections[indexPath.section].entries[indexPath.item]
    }

    // MARK: Actions

    @objc private func lettersTapped() {
        delegate?.emojiKeyboardViewDidTapLetters(self)
    }

    @objc private func deletePressed() {
        isDeleteHeld = true
        delegate?.emojiKeyboardViewDidTapDelete(self)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, self.isDeleteHeld, self.deleteTimer == nil else { return }
            self.deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.emojiKeyboardViewDidTapDelete(self)
            }
        }
    }

    @objc private func deleteReleased() {
        isDeleteHeld = false
        deleteTimer?.invalidate()
        deleteTimer = nil
    }

    @objc private func tabTapped(_ sender: UIButton) {
        let section = sender.tag
        guard sections.indices.contains(section), !sections[section].entries.isEmpty else { return }
        collectionView.scrollToItem(at: IndexPath(item: 0, section: section),
                                    at: .top,
                                    animated: false)
        highlightTab(forSection: section)
    }

    private func highlightTab(forSection section: Int) {
        for (index, button) in tabButtons.enumerated() {
            button.tintColor = index == section ? .label : .secondaryLabel
        }
    }

    private func select(_ emoji: String) {
        store.preferences.recordUse(of: emoji)
        delegate?.emojiKeyboardView(self, didSelect: emoji)
    }

    // MARK: Skin tone picker

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point),
              let entry = entry(at: indexPath),
              entry.supportsSkinTone,
              let cell = collectionView.cellForItem(at: indexPath)
        else { return }

        showSkinTonePicker(for: entry, over: cell)
    }

    private func showSkinTonePicker(for entry: EmojiEntry, over cell: UICollectionViewCell) {
        dismissSkinTonePicker()
        guard let variants = entry.v else { return }

        // Default (yellow) form first, then the five tones, matching Apple's order.
        let options = [entry.b] + variants

        let container = UIView()
        container.backgroundColor = KeyboardColors.popupBackground
        container.layer.cornerRadius = 10
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.25
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        for (index, option) in options.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(option, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 28)
            // index 0 is the default form; 1...5 map to tones 0...4.
            button.tag = index
            button.addTarget(self, action: #selector(skinToneChosen(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
        }

        let cellFrame = cell.convert(cell.bounds, to: self)
        let width = CGFloat(options.count) * 44 + 8
        var centerX = cellFrame.midX
        centerX = max(width / 2 + 4, min(bounds.width - width / 2 - 4, centerX))

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: width),
            container.heightAnchor.constraint(equalToConstant: 52),
            container.centerXAnchor.constraint(equalTo: leadingAnchor, constant: centerX),
            container.bottomAnchor.constraint(equalTo: topAnchor, constant: max(56, cellFrame.minY - 6)),

            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4)
        ])

        skinTonePicker = container
    }

    @objc private func skinToneChosen(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }

        // Remember the choice so every tone-capable emoji shows it, as iOS does.
        store.preferences.skinTone = sender.tag == 0 ? nil : sender.tag - 1

        dismissSkinTonePicker()
        select(title)
        collectionView.reloadData()
    }

    private func dismissSkinTonePicker() {
        skinTonePicker?.removeFromSuperview()
        skinTonePicker = nil
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Tapping outside an open picker dismisses it rather than selecting an emoji.
        if let picker = skinTonePicker, !picker.frame.contains(point) {
            dismissSkinTonePicker()
            return super.hitTest(point, with: event)
        }
        return super.hitTest(point, with: event)
    }
}

// MARK: - Collection view

extension EmojiKeyboardView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        sections[section].entries.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCell.reuseID,
                                                      for: indexPath) as! EmojiCell
        if let entry = entry(at: indexPath) {
            cell.label.text = entry.display(tone: store.preferences.skinTone)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: EmojiSectionHeader.reuseID,
            for: indexPath) as! EmojiSectionHeader
        header.label.text = sections[indexPath.section].title
        return header
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let available = collectionView.bounds.width - 12
        guard available > 0 else { return CGSize(width: targetCellWidth, height: targetCellWidth) }
        let columns = max(6, floor(available / targetCellWidth))
        let side = floor(available / columns)
        return CGSize(width: side, height: side)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let entry = entry(at: indexPath) else { return }
        select(entry.display(tone: store.preferences.skinTone))
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let top = collectionView.indexPathsForVisibleItems.min() else { return }
        highlightTab(forSection: top.section)
    }
}
