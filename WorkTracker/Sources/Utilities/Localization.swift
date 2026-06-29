import Foundation

/// UI language. `.system` follows the macOS language; the others force a language
/// regardless of system settings.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case en
    case de

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .en: return "English"
        case .de: return "Deutsch"
        }
    }
}

/// Tiny localization layer. Strings live in `en.lproj`/`de.lproj` Localizable.strings
/// inside the package's resource bundle (`Bundle.module`). The English source text is
/// used as the lookup key, so a missing translation gracefully falls back to English.
enum Localization {
    static let storageKey = "appLanguage"

    static var current: AppLanguage {
        get { AppLanguage(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .system }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: storageKey) }
    }

    /// Strings ship in the packaged app under `Contents/Resources/<lang>.lproj`
    /// (`Bundle.main`); when running from `swift run`/tests they live in the SwiftPM
    /// resource bundle (`Bundle.module`). Prefer whichever actually has them.
    private static var baseBundle: Bundle {
        Bundle.main.path(forResource: "de", ofType: "lproj") != nil ? .main : .module
    }

    private static func resolvedBundle() -> Bundle {
        switch current {
        case .system:
            return baseBundle
        case .en:
            return lprojBundle("en")
        case .de:
            return lprojBundle("de")
        }
    }

    private static func lprojBundle(_ code: String) -> Bundle {
        let base = baseBundle
        if let path = base.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return base
    }

    static func string(_ key: String) -> String {
        resolvedBundle().localizedString(forKey: key, value: key, table: nil)
    }
}

/// Localize a UI string. The key is the English source text.
func tr(_ key: String) -> String {
    Localization.string(key)
}

/// Localize a format string and substitute arguments (e.g. `tr("of %@ expected", h)`).
func tr(_ key: String, _ args: CVarArg...) -> String {
    String(format: Localization.string(key), arguments: args)
}
