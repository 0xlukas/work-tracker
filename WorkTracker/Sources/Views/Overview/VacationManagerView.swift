import SwiftUI
import SwiftData
import AppKit

// MARK: - Full Absences View (sidebar section)

struct AbsencesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VacationDay.date) private var allVacationDays: [VacationDay]

    @State private var selectedYear = Calendar.zurich.component(.year, from: Date())
    @State private var lastClickedDate: Date?
    @State private var mode: AbsenceType = .vacation

    private let yearRange = 2026...2036

    private var entitlement: Double { AppSettings.vacationEntitlement }

    private var absencesForYear: [VacationDay] {
        allVacationDays.filter { Calendar.zurich.component(.year, from: $0.date) == selectedYear }
    }

    private var vacationDaysForYear: [VacationDay] {
        absencesForYear.filter { $0.resolvedType == .vacation }
    }

    private var sickDaysForYear: [VacationDay] {
        absencesForYear.filter { $0.resolvedType == .sick }
    }

    /// Vacation day count: manual half-days and holiday half-days both count as 0.5
    private var vacationCount: Double {
        vacationDaysForYear.reduce(0.0) { total, vd in
            let normalized = vd.date.startOfDayZurich
            if vd.isHalfDay || holidayLookup[normalized] == .halfDay {
                return total + 0.5
            }
            return total + 1.0
        }
    }

    /// Sick day count: half-days count as 0.5
    private var sickCount: Double {
        sickDaysForYear.reduce(0.0) { total, vd in
            total + (vd.isHalfDay ? 0.5 : 1.0)
        }
    }

    private var holidayLookup: [Date: HolidayType] {
        ZurichHolidays.holidayLookup(for: selectedYear)
    }

    private var eligibleDays: [Date] {
        let cal = Calendar.zurich
        let tz = TimeZone(identifier: "Europe/Zurich")!
        let start = cal.date(from: DateComponents(timeZone: tz, year: selectedYear, month: 1, day: 1))!
        let end = cal.date(from: DateComponents(timeZone: tz, year: selectedYear, month: 12, day: 31))!
        return start.daysThrough(end).filter { !$0.isWeekend && holidayLookup[$0] != .fullDay }
    }

    private var eligibleDaySet: Set<Date> { Set(eligibleDays) }

    /// Lookup: date → VacationDay for quick access to type/isHalfDay
    private var absenceLookup: [Date: VacationDay] {
        Dictionary(uniqueKeysWithValues: absencesForYear.map { ($0.date.startOfDayZurich, $0) })
    }

    private var monthGroups: [(month: String, days: [Date])] {
        let cal = Calendar.zurich
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let grouped = Dictionary(grouping: eligibleDays) { cal.component(.month, from: $0) }
        return grouped.sorted { $0.key < $1.key }.map { (month, days) in
            (month: formatter.monthSymbols[month - 1].capitalized, days: days.sorted())
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tr("Absences"))
                        .font(.title2.bold())
                    HStack(spacing: 4) {
                        Text(tr("Year"))
                            .foregroundStyle(.secondary)
                        Picker("", selection: $selectedYear) {
                            ForEach(yearRange, id: \.self) { Text(String($0)).tag($0) }
                        }
                        .labelsHidden()
                        .frame(width: 80)
                    }
                    .font(.subheadline)
                }

                Spacer()

                // Counter — varies by mode
                if mode == .vacation {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(tr("%@ / %@ days", TimeFormatting.days(vacationCount), TimeFormatting.days(entitlement)))
                            .font(.title3.bold().monospacedDigit())
                            .foregroundStyle(vacationCount > entitlement ? .red : .primary)
                        let remaining = entitlement - vacationCount
                        if remaining >= 0 {
                            Text(tr("%@ remaining", TimeFormatting.days(remaining)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(tr("%@ over budget", TimeFormatting.days(abs(remaining))))
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.primary.opacity(0.04)))
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(tr("%@ sick days", TimeFormatting.days(sickCount)))
                            .font(.title3.bold().monospacedDigit())
                            .foregroundStyle(.primary)
                        Text(tr("this year"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.primary.opacity(0.04)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Mode toggle
            Picker("", selection: $mode) {
                Label(tr("Vacation"), systemImage: "airplane").tag(AbsenceType.vacation)
                Label(tr("Sick"), systemImage: "thermometer.medium").tag(AbsenceType.sick)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // Hint
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.blue)
                    .font(.caption)
                Text(LocalizedStringKey(hintText))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 24)

            // Day grid
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(monthGroups, id: \.month) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.month)
                                .font(.subheadline.bold())

                            FlowLayout(spacing: 3) {
                                ForEach(group.days, id: \.self) { date in
                                    DayCell(
                                        date: date,
                                        absence: absenceLookup[date],
                                        isHalfDayHoliday: holidayLookup[date] == .halfDay,
                                        isLastClicked: lastClickedDate == date
                                    ) { isShift in
                                        if isShift {
                                            handleShiftClick(date: date)
                                        } else {
                                            handleClick(date: date)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(tr("Absences"))
    }

    private var hintText: String {
        switch mode {
        case .vacation:
            return tr("Click: full day → half day → remove. **Shift+click** to select a range. Click a sick day to convert it to vacation.")
        case .sick:
            return tr("Click: full day → half day → remove. **Shift+click** to select a range. Click a vacation day to convert it to sick.")
        }
    }

    // MARK: - Actions

    private func handleClick(date: Date) {
        let normalized = date.startOfDayZurich
        if let existing = absencesForYear.first(where: { $0.date.isSameDay(as: normalized) }) {
            if existing.resolvedType != mode {
                // Different type → overwrite as full of the selected mode
                existing.type = mode
                existing.isHalfDay = false
            } else if !existing.isHalfDay {
                // Same type, full → half
                existing.isHalfDay = true
            } else {
                // Same type, half → remove
                modelContext.delete(existing)
            }
        } else {
            // Not set → full of the selected mode
            modelContext.insert(VacationDay(date: normalized, isHalfDay: false, type: mode))
        }
        lastClickedDate = normalized
    }

    private func handleShiftClick(date: Date) {
        let normalized = date.startOfDayZurich
        guard let anchor = lastClickedDate else {
            handleClick(date: date)
            return
        }
        let start = min(anchor, normalized)
        let end = max(anchor, normalized)
        let rangeDays = start.daysThrough(end).filter { eligibleDaySet.contains($0) }
        for day in rangeDays {
            if let existing = absencesForYear.first(where: { $0.date.isSameDay(as: day) }) {
                // Convert other-type entries to selected mode (full); leave same-type alone
                if existing.resolvedType != mode {
                    existing.type = mode
                    existing.isHalfDay = false
                }
            } else {
                modelContext.insert(VacationDay(date: day, isHalfDay: false, type: mode))
            }
        }
        lastClickedDate = normalized
    }

}

// MARK: - Day Cell (NSViewRepresentable for reliable clicks)

struct DayCell: NSViewRepresentable {
    let date: Date
    let absence: VacationDay?
    let isHalfDayHoliday: Bool
    let isLastClicked: Bool
    let action: (Bool) -> Void  // Bool = isShiftHeld

    func makeNSView(context: Context) -> DayCellNSView {
        let view = DayCellNSView()
        view.action = action
        updateAppearance(view)
        return view
    }

    func updateNSView(_ nsView: DayCellNSView, context: Context) {
        nsView.action = action
        updateAppearance(nsView)
    }

    private func updateAppearance(_ view: DayCellNSView) {
        let dayNum = Calendar.zurich.component(.day, from: date)
        let weekday = Calendar.zurich.component(.weekday, from: date)
        let weekdayName = Calendar.zurich.shortWeekdaySymbols[weekday - 1]
        view.configure(
            dayText: "\(dayNum)",
            weekdayText: weekdayName,
            absenceType: absence?.resolvedType,
            isHalfDayAbsence: absence?.isHalfDay == true,
            isHalfDayHoliday: isHalfDayHoliday,
            isLastClicked: isLastClicked
        )
    }
}

class DayCellNSView: NSView {
    var action: ((Bool) -> Void)?

    private let weekdayLabel = NSTextField(labelWithString: "")
    private let dayLabel = NSTextField(labelWithString: "")
    private let iconView = NSImageView()
    private var absenceType: AbsenceType?
    private var isHalfDayAbsence = false
    private var isHalfDayHoliday = false
    private var isLastClicked = false
    private var isHovered = false

    override init(frame: NSRect) {
        super.init(frame: NSRect(x: 0, y: 0, width: 40, height: 40))
        wantsLayer = true
        layer?.cornerRadius = 6

        // Dynamic Type: size tracks the user's text-size setting.
        weekdayLabel.font = .preferredFont(forTextStyle: .caption2)
        weekdayLabel.alignment = .center
        weekdayLabel.isBezeled = false
        weekdayLabel.drawsBackground = false
        weekdayLabel.isEditable = false

        dayLabel.font = .systemFont(ofSize: NSFont.preferredFont(forTextStyle: .body).pointSize, weight: .bold)
        dayLabel.alignment = .center
        dayLabel.isBezeled = false
        dayLabel.drawsBackground = false
        dayLabel.isEditable = false

        iconView.imageScaling = .scaleProportionallyDown
        iconView.isHidden = true

        addSubview(weekdayLabel)
        addSubview(dayLabel)
        addSubview(iconView)

        setAccessibilityRole(.button)
        setAccessibilityElement(true)

        let area = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect], owner: self)
        addTrackingArea(area)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { NSSize(width: 40, height: 40) }

    override func layout() {
        super.layout()
        weekdayLabel.frame = NSRect(x: 0, y: 20, width: bounds.width, height: 14)
        dayLabel.frame = NSRect(x: 0, y: 4, width: bounds.width, height: 16)
        iconView.frame = NSRect(x: bounds.width - 14, y: bounds.height - 14, width: 11, height: 11)
    }

    func configure(dayText: String, weekdayText: String, absenceType: AbsenceType?,
                   isHalfDayAbsence: Bool, isHalfDayHoliday: Bool, isLastClicked: Bool) {
        dayLabel.stringValue = dayText
        weekdayLabel.stringValue = weekdayText
        self.absenceType = absenceType
        self.isHalfDayAbsence = isHalfDayAbsence
        self.isHalfDayHoliday = isHalfDayHoliday
        self.isLastClicked = isLastClicked

        // Shape cue so absence type is distinguishable without relying on colour.
        switch absenceType {
        case .vacation:
            iconView.image = NSImage(systemSymbolName: "airplane", accessibilityDescription: tr("Vacation"))
            iconView.isHidden = false
        case .sick:
            iconView.image = NSImage(systemSymbolName: "cross.case.fill", accessibilityDescription: tr("Sick"))
            iconView.isHidden = false
        case .none:
            iconView.image = nil
            iconView.isHidden = true
        }

        let stateText: String
        switch absenceType {
        case .vacation: stateText = isHalfDayAbsence ? tr("half-day vacation") : tr("vacation")
        case .sick: stateText = isHalfDayAbsence ? tr("half-day sick") : tr("sick")
        case .none: stateText = isHalfDayHoliday ? tr("half-day holiday") : tr("no absence")
        }
        setAccessibilityLabel(tr("%@ %@, %@", weekdayText, dayText, stateText))

        updateColors()
    }

    private func updateColors() {
        let baseColor: NSColor? = {
            switch absenceType {
            case .vacation: return .systemBlue
            case .sick: return .systemRed
            case .none: return nil
            }
        }()

        iconView.contentTintColor = .white

        if let baseColor {
            if isHalfDayAbsence {
                // Half-day: lighter fill, colored border
                layer?.backgroundColor = baseColor.withAlphaComponent(0.4).cgColor
                dayLabel.textColor = .white
                weekdayLabel.textColor = .white.withAlphaComponent(0.8)
                layer?.borderWidth = 2
                layer?.borderColor = baseColor.cgColor
            } else {
                // Full day
                layer?.backgroundColor = baseColor.cgColor
                dayLabel.textColor = .white
                weekdayLabel.textColor = .white.withAlphaComponent(0.85)
                layer?.borderWidth = isLastClicked ? 2 : 0
                layer?.borderColor = NSColor.white.cgColor
            }
        } else if isHovered {
            layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.12).cgColor
            dayLabel.textColor = .labelColor
            weekdayLabel.textColor = .secondaryLabelColor
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.systemBlue.withAlphaComponent(0.3).cgColor
        } else if isHalfDayHoliday {
            layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.15).cgColor
            dayLabel.textColor = .labelColor
            weekdayLabel.textColor = .secondaryLabelColor
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.systemOrange.withAlphaComponent(0.5).cgColor
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
            dayLabel.textColor = .labelColor
            weekdayLabel.textColor = .secondaryLabelColor
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.2).cgColor
        }
    }

    override func mouseDown(with event: NSEvent) {
        // Visual press feedback
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.05
            self.animator().alphaValue = 0.6
        }
    }

    override func mouseUp(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.1
            self.animator().alphaValue = 1.0
        }
        let isShift = event.modifierFlags.contains(.shift)
        action?(isShift)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        updateColors()
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        updateColors()
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangeSubviews(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                                  proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }
        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
