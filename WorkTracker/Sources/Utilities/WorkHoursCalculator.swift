import Foundation

struct DaySummary {
    let date: Date
    let expectedHours: Double
    let isHoliday: Bool
    let holidayName: String?
    let isHalfDayHoliday: Bool
    let isVacation: Bool
    let isHalfDayVacation: Bool  // manual half-day vacation
    let isWeekend: Bool
}

struct PeriodSummary {
    let expectedHours: Double
    let actualHours: Double
    var balance: Double { actualHours - expectedHours }
    let workingDays: Int
    let holidayDays: Int
    let halfDayHolidays: Int
    let vacationDays: Double
}

struct MonthSummary: Identifiable {
    let year: Int
    let month: Int
    let expectedHours: Double
    let actualHours: Double
    var balance: Double { actualHours - expectedHours }

    var id: String { "\(year)-\(month)" }

    var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_CH")
        return formatter.monthSymbols[month - 1].capitalized
    }
}

struct ProjectHours: Identifiable {
    let project: Project
    let hours: Double
    var id: String { project.name }
}

struct WorkHoursCalculator {
    private let holidayLookup: [Date: HolidayType]
    private let holidayNameLookup: [Date: String]

    init(years: ClosedRange<Int> = 2026...2036) {
        self.holidayLookup = ZurichHolidays.holidayLookup(years: years)

        var names: [Date: String] = [:]
        for year in years {
            for h in ZurichHolidays.holidays(for: year) {
                let normalized = h.date.startOfDayZurich
                if !normalized.isWeekend {
                    names[normalized] = h.name
                }
            }
        }
        self.holidayNameLookup = names
    }

    /// vacationLookup: date → isHalfDay (true = half-day vacation, false = full-day vacation)
    func classify(date: Date, vacationLookup: [Date: Bool]) -> DaySummary {
        let normalized = date.startOfDayZurich

        if normalized.isWeekend {
            return DaySummary(date: normalized, expectedHours: 0, isHoliday: false,
                            holidayName: nil, isHalfDayHoliday: false, isVacation: false,
                            isHalfDayVacation: false, isWeekend: true)
        }

        let vacationEntry = vacationLookup[normalized]  // nil = no vacation, false = full, true = half
        let isVacation = vacationEntry != nil
        let isHalfDayVacation = vacationEntry == true
        let holidayType = holidayLookup[normalized]
        let holidayName = holidayNameLookup[normalized]

        // Full-day holiday: always 0h, vacation irrelevant
        if holidayType == .fullDay {
            return DaySummary(date: normalized, expectedHours: 0, isHoliday: true,
                            holidayName: holidayName, isHalfDayHoliday: false, isVacation: false,
                            isHalfDayVacation: false, isWeekend: false)
        }

        // Vacation on a half-day holiday
        if isVacation && holidayType == .halfDay {
            return DaySummary(date: normalized, expectedHours: 0, isHoliday: true,
                            holidayName: holidayName, isHalfDayHoliday: true, isVacation: true,
                            isHalfDayVacation: isHalfDayVacation, isWeekend: false)
        }

        // Half-day vacation on a regular day: 4h expected (work half, vacation half)
        if isHalfDayVacation {
            return DaySummary(date: normalized, expectedHours: 4, isHoliday: false,
                            holidayName: nil, isHalfDayHoliday: false, isVacation: true,
                            isHalfDayVacation: true, isWeekend: false)
        }

        // Full-day vacation on a regular day: 0h expected
        if isVacation {
            return DaySummary(date: normalized, expectedHours: 0, isHoliday: false,
                            holidayName: nil, isHalfDayHoliday: false, isVacation: true,
                            isHalfDayVacation: false, isWeekend: false)
        }

        // Half-day holiday without vacation: 4h expected
        if holidayType == .halfDay {
            return DaySummary(date: normalized, expectedHours: 4, isHoliday: true,
                            holidayName: holidayName, isHalfDayHoliday: true, isVacation: false,
                            isHalfDayVacation: false, isWeekend: false)
        }

        return DaySummary(date: normalized, expectedHours: 8, isHoliday: false,
                        holidayName: nil, isHalfDayHoliday: false, isVacation: false,
                        isHalfDayVacation: false, isWeekend: false)
    }

