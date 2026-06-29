import Foundation

struct AppSettings {
    private static let trackingStartDateKey = "trackingStartDate"
    private static let customDataDirectoryKey = "customDataDirectory"

    static var trackingStartDate: Date {
        get {
            if let date = UserDefaults.standard.object(forKey: trackingStartDateKey) as? Date {
                return Calendar.zurich.startOfDay(for: date)
            }
            return Calendar.zurich.startOfDay(for: Date())
        }
        set {
            UserDefaults.standard.set(Calendar.zurich.startOfDay(for: newValue), forKey: trackingStartDateKey)
        }
    }

    static var isTrackingStartDateSet: Bool {
        UserDefaults.standard.object(forKey: trackingStartDateKey) != nil
    }

    // MARK: - Vacation entitlement

    private static let vacationEntitlementKey = "vacationEntitlementDays"

    /// Annual paid-vacation entitlement in days. Defaults to 25.
    static var vacationEntitlement: Double {
        get { (UserDefaults.standard.object(forKey: vacationEntitlementKey) as? Double) ?? 25 }
        set { UserDefaults.standard.set(newValue, forKey: vacationEntitlementKey) }
    }

    // MARK: - Daily Quote

    private static let lastQuoteShownDateKey = "lastQuoteShownDate"
    private static let dailyQuoteEnabledKey = "dailyQuoteEnabled"

    /// Whether the once-a-day quote overlay appears on launch. Defaults to on.
    static var dailyQuoteEnabled: Bool {
        get { (UserDefaults.standard.object(forKey: dailyQuoteEnabledKey) as? Bool) ?? true }
        set { UserDefaults.standard.set(newValue, forKey: dailyQuoteEnabledKey) }
    }

    static var lastQuoteShownDate: Date? {
        get { UserDefaults.standard.object(forKey: lastQuoteShownDateKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastQuoteShownDateKey) }
    }

    static var shouldShowDailyQuote: Bool {
        guard dailyQuoteEnabled else { return false }
        guard let lastShown = lastQuoteShownDate else { return true }
        return !Calendar.zurich.isDateInToday(lastShown)
    }

    /// Custom directory for SwiftData storage. nil = default (Application Support).
    static var customDataDirectory: URL? {
        get {
            guard let path = UserDefaults.standard.string(forKey: customDataDirectoryKey) else { return nil }
            return URL(fileURLWithPath: path)
        }
        set {
            if let url = newValue {
                UserDefaults.standard.set(url.path, forKey: customDataDirectoryKey)
            } else {
                UserDefaults.standard.removeObject(forKey: customDataDirectoryKey)
            }
        }
    }

    /// The URL for the SwiftData store file.
    static var dataStoreURL: URL {
        let dir: URL
        if let custom = customDataDirectory {
            dir = custom
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            dir = appSupport.appendingPathComponent("WorkTracker", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("WorkTracker.store")
    }

    /// Copy the existing store file (and its `-wal`/`-shm` siblings) from the current
    /// location into `newDirectory`, so switching folders keeps the user's data.
    /// Won't overwrite a store that already exists in the destination. Returns true on
    /// success (or when there's nothing to move); false if any copy failed.
    static func migrateStore(to newDirectory: URL) -> Bool {
        let fm = FileManager.default
        let currentStore = dataStoreURL
        let currentDir = currentStore.deletingLastPathComponent()
        guard currentDir.standardizedFileURL != newDirectory.standardizedFileURL else { return true }

        do {
            try fm.createDirectory(at: newDirectory, withIntermediateDirectories: true)
        } catch {
            return false
        }

        let baseName = currentStore.lastPathComponent
        var allCopied = true
        for suffix in ["", "-wal", "-shm"] {
            let src = currentDir.appendingPathComponent(baseName + suffix)
            let dst = newDirectory.appendingPathComponent(baseName + suffix)
            guard fm.fileExists(atPath: src.path), !fm.fileExists(atPath: dst.path) else { continue }
            do {
                try fm.copyItem(at: src, to: dst)
            } catch {
                allCopied = false
            }
        }
        return allCopied
    }
}
