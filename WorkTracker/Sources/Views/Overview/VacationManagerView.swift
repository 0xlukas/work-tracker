import SwiftUI
import SwiftData
import AppKit

// MARK: - Full Vacation View (sidebar section)

struct VacationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VacationDay.date) private var allVacationDays: [VacationDay]

    @State private var selectedYear = Calendar.zurich.component(.year, from: Date())
    @State private var lastClickedDate: Date?

    private let yearRange = 2026...2036

    private var vacationDaysForYear: [VacationDay] {
        allVacationDays.filter { Calendar.zurich.component(.year, from: $0.date) == selectedYear }
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

    private var vacationDateSet: Set<Date> {
        Set(vacationDaysForYear.map { $0.date.startOfDayZurich })
    }

    /// Lookup: date → VacationDay for quick access to isHalfDay
    private var vacationDayLookup: [Date: VacationDay] {
        Dictionary(uniqueKeysWithValues: vacationDaysForYear.map { ($0.date.startOfDayZurich, $0) })
    }

    private var monthGroups: [(month: String, days: [Date])] {
        let cal = Calendar.zurich
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_CH")
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
                    Text("Vacation")
                        .font(.title2.bold())
                    HStack(spacing: 4) {
                        Text("Year")
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

                // Counter
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(formatDays(vacationCount)) / 25 days")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(vacationCount > 25 ? .red : .primary)
                    let remaining = 25.0 - vacationCount
                    if remaining >= 0 {
                        Text("\(formatDays(remaining)) remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(formatDays(abs(remaining))) over budget")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(.primary.opacity(0.04)))
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Hint
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.blue)
                    .font(.caption)
                Text("Click: full day → half day → remove. **Shift+click** to select a range.")
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
                                        isVacation: vacationDateSet.contains(date),
                                        isHalfDayVacation: vacationDayLookup[date]?.isHalfDay == true,
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
        .navigationTitle("Vacation")
    }

    // MARK: - Actions

    private func handleClick(date: Date) {
        let normalized = date.startOfDayZurich
        if let existing = vacationDaysForYear.first(where: { $0.date.isSameDay(as: normalized) }) {
            if !existing.isHalfDay {
                // Full day → half day
                existing.isHalfDay = true
            } else {
                // Half day → remove
                modelContext.delete(existing)
            }
        } else {
            // Not set → full day
            modelContext.insert(VacationDay(date: normalized))
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
            if !vacationDateSet.contains(day) {
                modelContext.insert(VacationDay(date: day))
            }
        }
        lastClickedDate = normalized
    }

    private func formatDays(_ days: Double) -> String {
        if days == days.rounded() {
            return "\(Int(days))"
        }
        return String(format: "%.1f", days)
    }
}

// MARK: - Day Cell (NSViewRepresentable for reliable clicks)

struct DayCell: NSViewRepresentable {
    let date: Date
    let isVacation: Bool
    let isHalfDayVacation: Bool
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
            isVacation: isVacation,
            isHalfDayVacation: isHalfDayVacation,
            isHalfDayHoliday: isHalfDayHoliday,
            isLastClicked: isLastClicked
        )
    }
}

class DayCellNSView: NSView {
    var action: ((Bool) -> Void)?

    private let weekdayLabel = NSTextField(labelWithString: "")
    private let dayLabel = NSTextField(labelWithString: "")
    private var isVacation = false
    private var isHalfDayVacation = false
    private var isHalfDayHoliday = false
    private var isLastClicked = false
    private var isHovered = false

    override init(frame: NSRect) {
        super.init(frame: NSRect(x: 0, y: 0, width: 40, height: 40))
        wantsLayer = true
        layer?.cornerRadius = 6

        weekdayLabel.font = .systemFont(ofSize: 9)
        weekdayLabel.alignment = .center
        weekdayLabel.isBezeled = false
        weekdayLabel.drawsBackground = false
        weekdayLabel.isEditable = false

        dayLabel.font = .boldSystemFont(ofSize: 11)
        dayLabel.alignment = .center
        dayLabel.isBezeled = false
        dayLabel.drawsBackground = false
        dayLabel.isEditable = false

        addSubview(weekdayLabel)
        addSubview(dayLabel)

        let area = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect], owner: self)
        addTrackingArea(area)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { NSSize(width: 40, height: 40) }

    override func layout() {
        super.layout()
        weekdayLabel.frame = NSRect(x: 0, y: 20, width: bounds.width, height: 14)
        dayLabel.frame = NSRect(x: 0, y: 4, width: bounds.width, height: 16)
    }

    func configure(dayText: String, weekdayText: String, isVacation: Bool, isHalfDayVacation: Bool, isHalfDayHoliday: Bool, isLastClicked: Bool) {
        dayLabel.stringValue = dayText
        weekdayLabel.stringValue = weekdayText
        self.isVacation = isVacation
        self.isHalfDayVacation = isHalfDayVacation
        self.isHalfDayHoliday = isHalfDayHoliday
        self.isLastClicked = isLastClicked
        updateColors()
    }

    private func updateColors() {
        if isVacation && isHalfDayVacation {
            // Half-day vacation: half-filled look
            layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.4).cgColor
            dayLabel.textColor = .white
            weekdayLabel.textColor = .white.withAlphaComponent(0.8)
            layer?.borderWidth = 2
            layer?.borderColor = NSColor.systemBlue.cgColor
        } else if isVacation {
            // Full-day vacation
            layer?.backgroundColor = NSColor.systemBlue.cgColor
            dayLabel.textColor = .white
            weekdayLabel.textColor = .white.withAlphaComponent(0.85)
            layer?.borderWidth = isLastClicked ? 2 : 0
            layer?.borderColor = NSColor.white.cgColor
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
