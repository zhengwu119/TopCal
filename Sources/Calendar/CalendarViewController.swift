import AppKit

/// Selection modes for the bottom toolbar calculators.
enum SelectionMode {
    case none
    case workdays
    case days
}

/// A day cell that remembers which date it represents (for click handling).
private final class DayCellView: NSView {
    var representedDate: Date?
}

/// Popover content: navigation header + weekday row + day grid + calculator
/// toolbar.
///
/// Data computation lives in `MonthGrid` (pure model) and `WorkdayCounter`
/// (pure logic); this view controller handles layout, rendering, and the
/// click-to-select interactions for the workday / total-days calculators.
class CalendarViewController: NSViewController {
    private var prevYearButton: NSButton!
    private var prevMonthButton: NSButton!
    private var titleLabel: NSTextField!
    private var nextMonthButton: NSButton!
    private var nextYearButton: NSButton!
    private var calendarStack: NSStackView!
    private var workdayButton: NSButton!
    private var daysButton: NSButton!
    private var toolbarLabel: NSTextField!

    private var currentDate = Date()
    private var selectionMode: SelectionMode = .none
    private var selectionStart: Date?
    private var selectionEnd: Date?

    // MARK: - Lifecycle

    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func loadView() {
        let frame = NSRect(x: 0, y: 0,
                           width: AppConstants.Popover.size.width,
                           height: AppConstants.Popover.size.height)
        self.view = NSView(frame: frame)
        setupUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        renderCurrentMonth()
    }

    /// Reset the view to today's month.
    func refresh() {
        let _ = view
        currentDate = Date()
        renderCurrentMonth()
    }

    /// Jump to a specific month (used by the screenshot renderer).
    func showMonth(_ date: Date) {
        let _ = view
        currentDate = date
        renderCurrentMonth()
    }

    /// The currently displayed month title (used by the screenshot renderer).
    var displayedTitle: String {
        titleLabel.stringValue
    }

    /// Renderer-only hook: override the toolbar button titles because the
    /// render binary's bundle defaults to English even when we force a
    /// non-English locale.
    func setToolbarButtonTitles(workdays: String, days: String) {
        workdayButton.title = workdays
        daysButton.title = days
    }

