import Foundation

extension Calendar {
    static let zurich: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Zurich")!
        return cal
    }()
}

extension Date {
    var startOfDayZurich: Date {
        Calendar.zurich.startOfDay(for: self)
    }

    var isWeekend: Bool {
        let weekday = Calendar.zurich.component(.weekday, from: self)
        return weekday == 1 || weekday == 7 // Sunday = 1, Saturday = 7
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.zurich.isDate(self, inSameDayAs: other)
    }

    /// Returns all dates from self to end (inclusive), stepping by 1 day.
    func daysThrough(_ end: Date) -> [Date] {
        var dates: [Date] = []
        var current = self.startOfDayZurich
        let endNormalized = end.startOfDayZurich
        while current <= endNormalized {
            dates.append(current)
            current = Calendar.zurich.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }
}
