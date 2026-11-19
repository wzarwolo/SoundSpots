//
//  StatsViewController.swift
//  SoundSpots
//
//  Tab 5: your year in music. Totals, listens per month, your most listened-to spots,
//  and tier lists for songs and spots.
//

import UIKit

final class StatsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private enum Section {
        case topSpots
        case tierHeader
        case tier(Tier)
    }

    private let store = ListenStore.shared
    private let cellID = "StatCell"
    private var year = Calendar.current.component(.year, from: Date())
    private var mode: TierListMode = .songs

    private var summary: YearSummary?
    private var topSpots: [RankedItem<Place>] = []
    private var songTiers: [(tier: Tier, items: [RankedItem<Song>])] = []
    private var placeTiers: [(tier: Tier, items: [RankedItem<Place>])] = []
    private var sections: [Section] = []
    private var historyObserver: NSObjectProtocol?

    // Header pieces (built in code, placed in the table header).
    private let headerTitle = UILabel()
    private let listensValue = UILabel()
    private let minutesValue = UILabel()
    private let songsValue = UILabel()
    private let barsView = MonthlyBarsView()

    deinit {
        if let observer = historyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = makeHeader()

        historyObserver = NotificationCenter.default.addObserver(forName: .listeningHistoryDidChange,
                                                                 object: nil, queue: .main) { [weak self] _ in
            self?.reload()
        }
        reload()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeHeaderToFit()
    }

    private func reload() {
        let summary = store.yearSummary(for: year)
        self.summary = summary
        headerTitle.text = "Your \(year) in Music"
        listensValue.text = summary.listens.formatted()
        minutesValue.text = summary.minutes.formatted()
        songsValue.text = summary.uniqueSongs.formatted()
        let currentMonth = Calendar.current.component(.month, from: Date())
        barsView.show(counts: summary.monthlyListens, highlightMonth: currentMonth)

        topSpots = Array(store.rankedPlaces().prefix(5))
        songTiers = Tier.assign(store.rankedSongs())
        placeTiers = Tier.assign(store.rankedPlaces())
        rebuildSections()
    }

    private func rebuildSections() {
        sections = []
        if !topSpots.isEmpty { sections.append(.topSpots) }
        sections.append(.tierHeader)
        let tiers = mode == .songs ? songTiers.map { $0.tier } : placeTiers.map { $0.tier }
        sections += tiers.map { Section.tier($0) }
        tableView.reloadData()
    }

    @objc private func modeChanged(_ sender: UISegmentedControl) {
        mode = TierListMode(rawValue: sender.selectedSegmentIndex) ?? .songs
        rebuildSections()
    }

    // MARK: Header

    private func makeHeader() -> UIView {
        headerTitle.font = .preferredFont(forTextStyle: .title2).bold()
        headerTitle.adjustsFontForContentSizeCategory = true

        let tiles = UIStackView(arrangedSubviews: [
            makeTile(value: listensValue, caption: "listens", symbol: "headphones"),
            makeTile(value: minutesValue, caption: "minutes", symbol: "clock"),
            makeTile(value: songsValue, caption: "songs", symbol: "music.note")
        ])
        tiles.axis = .horizontal
        tiles.distribution = .fillEqually
        tiles.spacing = 10

        let chartTitle = UILabel()
        chartTitle.text = "Listens per month"
        chartTitle.font = .preferredFont(forTextStyle: .footnote)
        chartTitle.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [headerTitle, tiles, chartTitle, barsView])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(18, after: tiles)
        stack.setCustomSpacing(6, after: chartTitle)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        container.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        return container
    }

    private func makeTile(value: UILabel, caption: String, symbol: String) -> UIView {
        value.font = .monospacedDigitSystemFont(ofSize: 26, weight: .bold)
        value.adjustsFontSizeToFitWidth = true
        value.minimumScaleFactor = 0.6
        value.text = "0"

        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .footnote)
        icon.tintColor = view.tintColor

        let captionLabel = UILabel()
        captionLabel.text = caption
        captionLabel.font = .preferredFont(forTextStyle: .footnote)
        captionLabel.textColor = .secondaryLabel

        let captionRow = UIStackView(arrangedSubviews: [icon, captionLabel])
        captionRow.spacing = 4
        captionRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [value, captionRow])
        stack.axis = .vertical
        stack.spacing = 2
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        stack.backgroundColor = .secondarySystemGroupedBackground
        stack.layer.cornerRadius = 14
        stack.isAccessibilityElement = true
        stack.accessibilityLabel = caption
        return stack
    }

    /// Table header views don't size themselves; measure with Auto Layout and apply the height.
    private func sizeHeaderToFit() {
        guard let header = tableView.tableHeaderView else { return }
        let width = tableView.bounds.width
        let size = header.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                                                  withHorizontalFittingPriority: .required,
                                                  verticalFittingPriority: .fittingSizeLevel)
        if header.frame.height != size.height || header.frame.width != width {
            header.frame = CGRect(x: 0, y: 0, width: width, height: size.height)
            tableView.tableHeaderView = header
        }
    }
}

// MARK: - Table

extension StatsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sections[section] {
        case .topSpots: return "Most listened-to spots"
        case .tierHeader: return "Tier list"
        case .tier(let tier): return "\(tier.rawValue) tier"
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .topSpots: return topSpots.count
        case .tierHeader: return 1
        case .tier(let tier):
            return mode == .songs
                ? songTiers.first { $0.tier == tier }?.items.count ?? 0
                : placeTiers.first { $0.tier == tier }?.items.count ?? 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        cell.accessoryView = nil
        cell.selectionStyle = .none
        var content = UIListContentConfiguration.valueCell()

        switch sections[indexPath.section] {
        case .topSpots:
            let ranked = topSpots[indexPath.row]
            content.text = "\(indexPath.row + 1). \(ranked.item.displayName)"
            content.secondaryText = pluralized(ranked.plays, "play")
            content.image = UIImage(systemName: "mappin.circle.fill")

        case .tierHeader:
            let control = UISegmentedControl(items: TierListMode.allCases.map { $0.title })
            control.selectedSegmentIndex = mode.rawValue
            control.addTarget(self, action: #selector(modeChanged(_:)), for: .valueChanged)
            content.text = "Rank by plays"
            cell.accessoryView = control

        case .tier(let tier):
            if mode == .songs, let ranked = songTiers.first(where: { $0.tier == tier })?.items[indexPath.row] {
                content = UIListContentConfiguration.subtitleCell()
                content.text = ranked.item.title
                content.secondaryText = "\(ranked.item.artist) • \(pluralized(ranked.plays, "play"))"
            } else if let ranked = placeTiers.first(where: { $0.tier == tier })?.items[indexPath.row] {
                content = UIListContentConfiguration.subtitleCell()
                content.text = ranked.item.displayName
                content.secondaryText = pluralized(ranked.plays, "play")
            }
            content.secondaryTextProperties.color = .secondaryLabel
            content.image = UIImage(systemName: tier.symbolName)
            content.imageProperties.tintColor = tier.color
        }

        cell.contentConfiguration = content
        return cell
    }
}

private extension UIFont {
    func bold() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) else { return self }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
