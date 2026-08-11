import AppKit

class CalendarViewController: NSViewController {
    private var prevButton: NSButton!
    private var nextButton: NSButton!
    private var titleLabel: NSTextField!
    private var calendarStack: NSStackView!
    private var currentDate: Date

    override init(nibName: String?, bundle: Bundle?) {
        self.currentDate = Date()
        super.init(nibName: nibName, bundle: bundle)
    }

    required init?(coder: NSCoder) {
        self.currentDate = Date()
        super.init(coder: coder)
    }

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 270))
        setupUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildCalendar()
    }

    func refresh() {
        let _ = view
        currentDate = Date()
        buildCalendar()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // ---- Navigation bar ----
        prevButton = NSButton(title: "◀", target: self, action: #selector(goToPreviousMonth))
        prevButton.bezelStyle = .inline
        prevButton.isBordered = false
        prevButton.font = NSFont.systemFont(ofSize: 11)
        prevButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(prevButton)

        nextButton = NSButton(title: "▶", target: self, action: #selector(goToNextMonth))
        nextButton.bezelStyle = .inline
        nextButton.isBordered = false
        nextButton.font = NSFont.systemFont(ofSize: 11)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextButton)

        titleLabel = NSTextField(labelWithString: "")
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Weekday headers — localized, aligned to the calendar's first weekday
        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.distribution = .fillEqually
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        for symbol in Self.weekdaySymbols() {
            let label = NSTextField(labelWithString: symbol)
            label.alignment = .center
            label.font = NSFont.systemFont(ofSize: 10, weight: .medium)
            label.textColor = NSColor.secondaryLabelColor
            headerStack.addArrangedSubview(label)
        }
        view.addSubview(headerStack)

        // ---- Calendar grid ----
        calendarStack = NSStackView()
        calendarStack.orientation = .vertical
        calendarStack.distribution = .fillEqually
        calendarStack.spacing = 2
        calendarStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendarStack)

        NSLayoutConstraint.activate([
            prevButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            prevButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            prevButton.widthAnchor.constraint(equalToConstant: 24),

            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            nextButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 24),

            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: prevButton.trailingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -4),

            headerStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            headerStack.heightAnchor.constraint(equalToConstant: 18),

            calendarStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 4),
            calendarStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            calendarStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            calendarStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])
    }

    // MARK: - Navigation

    @objc private func goToPreviousMonth() {
        let calendar = Calendar.current
        guard let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) else { return }
        currentDate = newDate
        buildCalendar()
    }

    @objc private func goToNextMonth() {
        let calendar = Calendar.current
        guard let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) else { return }
        currentDate = newDate
        buildCalendar()
    }

    // MARK: - Calendar Builder

    private func buildCalendar() {
        // Remove old rows
        for arrangedSubview in calendarStack.arrangedSubviews {
            calendarStack.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }

        let calendar = Calendar.current

        // Title — localized month/year format following the system language
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.dateFormat = NSLocalizedString("month.title.format",
                                                 comment: "Month/year title format for the calendar header")
        titleLabel.stringValue = formatter.string(from: currentDate)

        // Determine if we're viewing the current month (for today highlight)
        let nowComps = calendar.dateComponents([.year, .month], from: Date())
        let shownComps = calendar.dateComponents([.year, .month], from: currentDate)
        let isCurrentMonth = (nowComps.year == shownComps.year && nowComps.month == shownComps.month)
        let todayDay = calendar.component(.day, from: Date())

        // Month data
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)),
              let range = calendar.range(of: .day, in: .month, for: currentDate) else { return }
        let weekdayOfFirst = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = range.count

        let totalCells = daysInMonth + (weekdayOfFirst - 1)
        let rows = Int(ceil(Double(totalCells) / 7.0))

        for row in 0..<rows {
            let rowStack = NSStackView()
            rowStack.orientation = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 2

            for col in 0..<7 {
                let index = row * 7 + col
                let dayOfMonth = index - (weekdayOfFirst - 1) + 1

                if dayOfMonth >= 1 && dayOfMonth <= daysInMonth {
                    let highlight = isCurrentMonth && dayOfMonth == todayDay
                    rowStack.addArrangedSubview(makeDayCell(day: dayOfMonth, isToday: highlight))
                } else {
                    rowStack.addArrangedSubview(makeEmptyCell())
                }
            }

            rowStack.heightAnchor.constraint(equalToConstant: 26).isActive = true
            calendarStack.addArrangedSubview(rowStack)
        }
    }

    // MARK: - Cell Helpers

    /// Localized weekday abbreviations (e.g. 日/一/二… or S/M/T…),
    /// rotated so the column order starts on the calendar's first weekday.
    private static func weekdaySymbols() -> [String] {
        let calendar = Calendar.current
        var symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1  // 0-based index
        if first > 0 && first < symbols.count {
            symbols = Array(symbols[first...] + symbols[..<first])
        }
        return symbols
    }

    private func makeDayCell(day: Int, isToday: Bool) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 13
        container.layer?.masksToBounds = true

        let label = NSTextField(labelWithString: String(day))
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        if isToday {
            container.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            label.textColor = NSColor.white
        } else {
            label.textColor = NSColor.labelColor
        }

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func makeEmptyCell() -> NSView {
        return NSView()
    }
}
