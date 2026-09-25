import Foundation
import SwiftData

/// The Absences grid's editing rules, independent of the view.
@MainActor
struct AbsenceEditor {
    let context: ModelContext
    /// Existing absences by Zurich day.
    let existing: [Date: VacationDay]

    init(context: ModelContext, absences: [VacationDay]) {
        self.context = context
        self.existing = Dictionary(absences.map { ($0.date.startOfDayZurich, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Click cycle: none → full day → half day → none. Clicking an absence of another
    /// category converts it to a full day of the selected one.
    func click(_ date: Date, selection: AbsenceSelection) {
        let day = date.startOfDayZurich
        guard let absence = existing[day] else {
            insert(on: day, selection: selection)
            return
        }
        if absence.selectionID != selection.id {
            absence.assign(selection)
            absence.isHalfDay = false
        } else if !absence.isHalfDay {
            absence.isHalfDay = true
        } else {
            context.delete(absence)
        }
    }

    /// Shift-click range: every day becomes the selected category. Days that already
    /// have it keep their full/half state.
    func fill(_ days: [Date], selection: AbsenceSelection) {
        for day in days.map(\.startOfDayZurich) {
            if let absence = existing[day] {
                if absence.selectionID != selection.id {
                    absence.assign(selection)
                    absence.isHalfDay = false
                }
            } else {
                insert(on: day, selection: selection)
            }
        }
    }

    private func insert(on day: Date, selection: AbsenceSelection) {
        let absence = VacationDay(date: day)
        absence.assign(selection)
        context.insert(absence)
    }
}

/// Queries and bulk actions for time entries.
@MainActor
enum EntryActions {
    static func segments(on day: Date, in context: ModelContext) -> [WorkSegment] {
        let start = day.startOfDayZurich, end = start.addingDays(1)
        let descriptor = FetchDescriptor<WorkSegment>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.startTime)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// The most recent day before `day` that has entries.
    static func previousDayWithEntries(before day: Date, in context: ModelContext) -> Date? {
        let start = day.startOfDayZurich
        var descriptor = FetchDescriptor<WorkSegment>(
            predicate: #Predicate { $0.date < start },
            sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first?.date.startOfDayZurich
    }

    /// The project of the most recently logged entry that isn't archived.
    static func lastUsedProject(in context: ModelContext) -> Project? {
        var descriptor = FetchDescriptor<WorkSegment>(sortBy: [SortDescriptor(\.startTime, order: .reverse)])
        descriptor.fetchLimit = 20
        return (try? context.fetch(descriptor))?.lazy.compactMap(\.project).first { !$0.isArchived }
    }

    /// Copy every entry from `source` to `target` at the same times. Entries that would
    /// overlap something already on `target` are skipped. Returns (copied, skipped).
    @discardableResult
    static func copyEntries(from source: Date, to target: Date, in context: ModelContext) -> (copied: Int, skipped: Int) {
        let existing = segments(on: target, in: context)
        var copied = 0, skipped = 0
        var busy = existing.map { (start: $0.startTime, end: $0.endTime) }
        for segment in segments(on: source, in: context) {
            guard let project = segment.project else { skipped += 1; continue }
            let start = moved(segment.startTime, from: segment.date, to: target)
            let end = moved(segment.endTime, from: segment.date, to: target)
            if busy.contains(where: { start < $0.end && end > $0.start }) {
                skipped += 1
                continue
            }
            context.insert(WorkSegment(date: target, startTime: start, endTime: end, project: project, note: segment.note))
            busy.append((start, end))
            copied += 1
        }
        return (copied, skipped)
    }

    /// Same wall-clock offset from midnight on another day (24:00 stays 24:00).
    static func moved(_ time: Date, from day: Date, to target: Date) -> Date {
        let offset = Calendar.zurich.dateComponents([.minute], from: day.startOfDayZurich, to: time).minute ?? 0
        return Calendar.zurich.date(byAdding: .minute, value: offset, to: target.startOfDayZurich)!
    }
}
