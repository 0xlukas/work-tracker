import Foundation

struct AbsenceEntry {
    let type: AbsenceType
    let isHalfDay: Bool
}

struct DaySummary {
    let date: Date
    let expectedHours: Double
    let isHoliday: Bool
    let holidayName: String?
    let isHalfDayHoliday: Bool
    let isVacation: Bool
    let isHalfDayVacation: Bool  // manual half-day vacation
    let isSick: Bool
    let isHalfDaySick: Bool
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
    let sickDays: Double
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
        formatter.locale = Locale.current
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

    func classify(date: Date, absenceLookup: [Date: AbsenceEntry]) -> DaySummary {
        let normalized = date.startOfDayZurich

        if normalized.isWeekend {
            return DaySummary(date: normalized, expectedHours: 0, isHoliday: false,
                            holidayName: nil, isHalfDayHoliday: false, isVacation: false,
                            isHalfDayVacation: false, isSick: false, isHalfDaySick: false,
                            isWeekend: true)
        }

        let absence = absenceLookup[normalized]
        let holidayType = holidayLookup[normalized]
        let holidayName = holidayNameLookup[normalized]

        // Full-day holiday: always 0h, absence irrelevant
        if holidayType == .fullDay {
            return DaySummary(date: normalized, expectedHours: 0, isHoliday: true,
                            holidayName: holidayName, isHalfDayHoliday: false, isVacation: false,
                            isHalfDayVacation: false, isSick: false, isHalfDaySick: false,
                            isWeekend: false)
        }

        // Sick day on a half-day holiday: sick replaces the working half (0h expected)
        if absence?.type == .sick && holidayType == .halfDay {
            return DaySummary(date: normalized, expectedHours: 0, isHoliday: true,
                            holidayName: holidayName, isHalfDayHoliday: true, isVacation: false,
                            isHalfDayVacation: false, isSick: true,
                            isHalfDaySick: absence?.isHalfDay == true,
                            isWeekend: false)
        }

        // Half-day sick on a regular day: 4h expected (work half, sick half)
        if absence?.type == .sick && absence?.isHalfDay == true {
            return DaySummary(date: normalized, expectedHours: 4, isHoliday: false,
                            holidayName: nil, isHalfDayHoliday: false, isVacation: false,
                            isHalfDayVacation: false, isSick: true, isHalfDaySick: true,
                            isWeekend: false)
        }

        // Full-day sick on a regular day: 0h expected
        if absence?.type == .sick {
            return DaySummary(date: normalized, expectedHours: 0, isHoliday: false,
                            holidayName: nil, isHalfDayHoliday: false, isVacation: false,
                            isHalfDayVacation: false, isSick: true, isHalfDaySick: false,
                            isWeekend: false)
        }

        let isVacation = absence?.type == .vacation
        let isHalfDayVacation = isVacation && absence?.isHalfDay == true

        // Vacation on a half-day holiday
        if isVacation && holidayType == .halfDay {
            return DaySummary(date: normalized, expectedHours: 0, isHoliday: true,
                            holidayName: holidayName, isHalfDayHoliday: true, isVacation: true,
                            isHalfDayVacation: isHalfDayVacation, isSick: false, isHalfDaySick: false,
                            isWeekend: false)
        }

        // Half-day vacation on a regular day: 4h expected (work half, vacation half)
        if isHalfDayVacation {
            return DaySummary(date: normalized, expectedHours: 4, isHoliday: false,
                            holidayName: nil, isHalfDayHoliday: false, isVacation: true,
                            isHalfDayVacation: true, isSick: false, isHalfDaySick: false,
                            isWeekend: false)
        }

        // Full-day vacation on a regular day: 0h expected
        if isVacation {
            return DaySummary(date: normalized, expectedHours: 0, isHoliday: false,
                            holidayName: nil, isHalfDayHoliday: false, isVacation: true,
                            isHalfDayVacation: false, isSick: false, isHalfDaySick: false,
                            isWeekend: false)
        }

        // Half-day holiday without absence: 4h expected
        if holidayType == .halfDay {
            return DaySummary(date: normalized, expectedHours: 4, isHoliday: true,
                            holidayName: holidayName, isHalfDayHoliday: true, isVacation: false,
                            isHalfDayVacation: false, isSick: false, isHalfDaySick: false,
                            isWeekend: false)
        }

        return DaySummary(date: normalized, expectedHours: 8, isHoliday: false,
                        holidayName: nil, isHalfDayHoliday: false, isVacation: false,
                        isHalfDayVacation: false, isSick: false, isHalfDaySick: false,
                        isWeekend: false)
    }

    func periodSummary(from: Date, to: Date, absenceLookup: [Date: AbsenceEntry], segments: [WorkSegment]) -> PeriodSummary {
        let days = from.startOfDayZurich.daysThrough(to.startOfDayZurich)

        var expectedHours: Double = 0
        var workingDays = 0
        var holidayDays = 0
        var halfDayHolidays = 0
        var vacationDayCount: Double = 0
        var sickDayCount: Double = 0

        for day in days {
            let summary = classify(date: day, absenceLookup: absenceLookup)
            expectedHours += summary.expectedHours

            if summary.isWeekend { continue }

            // Sick on a half-day holiday: counts as 1 sick + 1 half-day holiday
            if summary.isSick && summary.isHalfDayHoliday {
                sickDayCount += 1
                halfDayHolidays += 1
                continue
            }

            // Half-day sick on regular day: 0.5 sick + still a partial working day
            if summary.isSick && summary.isHalfDaySick {
                sickDayCount += 0.5
                workingDays += 1
                continue
            }

            // Full-day sick on regular day
            if summary.isSick {
                sickDayCount += 1
                continue
            }

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
            vacationDays: vacationDayCount,
            sickDays: sickDayCount
        )
    }

    /// Monthly breakdown clamped to [startDate, endDate].
    /// Months entirely outside the range get 0/0. Partial months are clipped.
    func monthlyBreakdown(year: Int, absenceLookup: [Date: AbsenceEntry], segments: [WorkSegment],
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
                                        absenceLookup: absenceLookup, segments: segments)
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
