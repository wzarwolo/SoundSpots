//
//  MonthlyBarsView.swift
//  SoundSpots
//
//  A small bar chart of listens per month. Bars are plain UIViews, so they follow
//  light/dark mode and the accent color automatically.
//

import UIKit

final class MonthlyBarsView: UIView {

    private let barsStack = UIStackView()
    private let labelsStack = UIStackView()
    private var heightConstraints: [NSLayoutConstraint] = []
    private var bars: [UIView] = []
    private let maxBarHeight: CGFloat = 72
    private var lastCounts: [Int] = []
    private var lastHighlight: Int?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        barsStack.axis = .horizontal
        barsStack.distribution = .fillEqually
        barsStack.alignment = .bottom
        barsStack.spacing = 6

        labelsStack.axis = .horizontal
        labelsStack.distribution = .fillEqually
        labelsStack.spacing = 6

        let symbols = Calendar.current.veryShortMonthSymbols
        for index in 0..<12 {
            let bar = UIView()
            bar.layer.cornerRadius = 3
            bar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            let height = bar.heightAnchor.constraint(equalToConstant: 2)
            height.isActive = true
            heightConstraints.append(height)
            bars.append(bar)
            barsStack.addArrangedSubview(bar)

            let label = UILabel()
            label.text = symbols[index]
            label.font = .preferredFont(forTextStyle: .caption2)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            labelsStack.addArrangedSubview(label)
        }

        let column = UIStackView(arrangedSubviews: [barsStack, labelsStack])
        column.axis = .vertical
        column.spacing = 4
        column.translatesAutoresizingMaskIntoConstraints = false
        addSubview(column)
        NSLayoutConstraint.activate([
            column.topAnchor.constraint(equalTo: topAnchor),
            column.leadingAnchor.constraint(equalTo: leadingAnchor),
            column.trailingAnchor.constraint(equalTo: trailingAnchor),
            column.bottomAnchor.constraint(equalTo: bottomAnchor),
            barsStack.heightAnchor.constraint(equalToConstant: maxBarHeight)
        ])
    }

    /// `counts` = 12 monthly values. `highlightMonth` (1–12) is drawn in the accent color.
    func show(counts: [Int], highlightMonth: Int?) {
        lastCounts = counts
        lastHighlight = highlightMonth
        let maximum = max(counts.max() ?? 0, 1)
        for (index, bar) in bars.enumerated() {
            let value = index < counts.count ? counts[index] : 0
            heightConstraints[index].constant = value == 0 ? 2 : max(6, maxBarHeight * CGFloat(value) / CGFloat(maximum))
            let isHighlight = highlightMonth == index + 1
            bar.backgroundColor = value == 0 ? .tertiarySystemFill
                : (isHighlight ? tintColor : tintColor.withAlphaComponent(0.45))
        }
        accessibilityLabel = "Listens per month"
        accessibilityValue = counts.enumerated()
            .filter { $0.element > 0 }
            .map { "\(Calendar.current.monthSymbols[$0.offset]): \($0.element)" }
            .joined(separator: ", ")
        isAccessibilityElement = true
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        // Redraw the bars in the new accent color.
        show(counts: lastCounts, highlightMonth: lastHighlight)
    }
}
