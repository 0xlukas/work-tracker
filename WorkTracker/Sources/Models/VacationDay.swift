import Foundation
import SwiftData

@Model
final class VacationDay {
    var date: Date
    var isHalfDay: Bool
    /// Stored optional so SwiftData's lightweight migration of pre-existing
    /// rows (which have no value for this column) is safe. Use `resolvedType`
    /// for reads — it treats nil as `.vacation` for legacy data.
    var type: AbsenceType?

    var resolvedType: AbsenceType { type ?? .vacation }

    init(date: Date, isHalfDay: Bool = false, type: AbsenceType = .vacation) {
        self.date = Calendar.zurich.startOfDay(for: date)
        self.isHalfDay = isHalfDay
        self.type = type
    }
}
