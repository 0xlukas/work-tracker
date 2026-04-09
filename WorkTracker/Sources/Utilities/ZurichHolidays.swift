import Foundation

enum HolidayType {
    case fullDay  // 0 hours required
    case halfDay  // 4 hours required
}

struct Holiday {
    let name: String
    let date: Date
    let type: HolidayType
}

struct ZurichHolidays {
    /// Compute Easter Sunday for a given year using the Anonymous Gregorian algorithm.
    static func easterSunday(year: Int) -> Date {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        return makeDate(year: year, month: month, day: day)
    }

    /// Returns all Zurich public holidays for a given year.
    static func holidays(for year: Int) -> [Holiday] {
        let easter = easterSunday(year: year)
        let cal = Calendar.zurich

        var list: [Holiday] = []

        // Fixed full-day holidays
        list.append(Holiday(name: "Neujahr", date: makeDate(year: year, month: 1, day: 1), type: .fullDay))
        list.append(Holiday(name: "Berchtoldstag", date: makeDate(year: year, month: 1, day: 2), type: .fullDay))
        list.append(Holiday(name: "Tag der Arbeit", date: makeDate(year: year, month: 5, day: 1), type: .fullDay))
        list.append(Holiday(name: "Bundesfeier", date: makeDate(year: year, month: 8, day: 1), type: .fullDay))
        list.append(Holiday(name: "Heiligabend", date: makeDate(year: year, month: 12, day: 24), type: .fullDay))
        list.append(Holiday(name: "Weihnachten", date: makeDate(year: year, month: 12, day: 25), type: .fullDay))
        list.append(Holiday(name: "Stephanstag", date: makeDate(year: year, month: 12, day: 26), type: .fullDay))

        // Easter-based full-day holidays
        list.append(Holiday(name: "Karfreitag", date: cal.date(byAdding: .day, value: -2, to: easter)!, type: .fullDay))
        let easterMonday = cal.date(byAdding: .day, value: 1, to: easter)!
        list.append(Holiday(name: "Ostermontag", date: easterMonday, type: .fullDay))
        list.append(Holiday(name: "Auffahrt", date: cal.date(byAdding: .day, value: 39, to: easter)!, type: .fullDay))
        list.append(Holiday(name: "Pfingstmontag", date: cal.date(byAdding: .day, value: 50, to: easter)!, type: .fullDay))

        // Half-day holidays
        list.append(Holiday(name: "Sechseläuten", date: sechselaeuten(year: year, easterMonday: easterMonday), type: .halfDay))
        list.append(Holiday(name: "Knabenschiessen", date: knabenschiessen(year: year), type: .halfDay))
        list.append(Holiday(name: "Silvester", date: makeDate(year: year, month: 12, day: 31), type: .halfDay))

        return list
    }

    /// Build a lookup dictionary: date -> HolidayType for a given year.
    /// Only includes holidays that fall on weekdays.
    static func holidayLookup(for year: Int) -> [Date: HolidayType] {
        var dict: [Date: HolidayType] = [:]
        for holiday in holidays(for: year) {
            let normalized = holiday.date.startOfDayZurich
            if !normalized.isWeekend {
                dict[normalized] = holiday.type
            }
        }
        return dict
    }

    /// Build a lookup for multiple years.
    static func holidayLookup(years: ClosedRange<Int>) -> [Date: HolidayType] {
        var dict: [Date: HolidayType] = [:]
        for year in years {
            dict.merge(holidayLookup(for: year)) { _, new in new }
        }
        return dict
    }

    // MARK: - Sechseläuten

    /// 3rd Monday of April. If it coincides with Easter Monday, moves to 4th Monday.
    private static func sechselaeuten(year: Int, easterMonday: Date) -> Date {
        let thirdMonday = nthWeekday(nth: 3, weekday: 2, month: 4, year: year) // weekday 2 = Monday
        if Calendar.zurich.isDate(thirdMonday, inSameDayAs: easterMonday) {
            return nthWeekday(nth: 4, weekday: 2, month: 4, year: year)
        }
        return thirdMonday
    }

    // MARK: - Knabenschiessen

    /// Monday after the 2nd Sunday of September.
    private static func knabenschiessen(year: Int) -> Date {
        let secondSunday = nthWeekday(nth: 2, weekday: 1, month: 9, year: year) // weekday 1 = Sunday
        return Calendar.zurich.date(byAdding: .day, value: 1, to: secondSunday)!
    }

    // MARK: - Helpers

    private static func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "Europe/Zurich")
        return Calendar.zurich.date(from: components)!
    }

    /// Returns the nth occurrence of a weekday in a given month/year.
    /// weekday: 1=Sunday, 2=Monday, ..., 7=Saturday
    private static func nthWeekday(nth: Int, weekday: Int, month: Int, year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.weekday = weekday
        components.weekdayOrdinal = nth
        components.timeZone = TimeZone(identifier: "Europe/Zurich")
        return Calendar.zurich.date(from: components)!
    }
}
