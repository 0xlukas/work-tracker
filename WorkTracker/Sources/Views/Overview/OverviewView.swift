import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct OverviewView: View {
    @Query(sort: \WorkSegment.startTime) private var allSegments: [WorkSegment]
    @Query(sort: \VacationDay.date) private var allVacationDays: [VacationDay]

    @State private var selectedYear = Calendar.zurich.component(.year, from: Date())
    @State private var trackingStartDate: Date = AppSettings.trackingStartDate
    @State private var showStartDatePicker = false

    private let calculator = WorkHoursCalculator()
    private let yearRange = 2026...2036

    private var today: Date { Calendar.zurich.startOfDay(for: Date()) }

    // Effective start for the selected year: max(trackingStartDate, yearStart)
    private var effectiveYearStart: Date {
        let yearStart = Calendar.zurich.date(from: DateComponents(
            timeZone: TimeZone(identifier: "Europe/Zurich"),
            year: selectedYear, month: 1, day: 1))!
        return max(trackingStartDate, yearStart)
    }

    private var yearEnd: Date {
        Calendar.zurich.date(from: DateComponents(
            timeZone: TimeZone(identifier: "Europe/Zurich"),
            year: selectedYear, month: 12, day: 31))!
    }

    // "Up to today" end: min(today, yearEnd)
    private var effectiveEnd: Date {
        min(today, yearEnd)
    }

    private var absenceLookupForYear: [Date: AbsenceEntry] {
        var lookup: [Date: AbsenceEntry] = [:]
        for vd in allVacationDays where Calendar.zurich.component(.year, from: vd.date) == selectedYear {
            lookup[vd.date.startOfDayZurich] = AbsenceEntry(type: vd.resolvedType, isHalfDay: vd.isHalfDay)
        }
        return lookup
    }

    private var allAbsenceLookup: [Date: AbsenceEntry] {
        var lookup: [Date: AbsenceEntry] = [:]
        for vd in allVacationDays {
            lookup[vd.date.startOfDayZurich] = AbsenceEntry(type: vd.resolvedType, isHalfDay: vd.isHalfDay)
        }
        return lookup
    }

    /// Full calendar year summary (Jan 1 - Dec 31) for pills
    private var fullCalendarYearSummary: PeriodSummary {
        let yearStart = Calendar.zurich.date(from: DateComponents(
            timeZone: TimeZone(identifier: "Europe/Zurich"),
            year: selectedYear, month: 1, day: 1))!
        return calculator.periodSummary(from: yearStart, to: yearEnd,
                                        absenceLookup: absenceLookupForYear, segments: allSegments)
    }

    // Balance up to today for the selected year
    private var toDateSummary: PeriodSummary {
        guard effectiveYearStart <= effectiveEnd else {
            return PeriodSummary(expectedHours: 0, actualHours: 0,
                                workingDays: 0, holidayDays: 0, halfDayHolidays: 0,
                                vacationDays: 0, sickDays: 0)
        }
        return calculator.periodSummary(from: effectiveYearStart, to: effectiveEnd,
                                        absenceLookup: absenceLookupForYear, segments: allSegments)
    }

    // Full year projection
    private var fullYearSummary: PeriodSummary {
        guard effectiveYearStart <= yearEnd else {
            return PeriodSummary(expectedHours: 0, actualHours: 0,
                                workingDays: 0, holidayDays: 0, halfDayHolidays: 0,
                                vacationDays: 0, sickDays: 0)
        }
        return calculator.periodSummary(from: effectiveYearStart, to: yearEnd,
                                        absenceLookup: absenceLookupForYear, segments: allSegments)
    }

    // Cumulative from tracking start through today
    private var cumulativeSummary: PeriodSummary {
        guard trackingStartDate <= today else {
            return PeriodSummary(expectedHours: 0, actualHours: 0,
                                workingDays: 0, holidayDays: 0, halfDayHolidays: 0,
                                vacationDays: 0, sickDays: 0)
        }
        return calculator.periodSummary(from: trackingStartDate, to: today,
                                        absenceLookup: allAbsenceLookup, segments: allSegments)
    }

    private var monthlyData: [MonthSummary] {
        calculator.monthlyBreakdown(year: selectedYear,
                                    absenceLookup: absenceLookupForYear,
                                    segments: allSegments,
                                    startDate: trackingStartDate,
                                    endDate: today)
    }

    // MARK: - "Right now" snapshot (always present-based, ignores the year picker)

    private var weekStart: Date {
        let cal = Calendar.zurich
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        return cal.date(byAdding: .day, value: -daysFromMonday, to: today)!
    }

    private var monthStart: Date {
        let cal = Calendar.zurich
        return cal.date(from: cal.dateComponents([.year, .month], from: today))!
    }

    private var todaySnapshot: PeriodSummary {
        calculator.periodSummary(from: today, to: today, absenceLookup: allAbsenceLookup, segments: allSegments)
    }
    private var weekSnapshot: PeriodSummary {
        calculator.periodSummary(from: weekStart, to: today, absenceLookup: allAbsenceLookup, segments: allSegments)
    }
    private var monthSnapshot: PeriodSummary {
        calculator.periodSummary(from: monthStart, to: today, absenceLookup: allAbsenceLookup, segments: allSegments)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tr("Overview"))
                            .font(.title.bold())
                        HStack(spacing: 4) {
                            Text(tr("Year"))
                                .foregroundStyle(.secondary)
                            Picker("", selection: $selectedYear) {
                                ForEach(yearRange, id: \.self) { year in
                                    Text(String(year)).tag(year)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 80)
                        }
                        .font(.subheadline)
                    }

                    Spacer()

                    Button {
                        exportCSV()
                    } label: {
                        Label(tr("Export CSV"), systemImage: "square.and.arrow.up")
                    }
                    .help(tr("Export a day-by-day report for %@ as a CSV file", String(selectedYear)))
                }

                // "Right now" snapshot — answers "am I on track?" at a glance
                VStack(alignment: .leading, spacing: 8) {
                    Text(tr("Right Now"))
                        .font(.headline)
                    HStack(spacing: 12) {
                        snapshotCard(tr("Today"), todaySnapshot)
                        snapshotCard(tr("This Week"), weekSnapshot)
                        snapshotCard(tr("This Month"), monthSnapshot)
                    }
                }

                // Tracking start date
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(.blue)
                        .font(.caption)
                    Text(tr("Tracking since"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if showStartDatePicker {
                        DatePicker("", selection: $trackingStartDate, displayedComponents: .date)
                            .labelsHidden()
                            .onChange(of: trackingStartDate) { _, newValue in
                                AppSettings.trackingStartDate = newValue
                            }
                        Button(tr("Done")) {
                            showStartDatePicker = false
                        }
                        .controlSize(.small)
                    } else {
                        Button {
                            showStartDatePicker = true
                        } label: {
                            Text(trackingStartDate, format: .dateTime.day().month(.wide).year())
                                .font(.caption.bold())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(.blue.opacity(0.06)))

                // Primary: Balance to date
                HStack(spacing: 12) {
                    statCard(
                        icon: "target",
                        iconColor: .blue,
                        title: tr("Expected (to date)"),
                        value: TimeFormatting.hours(toDateSummary.expectedHours),
                        detail: tr("%lld working days", toDateSummary.workingDays)
                    )
                    statCard(
                        icon: "checkmark.circle",
                        iconColor: .green,
                        title: tr("Worked (to date)"),
                        value: TimeFormatting.hours(toDateSummary.actualHours),
                        detail: nil
                    )
                    balanceCard(
                        title: tr("Current Balance"),
                        balance: toDateSummary.balance
                    )
                    if Calendar.zurich.component(.year, from: trackingStartDate) < selectedYear {
                        balanceCard(
                            title: tr("All-time Balance"),
                            balance: cumulativeSummary.balance
                        )
                    }
                }

                // Full year info (secondary)
                if selectedYear == Calendar.zurich.component(.year, from: Date()) {
                    HStack(spacing: 16) {
                        Label(tr("Full year target: %@", TimeFormatting.hours(fullYearSummary.expectedHours)),
                              systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Label(tr("Remaining: %@", TimeFormatting.hours(max(0, fullYearSummary.expectedHours - toDateSummary.actualHours))),
                              systemImage: "hourglass")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Info pills — always show full calendar year counts
                HStack(spacing: 8) {
                    infoPill(icon: "flag.fill",
                             text: tr("%lld public holidays", fullCalendarYearSummary.holidayDays),
                             color: .orange)
                        .help(tr("Full days off (0h expected) — e.g. Karfreitag, Weihnachten, Bundesfeier"))

                    infoPill(icon: "flag",
                             text: tr("%lld half-day holidays", fullCalendarYearSummary.halfDayHolidays),
                             color: .orange)
                        .help(tr("Half days off (4h expected) — Sechseläuten, Knabenschiessen, Silvester"))

                    infoPill(icon: "airplane",
                             text: tr("%@/%@ vacation days", TimeFormatting.days(fullCalendarYearSummary.vacationDays), TimeFormatting.days(AppSettings.vacationEntitlement)),
                             color: .blue)
                        .help(tr("Vacation days used this year (Jan–Dec). Half-day holidays count as 0.5 days."))

                    if fullCalendarYearSummary.sickDays > 0 {
                        infoPill(icon: "thermometer.medium",
                                 text: tr("%@ sick days", TimeFormatting.days(fullCalendarYearSummary.sickDays)),
                                 color: .red)
                            .help(tr("Sick days used this year. Treated as full work days — no balance impact."))
                    }
                }

                // Monthly breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text(tr("Monthly Breakdown"))
                        .font(.headline)

                    MonthlyBreakdownView(months: monthlyData)
                }
            }
            .padding(24)
        }
        .navigationTitle(tr("Overview"))
    }

    private func statCard(icon: String, iconColor: Color, title: String, value: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3.bold().monospacedDigit())
            Text(detail ?? " ")
                .font(.caption2)
                .foregroundColor(detail != nil ? .secondary.opacity(0.5) : .clear)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(.primary.opacity(0.04)))
    }

    private func balanceCard(title: String, balance: Double) -> some View {
        let color: Color = balance >= 0 ? .green : .red
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: balance >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundStyle(color)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(balance >= 0 ? "+" : "-")\(TimeFormatting.hours(abs(balance)))")
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(balance >= 0 ? tr("overtime") : tr("undertime"))
                .font(.caption2)
                .foregroundStyle(color.opacity(0.7))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.06)))
    }

    private func infoPill(icon: String, text: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.1)))
    }

    private func snapshotCard(_ title: String, _ summary: PeriodSummary) -> some View {
        let balanceColor: Color = summary.balance >= 0 ? .green : .red
        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(TimeFormatting.hours(summary.actualHours))
                .font(.title3.bold().monospacedDigit())
            HStack(spacing: 4) {
                Image(systemName: summary.balance >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                Text(tr("%@ vs %@",
                        "\(summary.balance >= 0 ? "+" : "-")\(TimeFormatting.hours(abs(summary.balance)))",
                        TimeFormatting.hours(summary.expectedHours)))
                    .font(.caption2)
                    .monospacedDigit()
            }
            .foregroundStyle(balanceColor)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(.primary.opacity(0.04)))
        .accessibilityElement(children: .combine)
    }

    // MARK: - CSV export

    /// Day-by-day report for the selected year (clamped to the tracking window and
    /// today), suitable for handing to payroll/HR.
    private func exportCSV() {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "Europe/Zurich")
        df.dateFormat = "yyyy-MM-dd"

        func hours(_ value: Double) -> String { String(format: "%.2f", value) }

        let header = [tr("Date"), tr("Weekday"), tr("Expected hours"),
                      tr("Worked hours"), tr("Balance hours"), tr("Absence")].joined(separator: ",")
        var rows = [header]
        var totalExpected = 0.0
        var totalWorked = 0.0

        for day in effectiveYearStart.daysThrough(effectiveEnd) {
            let cls = calculator.classify(date: day, absenceLookup: allAbsenceLookup)
            let worked = allSegments
                .filter { $0.date.isSameDay(as: day) }
                .reduce(0.0) { $0 + $1.durationHours }
            totalExpected += cls.expectedHours
            totalWorked += worked

            let absence: String
            if cls.isWeekend { absence = tr("Weekend") }
            else if cls.isVacation { absence = cls.isHalfDayVacation ? tr("Vacation (half)") : tr("Vacation") }
            else if cls.isSick { absence = cls.isHalfDaySick ? tr("Sick (half)") : tr("Sick") }
            else if cls.isHoliday { absence = cls.holidayName ?? tr("Holiday") }
            else { absence = "" }

            let weekday = day.formatted(.dateTime.weekday(.abbreviated))
            rows.append("\(df.string(from: day)),\(weekday),\(hours(cls.expectedHours)),\(hours(worked)),\(hours(worked - cls.expectedHours)),\"\(absence)\"")
        }
        rows.append("\(tr("Total")),,\(hours(totalExpected)),\(hours(totalWorked)),\(hours(totalWorked - totalExpected)),")

        let csv = rows.joined(separator: "\n")
        let panel = NSSavePanel()
        panel.title = tr("Export Time Report")
        panel.nameFieldStringValue = "WorkTracker-\(selectedYear).csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        if panel.runModal() == .OK, let url = panel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }

}
