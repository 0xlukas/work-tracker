import Foundation
import SwiftData

@Model
final class VacationDay {
    var date: Date
    var isHalfDay: Bool

    init(date: Date, isHalfDay: Bool = false) {
        self.date = Calendar.zurich.startOfDay(for: date)
        self.isHalfDay = isHalfDay
    }
}
