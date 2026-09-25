import SwiftUI
import SwiftData

/// How an absence changes the expected hours. Raw values are persisted.
enum AbsenceCountingRule: String, Codable, CaseIterable {
    /// Credits the day's scheduled hours without using vacation allowance.
    case reduceHours = "holiday"
    /// Credits the day's scheduled hours against the annual vacation allowance.
    case vacation
    /// Records the absence without any time credit.
    case unchanged

    var title: String {
        switch self {
        case .reduceHours: return tr("Reduce expected hours")
        case .vacation: return tr("Use vacation allowance")
        case .unchanged: return tr("Leave expected hours unchanged")
        }
    }
}

/// Display and counting information for any absence category, built-in or custom.
struct CategoryDetails: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let color: PaletteColor
    let rule: AbsenceCountingRule
    /// Set for the three built-in categories; nil for custom ones.
    var builtIn: AbsenceType? = nil
}

@Model
final class AbsenceCategory {
    var id: UUID
    var name: String
    var icon: String
    var colorRaw: String
    var ruleRaw: String
    var isArchived: Bool

    init(name: String, icon: String = "calendar.badge.clock", color: PaletteColor = .purple,
         rule: AbsenceCountingRule = .reduceHours) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorRaw = color.rawValue
        self.ruleRaw = rule.rawValue
        self.isArchived = false
    }

    var color: PaletteColor { PaletteColor(rawValue: colorRaw) ?? .purple }
    var rule: AbsenceCountingRule { AbsenceCountingRule(rawValue: ruleRaw) ?? .reduceHours }

    var details: CategoryDetails {
        CategoryDetails(id: id.uuidString, name: name, icon: icon, color: color, rule: rule)
    }
}

extension AbsenceType {
    /// The built-in categories, in display order.
    static let builtIns: [AbsenceType] = [.vacation, .sick, .service]

    var details: CategoryDetails {
        switch self {
        case .vacation:
            return CategoryDetails(id: rawValue, name: tr("Vacation"), icon: "airplane", color: .blue,
                                   rule: .vacation, builtIn: self)
        case .sick:
            return CategoryDetails(id: rawValue, name: tr("Sick"), icon: "cross.case.fill", color: .red,
                                   rule: .reduceHours, builtIn: self)
        case .service:
            return CategoryDetails(id: rawValue, name: tr("Public Service"), icon: "shield.fill", color: .green,
                                   rule: .reduceHours, builtIn: self)
        case .custom:
            // Only reached if a custom entry lost its category; count it like a day off.
            return CategoryDetails(id: rawValue, name: tr("Other absence"), icon: "calendar.badge.clock",
                                   color: .purple, rule: .reduceHours)
        }
    }
}
