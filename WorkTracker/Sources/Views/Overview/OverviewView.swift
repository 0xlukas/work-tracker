import SwiftUI
import SwiftData

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

    private var vacationLookupForYear: [Date: Bool] {
        var lookup: [Date: Bool] = [:]
        for vd in allVacationDays where Calendar.zurich.component(.year, from: vd.date) == selectedYear {
            lookup[vd.date.startOfDayZurich] = vd.isHalfDay
        }
        return lookup
    }

    private var allVacationLookup: [Date: Bool] {
        var lookup: [Date: Bool] = [:]
        for vd in allVacationDays {
            lookup[vd.date.startOfDayZurich] = vd.isHalfDay
        }
        return lookup
    }

    /// Full calendar year summary (Jan 1 - Dec 31) for pills
    private var fullCalendarYearSummary: PeriodSummary {
        let yearStart = Calendar.zurich.date(from: DateComponents(
            timeZone: TimeZone(identifier: "Europe/Zurich"),
            year: selectedYear, month: 1, day: 1))!
        return calculator.periodSummary(from: yearStart, to: yearEnd,
                                        vacationLookup: vacationLookupForYear, segments: allSegments)
    }

    // Balance up to today for the selected year
    private var toDateSummary: PeriodSummary {
        guard effectiveYearStart <= effectiveEnd else {
            return PeriodSummary(expectedHours: 0, actualHours: 0,
                                workingDays: 0, holidayDays: 0, halfDayHolidays: 0, vacationDays: 0)
        }
        return calculator.periodSummary(from: effectiveYearStart, to: effectiveEnd,
                                        vacationLookup: vacationLookupForYear, segments: allSegments)
    }

    // Full year projection
    private var fullYearSummary: PeriodSummary {
        guard effectiveYearStart <= yearEnd else {
            return PeriodSummary(expectedHours: 0, actualHours: 0,
                                workingDays: 0, holidayDays: 0, halfDayHolidays: 0, vacationDays: 0)
        }
        return calculator.periodSummary(from: effectiveYearStart, to: yearEnd,
                                        vacationLookup: vacationLookupForYear, segments: allSegments)
    }

    // Cumulative from tracking start through today
    private var cumulativeSummary: PeriodSummary {
        guard trackingStartDate <= today else {
            return PeriodSummary(expectedHours: 0, actualHours: 0,
                                workingDays: 0, holidayDays: 0, halfDayHolidays: 0, vacationDays: 0)
        }
        return calculator.periodSummary(from: trackingStartDate, to: today,
                                        vacationLookup: allVacationLookup, segments: allSegments)
    }

    private var monthlyData: [MonthSummary] {
        calculator.monthlyBreakdown(year: selectedYear,
                                    vacationLookup: vacationLookupForYear,
                                    segments: allSegments,
                                    startDate: trackingStartDate,
                                    endDate: today)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Overview")
                            .font(.title.bold())
                        HStack(spacing: 4) {
                            Text("Year")
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
                }

                // Tracking start date
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(.blue)
                        .font(.caption)
                    Text("Tracking since")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if showStartDatePicker {
                        DatePicker("", selection: $trackingStartDate, displayedComponents: .date)
                            .labelsHidden()
                            .onChange(of: trackingStartDate) { _, newValue in
                                AppSettings.trackingStartDate = newValue
                            }
                        Button("Done") {
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
                        title: "Expected (to date)",
                        value: formatHours(toDateSummary.expectedHours),
                        detail: "\(toDateSummary.workingDays) working days"
                    )
                    statCard(
                        icon: "checkmark.circle",
                        iconColor: .green,
                        title: "Worked (to date)",
                        value: formatHours(toDateSummary.actualHours),
                        detail: nil
                    )
                    balanceCard(
                        title: "Current Balance",
                        balance: toDateSummary.balance
                    )
                    if Calendar.zurich.component(.year, from: trackingStartDate) < selectedYear {
                        balanceCard(
                            title: "All-time Balance",
                            balance: cumulativeSummary.balance
                        )
                    }
                }

                // Full year info (secondary)
                if selectedYear == Calendar.zurich.component(.year, from: Date()) {
                    HStack(spacing: 16) {
                        Label("Full year target: \(formatHours(fullYearSummary.expectedHours))",
                              systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Label("Remaining: \(formatHours(max(0, fullYearSummary.expectedHours - toDateSummary.actualHours)))",
                              systemImage: "hourglass")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Info pills — always show full calendar year counts
                HStack(spacing: 8) {
                    infoPill(icon: "flag.fill",
                             text: "\(fullCalendarYearSummary.holidayDays) public holidays",
                             color: .orange)
                        .help("Full days off (0h expected) — e.g. Karfreitag, Weihnachten, Bundesfeier")

                    infoPill(icon: "flag",
                             text: "\(fullCalendarYearSummary.halfDayHolidays) half-day holidays",
                             color: .orange)
                        .help("Half days off (4h expected) — Sechseläuten, Knabenschiessen, Silvester")

                    infoPill(icon: "airplane",
                             text: "\(formatVacationDays(fullCalendarYearSummary.vacationDays))/25 vacation days",
                             color: .blue)
                        .help("Vacation days used this year (Jan–Dec). Half-day holidays count as 0.5 days.")
                }

                // Monthly breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Monthly Breakdown")
                        .font(.headline)

                    MonthlyBreakdownView(months: monthlyData)
                }
            }
            .padding(24)
        }
        .navigationTitle("Overview")
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
            Text("\(balance >= 0 ? "+" : "-")\(formatHours(abs(balance)))")
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(balance >= 0 ? "overtime" : "undertime")
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

    private func formatVacationDays(_ days: Double) -> String {
        if days == days.rounded() {
            return "\(Int(days))"
        }
        return String(format: "%.1f", days)
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int(((hours - Double(h)) * 60).rounded())
        return String(format: "%dh %02dm", h, m)
    }
}