    // MARK: - UI setup

    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // Navigation header: « ‹ title › »
        prevYearButton = makeNavButton(symbol: "chevron.left.2", action: #selector(goToPreviousYear))
        prevMonthButton = makeNavButton(symbol: "chevron.left", action: #selector(goToPreviousMonth))
        nextMonthButton = makeNavButton(symbol: "chevron.right", action: #selector(goToNextMonth))
        nextYearButton = makeNavButton(symbol: "chevron.right.2", action: #selector(goToNextYear))

        titleLabel = NSTextField(labelWithString: "")
        titleLabel.font = NSFont.systemFont(ofSize: AppConstants.Calendar.titleFontSize, weight: .semibold)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Weekday row
        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.distribution = .fillEqually
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        for symbol in MonthGrid.weekdaySymbols() {
            headerStack.addArrangedSubview(makeWeekdayLabel(symbol))
        }
        view.addSubview(headerStack)

        // Day grid container
        calendarStack = NSStackView()
        calendarStack.orientation = .vertical
        calendarStack.distribution = .fillEqually
        calendarStack.spacing = AppConstants.Calendar.rowSpacing
        calendarStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendarStack)

        // Calculator toolbar
        setupToolbar()

        NSLayoutConstraint.activate([
            prevYearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            prevYearButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            prevYearButton.widthAnchor.constraint(equalToConstant: 22),

            prevMonthButton.leadingAnchor.constraint(equalTo: prevYearButton.trailingAnchor, constant: 0),
            prevMonthButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            prevMonthButton.widthAnchor.constraint(equalToConstant: 22),

            nextMonthButton.trailingAnchor.constraint(equalTo: nextYearButton.leadingAnchor, constant: 0),
            nextMonthButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            nextMonthButton.widthAnchor.constraint(equalToConstant: 22),

            nextYearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            nextYearButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            nextYearButton.widthAnchor.constraint(equalToConstant: 22),

            titleLabel.topAnchor.constraint(equalTo: view.topAnchor,
                                            constant: AppConstants.Calendar.topPadding),
            titleLabel.leadingAnchor.constraint(equalTo: prevMonthButton.trailingAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: nextMonthButton.leadingAnchor, constant: -2),

            headerStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                 constant: AppConstants.Calendar.margin),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                  constant: -AppConstants.Calendar.margin),
            headerStack.heightAnchor.constraint(equalToConstant: 18),

            calendarStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 4),
            calendarStack.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                  constant: AppConstants.Calendar.margin),
            calendarStack.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                   constant: -AppConstants.Calendar.margin)
        ])
    }

    private func setupToolbar() {
        workdayButton = NSButton(title: NSLocalizedString("toolbar.workdays", comment: "Toolbar button"),
                                 target: self, action: #selector(workdayTapped))
        daysButton = NSButton(title: NSLocalizedString("toolbar.days", comment: "Toolbar button"),
                              target: self, action: #selector(daysTapped))
        workdayButton.font = NSFont.systemFont(ofSize: AppConstants.Calendar.toolButtonFontSize, weight: .medium)
        daysButton.font = NSFont.systemFont(ofSize: AppConstants.Calendar.toolButtonFontSize, weight: .medium)

        toolbarLabel = NSTextField(labelWithString: "")
        toolbarLabel.font = NSFont.systemFont(ofSize: AppConstants.Calendar.toolButtonFontSize)
        toolbarLabel.textColor = .secondaryLabelColor
        toolbarLabel.alignment = .center
        toolbarLabel.lineBreakMode = .byTruncatingTail

        let toolbar = NSStackView(views: [workdayButton, toolbarLabel, daysButton])
        toolbar.orientation = .horizontal
        toolbar.distribution = .fill
        toolbar.alignment = .centerY
        toolbar.spacing = 8
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: calendarStack.bottomAnchor, constant: 8),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppConstants.Calendar.margin),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppConstants.Calendar.margin),
            toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            toolbar.heightAnchor.constraint(equalToConstant: AppConstants.Calendar.toolbarHeight),
            toolbarLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 90)
        ])
    }

    private func makeNavButton(symbol: String, action: Selector) -> NSButton {
        let button = NSButton()
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        button.imagePosition = .imageOnly
        button.isBordered = false
        button.contentTintColor = .secondaryLabelColor
        button.target = self
        button.action = action
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        return button
    }

    private func makeWeekdayLabel(_ symbol: String) -> NSTextField {
        let label = NSTextField(labelWithString: symbol)
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: AppConstants.Calendar.weekdayFontSize, weight: .medium)
        label.textColor = NSColor.secondaryLabelColor
        return label
    }

    // MARK: - Navigation

    @objc private func goToPreviousMonth() { shiftMonth(by: -1) }
    @objc private func goToNextMonth() { shiftMonth(by: 1) }
    @objc private func goToPreviousYear() { shiftMonth(by: -12) }
    @objc private func goToNextYear() { shiftMonth(by: 12) }

    private func shiftMonth(by months: Int) {
        guard let newDate = Calendar.current.date(byAdding: .month, value: months, to: currentDate) else { return }
        currentDate = newDate
        renderCurrentMonth()
    }

    // MARK: - Toolbar calculators

    @objc private func workdayTapped() {
        beginSelection(.workdays)
    }

    @objc private func daysTapped() {
        beginSelection(.days)
    }

    private func beginSelection(_ mode: SelectionMode) {
        selectionMode = mode
        selectionStart = nil
        selectionEnd = nil
        toolbarLabel.stringValue = NSLocalizedString("toolbar.select.start",
                                                     comment: "Prompt to pick the first date")
        renderCurrentMonth()
    }

    @objc private func cellClicked(_ gesture: NSClickGestureRecognizer) {
        guard selectionMode != .none,
              let cell = gesture.view as? DayCellView,
              let date = cell.representedDate else { return }

        if selectionStart == nil {
            selectionStart = date
            toolbarLabel.stringValue = NSLocalizedString("toolbar.select.end",
                                                         comment: "Prompt to pick the last date")
        } else if selectionEnd == nil {
            var start = selectionStart ?? date
            var end = date
            if end < start { swap(&start, &end) }
            selectionStart = start
            selectionEnd = end
            let mode = selectionMode
            selectionMode = .none
            showResult(mode: mode, start: start, end: end)
        }
        renderCurrentMonth()
    }

    private func showResult(mode: SelectionMode, start: Date, end: Date) {
        let total = WorkdayCounter.totalDays(from: start, to: end)
        let range = "\(Self.shortDate(start)) → \(Self.shortDate(end))"
        switch mode {
        case .workdays:
            let workdays = WorkdayCounter.workdays(from: start, to: end)
            toolbarLabel.stringValue = String(format:
                NSLocalizedString("toolbar.result.workdays",
                                  comment: "Result text, placeholders: range, workdays, total"),
                range, workdays, total)
        case .days:
            toolbarLabel.stringValue = String(format:
                NSLocalizedString("toolbar.result.days",
                                  comment: "Result text, placeholders: range, total"),
                range, total)
        case .none:
            toolbarLabel.stringValue = ""
        }
    }

    private static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LocaleProvider.locale
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    // MARK: - Rendering

    private func renderCurrentMonth() {
        guard let grid = MonthGrid.make(for: currentDate) else { return }
        titleLabel.stringValue = grid.formattedTitle

        for arrangedSubview in calendarStack.arrangedSubviews {
            calendarStack.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }

        for row in 0..<grid.rows {
            let rowStack = NSStackView()
            rowStack.orientation = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = AppConstants.Calendar.cellSpacing
            for column in 0..<MonthGrid.columnsPerWeek {
                rowStack.addArrangedSubview(makeDayCell(grid.cellAt(row: row, column: column)))
            }
            rowStack.heightAnchor.constraint(equalToConstant: AppConstants.Calendar.dayCellHeight).isActive = true
            calendarStack.addArrangedSubview(rowStack)
        }
    }

    private func makeDayCell(_ cell: MonthCell) -> NSView {
        let container = DayCellView()
        container.wantsLayer = true
        container.layer?.cornerRadius = AppConstants.Calendar.dayCellHeight / 2
        container.layer?.masksToBounds = true

        // Gregorian day number
        let dayLabel = NSTextField(labelWithString: String(cell.day))
        dayLabel.alignment = .center
        dayLabel.font = NSFont.systemFont(ofSize: AppConstants.Calendar.dayCellFontSize,
                                          weight: cell.isCurrentMonth ? .regular : .light)
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(dayLabel)

        // Lunar day (Chinese locales only)
        let lunarLabel: NSTextField?
        if let lunar = cell.lunarLabel {
            let label = NSTextField(labelWithString: lunar)
            label.alignment = .center
            label.font = NSFont.systemFont(ofSize: AppConstants.Calendar.lunarFontSize, weight: .light)
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)
            lunarLabel = label
        } else {
            lunarLabel = nil
        }

        // Holiday / make-up workday dot at the bottom centre
        let dot: NSView?
        if cell.isHoliday || cell.isMakeupWorkday {
            let d = NSView()
            d.wantsLayer = true
            d.layer?.cornerRadius = AppConstants.Calendar.dotRadius
            d.layer?.masksToBounds = true
            d.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(d)
            if cell.isHoliday {
                d.layer?.backgroundColor = NSColor.systemGreen.cgColor
            } else {
                d.layer?.backgroundColor = (cell.isToday
                    ? NSColor.white : NSColor.labelColor).cgColor
            }
            dot = d
        } else {
            dot = nil
        }

        // Colors
        if cell.isToday {
            container.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            dayLabel.textColor = .white
            lunarLabel?.textColor = .white.withAlphaComponent(0.85)
        } else if cell.isCurrentMonth {
            dayLabel.textColor = .labelColor
            lunarLabel?.textColor = .secondaryLabelColor
        } else {
            dayLabel.textColor = .tertiaryLabelColor
            lunarLabel?.textColor = .tertiaryLabelColor.withAlphaComponent(0.6)
        }

        // Selection highlight (range endpoints)
        let calendar = LocaleProvider.calendar
        container.representedDate = cell.date
        let isEndpoint = [selectionStart, selectionEnd]
            .compactMap { $0 }
            .contains { calendar.isDate($0, inSameDayAs: cell.date) }
        if isEndpoint {
            container.layer?.borderColor = NSColor.controlAccentColor.cgColor
            container.layer?.borderWidth = 1.5
        }

        // Click gesture for the range selectors
        let gesture = NSClickGestureRecognizer(target: self, action: #selector(cellClicked(_:)))
        container.addGestureRecognizer(gesture)

        NSLayoutConstraint.activate([
            dayLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            dayLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 3)
        ])
        if let lunarLabel = lunarLabel {
            NSLayoutConstraint.activate([
                lunarLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                lunarLabel.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 1)
            ])
        }
        if let dot = dot {
            NSLayoutConstraint.activate([
                dot.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                dot.bottomAnchor.constraint(equalTo: container.bottomAnchor,
                                             constant: -AppConstants.Calendar.dotBottomInset),
                dot.widthAnchor.constraint(equalToConstant: AppConstants.Calendar.dotDiameter),
                dot.heightAnchor.constraint(equalToConstant: AppConstants.Calendar.dotDiameter)
            ])
        }

        return container
    }
}
