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
}
