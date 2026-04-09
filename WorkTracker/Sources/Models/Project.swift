import Foundation
import SwiftData

@Model
final class Project {
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .deny, inverse: \WorkSegment.project)
    var segments: [WorkSegment] = []

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}
