import Foundation
import SwiftData

enum AbsenceType: String, Codable, CaseIterable {
    case vacation
    case sick
}

enum WorkTrackerSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Project.self, WorkSegment.self, VacationDay.self]
    }

    @Model
    final class VacationDay {
        var date: Date
        var isHalfDay: Bool

        init(date: Date, isHalfDay: Bool = false) {
            self.date = Calendar.zurich.startOfDay(for: date)
            self.isHalfDay = isHalfDay
        }
    }
}

enum WorkTrackerSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Project.self, WorkSegment.self, VacationDay.self]
    }
}

enum WorkTrackerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [WorkTrackerSchemaV1.self, WorkTrackerSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: WorkTrackerSchemaV1.self,
                      toVersion: WorkTrackerSchemaV2.self)]
    }
}
