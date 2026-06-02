import Foundation

struct MoodCount: Identifiable {
    let mood: String
    let count: Int

    var id: String { mood }
}

struct NapDataPoint: Identifiable {
    let date: Date
    let minutes: Int

    var id: Date { date }
}

struct BodyPartCount: Identifiable {
    let bodyPart: String
    let count: Int

    var id: String { bodyPart }
}

struct WeeklyAttendancePoint: Identifiable {
    let dayLabel: String
    let date: Date
    let presentCount: Int

    var id: Date { date }
}

struct ChildAttendanceFrequency: Identifiable {
    let childName: String
    let daysPresent: Int

    var id: String { childName }
}

struct AnalyticsViewModel {
    let diaryLogs: [DiaryLog]
    let incidents: [Incident]
    let attendanceRecords: [AttendanceRecord]
    let childFilter: String?

    init(
        diaryLogs: [DiaryLog],
        incidents: [Incident],
        attendanceRecords: [AttendanceRecord] = [],
        childFilter: String? = nil
    ) {
        self.diaryLogs = diaryLogs
        self.incidents = incidents
        self.attendanceRecords = attendanceRecords
        self.childFilter = childFilter
    }

    var hasDiaryData: Bool {
        !filteredDiaryLogs.isEmpty
    }

    var hasAttendanceData: Bool {
        !filteredAttendance.isEmpty
    }

    var moodCounts: [MoodCount] {
        let recentLogs = filteredDiaryLogs.filter { isInLast14Days($0.date) }
        let grouped = Dictionary(grouping: recentLogs, by: \.mood)
        return grouped
            .map { MoodCount(mood: $0.key, count: $0.value.count) }
            .sorted { $0.mood < $1.mood }
    }

    var napTrend: [NapDataPoint] {
        filteredDiaryLogs
            .filter { isInLast14Days($0.date) }
            .sorted { $0.date < $1.date }
            .map { NapDataPoint(date: $0.date, minutes: $0.napDurationMinutes) }
    }

    var bodyPartCounts: [BodyPartCount] {
        let grouped = Dictionary(grouping: filteredIncidents, by: \.bodyPart)
        return grouped
            .map { BodyPartCount(bodyPart: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    /// Children present per weekday for the last 7 calendar days.
    var weeklyAttendance: [WeeklyAttendancePoint] {
        let calendar = Calendar.current
        var points: [WeeklyAttendancePoint] = []

        for dayOffset in -6...0 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            let dayRecords = filteredAttendance.filter {
                calendar.isDate($0.date, inSameDayAs: day)
            }

            let count: Int
            if let childFilter {
                count = dayRecords.contains { $0.childName == childFilter && $0.isPresent } ? 1 : 0
            } else {
                let presentNames = Set(
                    dayRecords.filter(\.isPresent).map(\.childName)
                )
                count = presentNames.count
            }

            points.append(
                WeeklyAttendancePoint(
                    dayLabel: day.formatted(.dateTime.weekday(.abbreviated)),
                    date: day,
                    presentCount: count
                )
            )
        }

        return points
    }

    /// Days present in the last 14 days per child (nursery-wide view only).
    var childAttendanceFrequency: [ChildAttendanceFrequency] {
        guard childFilter == nil else { return [] }

        let presentRecords = filteredAttendance.filter { isInLast14Days($0.date) && $0.isPresent }
        let grouped = Dictionary(grouping: presentRecords, by: \.childName)

        return grouped
            .map { name, records in
                let uniqueDays = Set(
                    records.map { calendar in Calendar.current.startOfDay(for: calendar.date) }
                )
                return ChildAttendanceFrequency(childName: name, daysPresent: uniqueDays.count)
            }
            .sorted { $0.daysPresent > $1.daysPresent }
    }

    private var filteredDiaryLogs: [DiaryLog] {
        guard let childFilter else { return diaryLogs }
        return diaryLogs.filter { $0.childName == childFilter }
    }

    private var filteredIncidents: [Incident] {
        guard let childFilter else { return incidents }
        return incidents.filter { $0.childName == childFilter }
    }

    private var filteredAttendance: [AttendanceRecord] {
        guard let childFilter else { return attendanceRecords }
        return attendanceRecords.filter { $0.childName == childFilter }
    }

    private func isInLast14Days(_ date: Date) -> Bool {
        let calendar = Calendar.current
        guard let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: Date()) else { return false }
        let startOfFourteenDaysAgo = calendar.startOfDay(for: fourteenDaysAgo)
        return date >= startOfFourteenDaysAgo && date <= Date()
    }
}
