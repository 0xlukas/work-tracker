import Foundation
import SwiftData

@Model
final class WorkSegment {
    var date: Date
    var startTime: Date
    var endTime: Date
    var durationHours: Double
    var project: Project?

    init(date: Date, startTime: Date, endTime: Date, project: Project) {
        self.date = Calendar.zurich.startOfDay(for: date)
        self.startTime = startTime
        self.endTime = endTime
        self.durationHours = endTime.timeIntervalSince(startTime) / 3600.0
        self.project = project
    }

    func recalculateDuration() {
        durationHours = endTime.timeIntervalSince(startTime) / 3600.0
    }
}
