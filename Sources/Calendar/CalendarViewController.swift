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
    private var settingsButton: NSButton!
    private var toolbarLabel: NSTextField!

    private var currentDate = Date()
    private var selectionMode: SelectionMode = .none
    private var selectionStart: Date?
    private var selectionEnd: Date?

    /// Called after the user changes the language in the settings menu so the
    /// owning app delegate can rebuild the popover in the new language.
    var onLanguageChanged: (() -> Void)?

    /// Called after the user changes the appearance (theme) so the owning app
    /// delegate can apply it and refresh the menu-bar icon.
    var onAppearanceChanged: (() -> Void)?

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

    // MARK: - UI setup

    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // Navigation header: « ‹ title › »
        prevYearButton = makeNavButton(title: "«", action: #selector(goToPreviousYear))
        prevMonthButton = makeNavButton(title: "‹", action: #selector(goToPreviousMonth))
        nextMonthButton = makeNavButton(title: "›", action: #selector(goToNextMonth))
        nextYearButton = makeNavButton(title: "»", action: #selector(goToNextYear))

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
        workdayButton = makeToolButton(symbol: "calendar.badge.clock",
                                       tip: LocaleProvider.localizedString("toolbar.workdays.tip",
                                                                            fallback: "Workdays between two dates"),
                                       action: #selector(workdayTapped))
        daysButton = makeToolButton(symbol: "calendar",
                                    tip: LocaleProvider.localizedString("toolbar.days.tip",
                                                                       fallback: "Total days between two dates"),
                                    action: #selector(daysTapped))
        settingsButton = makeToolButton(symbol: "gearshape",
                                        tip: LocaleProvider.localizedString("settings.title",
                                                                           fallback: "Settings"),
                                        action: #selector(settingsTapped))

        toolbarLabel = NSTextField(labelWithString: "")
        toolbarLabel.font = NSFont.systemFont(ofSize: AppConstants.Calendar.toolButtonFontSize)
        toolbarLabel.textColor = .secondaryLabelColor
        toolbarLabel.alignment = .center
        toolbarLabel.lineBreakMode = .byTruncatingTail

        let toolbar = NSView()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)

        let toolbarControls: [NSView] = [workdayButton, daysButton, toolbarLabel, settingsButton]
        for control in toolbarControls {
            control.translatesAutoresizingMaskIntoConstraints = false
            toolbar.addSubview(control)
        }

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: calendarStack.bottomAnchor, constant: 8),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppConstants.Calendar.margin),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppConstants.Calendar.margin),
            toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            toolbar.heightAnchor.constraint(equalToConstant: AppConstants.Calendar.toolbarHeight),

            // Left → right: workdays, days | result label (center) | settings
            workdayButton.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor),
            workdayButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            daysButton.leadingAnchor.constraint(equalTo: workdayButton.trailingAnchor, constant: 14),
            daysButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            settingsButton.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor),
            settingsButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            toolbarLabel.centerXAnchor.constraint(equalTo: toolbar.centerXAnchor),
            toolbarLabel.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            toolbarLabel.leadingAnchor.constraint(greaterThanOrEqualTo: daysButton.trailingAnchor, constant: 8),
            toolbarLabel.trailingAnchor.constraint(lessThanOrEqualTo: settingsButton.leadingAnchor, constant: -8),
            toolbarLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }

    private func makeNavButton(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: AppConstants.Calendar.titleFontSize,
                                        weight: .semibold)
        button.contentTintColor = .secondaryLabelColor
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        return button
    }

    private func makeToolButton(symbol: String, tip: String, action: Selector) -> NSButton {
        let button = NSButton()
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: tip)
        button.imagePosition = .imageOnly
        button.isBordered = false
        button.contentTintColor = .secondaryLabelColor
        button.target = self
        button.action = action
        button.toolTip = tip
        return button
    }

    // MARK: - Settings menu

    @objc private func settingsTapped(_ sender: NSButton) {
        let menu = buildSettingsMenu()
        menu.popUp(positioning: nil,
                   at: NSPoint(x: 0, y: sender.bounds.height + 4),
                   in: sender)
    }

    private func buildSettingsMenu() -> NSMenu {
        let menu = NSMenu()
        // Keep the popup menu in the same appearance as the app (otherwise it
        // follows the system menu-bar theme).
        menu.appearance = AppearanceManager.appearance

        // Language submenu
        let languageItem = NSMenuItem(
            title: LocaleProvider.localizedString("settings.language", fallback: "Language"),
            action: nil, keyEquivalent: "")
        let languageMenu = NSMenu()
        languageMenu.appearance = AppearanceManager.appearance
        for language in LocaleProvider.supportedLanguages {
            let item = NSMenuItem(title: LocaleProvider.displayName(for: language.code),
                                  action: #selector(languageSelected(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.representedObject = language.code
            item.state = language.code == LocaleProvider.currentLanguage ? .on : .off
            languageMenu.addItem(item)
        }
        menu.setSubmenu(languageMenu, for: languageItem)
        menu.addItem(languageItem)

        // Appearance submenu (theme)
        let appearanceItem = NSMenuItem(
            title: LocaleProvider.localizedString("settings.appearance", fallback: "Appearance"),
            action: nil, keyEquivalent: "")
        let appearanceMenu = NSMenu()
        appearanceMenu.appearance = AppearanceManager.appearance
        let appearanceModes: [(mode: AppearanceManager.Mode, key: String, fallback: String)] = [
            (.system, "settings.appearance.system", "Follow System"),
            (.light, "settings.appearance.light", "Light"),
            (.dark, "settings.appearance.dark", "Dark")
        ]
        for entry in appearanceModes {
            let item = NSMenuItem(
                title: LocaleProvider.localizedString(entry.key, fallback: entry.fallback),
                action: #selector(appearanceSelected(_:)),
                keyEquivalent: "")
            item.target = self
            item.representedObject = entry.mode.rawValue
            item.state = entry.mode == AppearanceManager.current ? .on : .off
            appearanceMenu.addItem(item)
        }
        menu.setSubmenu(appearanceMenu, for: appearanceItem)
        menu.addItem(appearanceItem)

        menu.addItem(.separator())

        // Launch at login toggle
        let launchItem = makeMenuItem(
            LocaleProvider.localizedString("settings.launchAtLogin", fallback: "Launch at Login"),
            action: #selector(toggleLaunchAtLogin))
        launchItem.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(.separator())

        menu.addItem(makeMenuItem(
            LocaleProvider.localizedString("settings.checkUpdates", fallback: "Check for Updates…"),
            action: #selector(checkForUpdates)))
        menu.addItem(makeMenuItem(
            LocaleProvider.localizedString("settings.about", fallback: "About TopCal"),
            action: #selector(showAbout)))

        menu.addItem(.separator())
        menu.addItem(makeMenuItem(
            LocaleProvider.localizedString("settings.quit", fallback: "Quit TopCal"),
            action: #selector(quitApp)))

        return menu
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let manager = LaunchAtLoginManager.shared
        let enabled = manager.isEnabled
        if enabled {
            manager.unregister()
        } else {
            manager.register()
        }
        UserDefaults.standard.set(!enabled, forKey: Self.launchAtLoginPreferenceKey)
        sender.state = enabled ? .off : .on
    }

    /// Preference key recording the user's launch-at-login choice so the app
    /// doesn't re-register itself after they turn it off.
    static let launchAtLoginPreferenceKey = "LaunchAtLogin"

    private func makeMenuItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func languageSelected(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String, code != LocaleProvider.currentLanguage else { return }
        LocaleProvider.userLanguage = code
        onLanguageChanged?()
    }

    @objc private func appearanceSelected(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String else { return }
        UserDefaults.standard.set(raw, forKey: AppearanceManager.preferenceKey)
        onAppearanceChanged?()
    }

    @objc private func checkForUpdates() {
        guard let url = URL(string: "https://api.github.com/repos/zhengwu119/TopCal/releases/latest") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tag = json["tag_name"] as? String else {
                    self?.showAlert(
                        message: LocaleProvider.localizedString("update.error", fallback: "Update check failed"),
                        info: error?.localizedDescription ?? "",
                        buttons: [])
                    return
                }
                self?.handleUpdateResult(latestTag: tag)
            }
        }.resume()
    }

    private func handleUpdateResult(latestTag: String) {
        let latest = latestTag.replacingOccurrences(of: "v", with: "")
        let local = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

        if Self.compareVersions(latest, local) > 0 {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = LocaleProvider.localizedString("update.available",
                                                               fallback: "A new version is available")
            alert.informativeText = String(format:
                LocaleProvider.localizedString("update.available.info",
                                               fallback: "TopCal %@ is available (you have %@)."),
                latest, local)
            alert.addButton(withTitle: LocaleProvider.localizedString("update.download", fallback: "Download"))
            alert.addButton(withTitle: LocaleProvider.localizedString("common.cancel", fallback: "Cancel"))
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "https://github.com/zhengwu119/TopCal/releases/latest") {
                    NSWorkspace.shared.open(url)
                }
            }
        } else {
            showAlert(
                message: LocaleProvider.localizedString("update.latest", fallback: "You're up to date"),
                info: String(format:
                    LocaleProvider.localizedString("update.latest.info",
                                                   fallback: "TopCal %@ is the latest version."),
                    local),
                buttons: [])
        }
    }

    @objc private func showAbout() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "TopCal · 顶历"
        alert.informativeText = LocaleProvider.localizedString("about.info",
                                                               fallback: "Version %@ — a minimal macOS menu bar calendar.\nMIT License © Alex Liu")
            .replacingOccurrences(of: "%@", with: version)
        if let appIcon = NSApp.applicationIconImage {
            alert.icon = appIcon
        }
        alert.runModal()
    }

    private func showAlert(message: String, info: String, buttons: [String]) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = message
        alert.informativeText = info
        if buttons.isEmpty {
            alert.addButton(withTitle: LocaleProvider.localizedString("common.ok", fallback: "OK"))
        } else {
            for title in buttons {
                alert.addButton(withTitle: title)
            }
        }
        alert.runModal()
    }

    /// Compares "x.y.z" version strings: > 0 if lhs is newer, < 0 if older.
    private static func compareVersions(_ lhs: String, _ rhs: String) -> Int {
        let l = lhs.split(separator: ".").compactMap { Int($0) }
        let r = rhs.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(l.count, r.count) {
            let a = i < l.count ? l[i] : 0
            let b = i < r.count ? r[i] : 0
            if a != b { return a > b ? 1 : -1 }
        }
        return 0
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
        toggleSelection(.workdays)
    }

    @objc private func daysTapped() {
        toggleSelection(.days)
    }

    /// Clicking a calculator button either starts a selection or — if a
    /// selection is already in progress for that mode or a result is shown —
    /// resets everything back to the initial state.
    private func toggleSelection(_ mode: SelectionMode) {
        if selectionMode == mode || selectionEnd != nil || selectionStart != nil {
            resetSelection()
            return
        }
        beginSelection(mode)
    }

    private func resetSelection() {
        selectionMode = .none
        selectionStart = nil
        selectionEnd = nil
        toolbarLabel.stringValue = ""
        renderCurrentMonth()
    }

    private func beginSelection(_ mode: SelectionMode) {
        selectionMode = mode
        selectionStart = nil
        selectionEnd = nil
        toolbarLabel.stringValue = LocaleProvider.localizedString("toolbar.select.start",
                                                                  fallback: "Pick the first date")
        renderCurrentMonth()
    }

    @objc private func cellClicked(_ gesture: NSClickGestureRecognizer) {
        guard selectionMode != .none,
              let cell = gesture.view as? DayCellView,
              let date = cell.representedDate else { return }

        if selectionStart == nil {
            selectionStart = date
            toolbarLabel.stringValue = LocaleProvider.localizedString("toolbar.select.end",
                                                                      fallback: "Pick the last date")
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
                LocaleProvider.localizedString("toolbar.result.workdays",
                                               fallback: "%@ · %d workdays / %d days total"),
                range, workdays, total)
        case .days:
            toolbarLabel.stringValue = String(format:
                LocaleProvider.localizedString("toolbar.result.days",
                                               fallback: "%@ · %d days total"),
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
        container.layer?.cornerRadius = AppConstants.Calendar.cellCornerRadius
        container.layer?.masksToBounds = true

        // Hover tooltip for holidays / make-up workdays
        if let tip = HolidayCalendar.holidayTooltip(for: cell.date) {
            container.toolTip = tip
        } else if let tip = HolidayCalendar.makeupTooltip(for: cell.date) {
            container.toolTip = tip
        }

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
