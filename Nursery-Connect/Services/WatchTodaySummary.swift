import Foundation

struct WatchAttendanceAlert: Codable, Equatable {
    var message: String
    var date: Date
    /// "signIn" or "signOut"
    var kind: String
}

/// JSON payload shared between the iOS app and watchOS companion via App Groups.
struct WatchTodaySummary: Codable {
    var updatedAt: Date
    var childrenCount: Int
    /// Children currently signed in and not yet signed out today.
    var studentsInNurseryToday: Int
    var diaryEntriesToday: Int
    var incidentsToday: Int
    var recentIncidents: [WatchRecentIncident]
    var attendanceAlert: WatchAttendanceAlert?
}

struct WatchRecentIncident: Codable, Identifiable {
    var id: UUID
    var childName: String
    var bodyPart: String
    var date: Date
}

enum WatchSummaryStore {
    static let appGroupID = "group.com.ruwanya.Nursery-Connect"
    static let fileName = "todaySummary.json"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    static var fileURL: URL? {
        containerURL?.appendingPathComponent(fileName)
    }

    static func load() -> WatchTodaySummary? {
        guard let fileURL else { return nil }
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(WatchTodaySummary.self, from: data)
    }

    static func save(_ summary: WatchTodaySummary) {
        guard let fileURL else { return }
        guard let data = try? JSONEncoder().encode(summary) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
