import Foundation

struct WatchAttendanceAlert: Codable, Equatable {
    var message: String
    var date: Date
    var kind: String
}

struct WatchTodaySummary: Codable {
    var updatedAt: Date
    var childrenCount: Int
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
    static let fileName = "todaySummary.json"

    static var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }

    static func load() -> WatchTodaySummary? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(WatchTodaySummary.self, from: data)
    }

    static func save(_ summary: WatchTodaySummary) {
        guard let data = try? JSONEncoder().encode(summary) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