    func periodSummary(from: Date, to: Date, vacationLookup: [Date: Bool], segments: [WorkSegment]) -> PeriodSummary {
        let days = from.startOfDayZurich.daysThrough(to.startOfDayZurich)

        var expectedHours: Double = 0
        var workingDays = 0
        var holidayDays = 0
        var halfDayHolidays = 0
        var vacationDayCount: Double = 0

        for day in days {
            let summary = classify(date: day, vacationLookup: vacationLookup)
            expectedHours += summary.expectedHours

            if summary.isWeekend { continue }

            // Vacation on a half-day holiday: counts as 0.5 vacation + 1 half-day holiday
            if summary.isVacation && summary.isHalfDayHoliday {
                vacationDayCount += 0.5
                halfDayHolidays += 1
                continue
            }

            // Half-day vacation on regular day: counts as 0.5
            if summary.isVacation && summary.isHalfDayVacation {
                vacationDayCount += 0.5
                workingDays += 1  // still a partial working day
                continue
            }

            if summary.isVacation { vacationDayCount += 1; continue }
            if summary.isHoliday && !summary.isHalfDayHoliday { holidayDays += 1; continue }
            if summary.isHalfDayHoliday { halfDayHolidays += 1 }
            workingDays += 1
        }

        // Extra vacation beyond 25 days adds to expected hours (unpaid leave penalty)
        if vacationDayCount > 25 {
            let extraDays = vacationDayCount - 25
            expectedHours += extraDays * 8
        }

        let actualHours = segments
            .filter { seg in
                let d = seg.date.startOfDayZurich
                return d >= from.startOfDayZurich && d <= to.startOfDayZurich
            }
            .reduce(0.0) { $0 + $1.durationHours }

        return PeriodSummary(
            expectedHours: expectedHours,
            actualHours: actualHours,
            workingDays: workingDays,
            holidayDays: holidayDays,
            halfDayHolidays: halfDayHolidays,
            vacationDays: vacationDayCount
        )
    }

    /// Monthly breakdown clamped to [startDate, endDate].
    /// Months entirely outside the range get 0/0. Partial months are clipped.
    func monthlyBreakdown(year: Int, vacationLookup: [Date: Bool], segments: [WorkSegment],
                          startDate: Date? = nil, endDate: Date? = nil) -> [MonthSummary] {
        let cal = Calendar.zurich
        let tz = TimeZone(identifier: "Europe/Zurich")!
        let clampStart = startDate?.startOfDayZurich
        let clampEnd = endDate?.startOfDayZurich

        return (1...12).map { month in
            var monthStart = cal.date(from: DateComponents(timeZone: tz, year: year, month: month, day: 1))!
            let endDay = cal.range(of: .day, in: .month, for: monthStart)!.upperBound - 1
            var monthEnd = cal.date(from: DateComponents(timeZone: tz, year: year, month: month, day: endDay))!

            // Clamp to tracking window
            if let s = clampStart { monthStart = max(monthStart, s) }
            if let e = clampEnd { monthEnd = min(monthEnd, e) }

            guard monthStart <= monthEnd else {
                return MonthSummary(year: year, month: month, expectedHours: 0, actualHours: 0)
            }

            let summary = periodSummary(from: monthStart, to: monthEnd,
                                        vacationLookup: vacationLookup, segments: segments)
            return MonthSummary(year: year, month: month,
                               expectedHours: summary.expectedHours, actualHours: summary.actualHours)
        }
    }

    func projectBreakdown(from: Date, to: Date, segments: [WorkSegment]) -> [ProjectHours] {
        let filtered = segments.filter { seg in
            let d = seg.date.startOfDayZurich
            return d >= from.startOfDayZurich && d <= to.startOfDayZurich
        }

        var projectMap: [String: (project: Project, hours: Double)] = [:]
        for seg in filtered {
            guard let project = seg.project else { continue }
            let key = project.name
            if var entry = projectMap[key] {
                entry.hours += seg.durationHours
                projectMap[key] = entry
            } else {
                projectMap[key] = (project: project, hours: seg.durationHours)
            }
        }

        return projectMap.values
            .map { ProjectHours(project: $0.project, hours: $0.hours) }
            .sorted { $0.hours > $1.hours }
    }
}
