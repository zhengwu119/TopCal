import AppKit

/// Popover content: month/year header + weekday row + day grid.
///
/// Data computation lives in `MonthGrid` (a pure model); this view controller
/// is responsible only for layout and rendering.
class CalendarViewController: NSViewController {
    private var prevButton: NSButton!
    private var nextButton: NSButton!
    private var titleLabel: NSTextField!
    private var calendarStack: NSStackView!
    private var grid = MonthGrid.make(for: Date()) ?? MonthGrid(date: Date(),
                                                               weekdayOfFirst: 1,
                                                               daysInMonth: 1,
                                                               rows: 1,
                                                               isCurrentMonth: true,
                                                               todayDay: 1)
    private var currentDate = Date()

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

    // MARK: - UI setup

    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // Navigation header
        prevButton = makeNavButton(title: "◀", action: #selector(goToPreviousMonth))
        nextButton = makeNavButton(title: "▶", action: #selector(goToNextMonth))

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

        NSLayoutConstraint.activate([
            prevButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            prevButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            prevButton.widthAnchor.constraint(equalToConstant: 24),

            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            nextButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 24),

            titleLabel.topAnchor.constraint(equalTo: view.topAnchor,
                                            constant: AppConstants.Calendar.topPadding),
            titleLabel.leadingAnchor.constraint(equalTo: prevButton.trailingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -4),

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
                                                   constant: -AppConstants.Calendar.margin),
            calendarStack.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                 constant: -AppConstants.Calendar.margin)
        ])
    }

    private func makeNavButton(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .inline
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 11)
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

    @objc private func goToPreviousMonth() {
        shiftMonth(by: -1)
    }

    @objc private func goToNextMonth() {
        shiftMonth(by: 1)
    }

    private func shiftMonth(by months: Int) {
        guard let newDate = Calendar.current.date(byAdding: .month, value: months, to: currentDate) else { return }
        currentDate = newDate
        renderCurrentMonth()
    }

    // MARK: - Rendering

    private func renderCurrentMonth() {
        // Update title from the current month
        guard let grid = MonthGrid.make(for: currentDate) else { return }
        self.grid = grid
        titleLabel.stringValue = grid.formattedTitle

        // Rebuild day grid
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
                if let day = grid.dayAt(row: row, column: column) {
                    let isToday = grid.isCurrentMonth && day == grid.todayDay
                    rowStack.addArrangedSubview(makeDayCell(day: day, isToday: isToday))
                } else {
                    rowStack.addArrangedSubview(NSView())
                }
            }
            rowStack.heightAnchor.constraint(equalToConstant: AppConstants.Calendar.dayCellHeight).isActive = true
            calendarStack.addArrangedSubview(rowStack)
        }
    }

    private func makeDayCell(day: Int, isToday: Bool) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = AppConstants.Calendar.dayCellHeight / 2
        container.layer?.masksToBounds = true

        let label = NSTextField(labelWithString: String(day))
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: AppConstants.Calendar.dayCellFontSize,
                                       weight: AppConstants.Calendar.dayCellFontWeight)
        label.textColor = isToday ? .white : .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        if isToday {
            container.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        }

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }
}