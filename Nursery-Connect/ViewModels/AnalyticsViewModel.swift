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
        !weekAttendanceRecords.isEmpty
    }

    var moodCounts: [MoodCount] {
        let weekLogs = filteredDiaryLogs.filter { isInCurrentWeek($0.date) }
        let grouped = Dictionary(grouping: weekLogs, by: \.mood)
        return grouped
            .map { MoodCount(mood: $0.key, count: $0.value.count) }
            .sorted { $0.mood < $1.mood }
    }

    var napTrend: [NapDataPoint] {
        filteredDiaryLogs
            .filter { isInCurrentWeek($0.date) }
            .sorted { $0.date < $1.date }
            .map { NapDataPoint(date: $0.date, minutes: $0.napDurationMinutes) }
    }

    var bodyPartCounts: [BodyPartCount] {
        let grouped = Dictionary(grouping: filteredIncidents, by: \.bodyPart)
        return grouped
            .map { BodyPartCount(bodyPart: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    /// Children present per weekday (or 0/1 per day when filtered to one child).
    var weeklyAttendance: [WeeklyAttendancePoint] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return []
        }

        var points: [WeeklyAttendancePoint] = []
        var day = weekInterval.start

        while day < weekInterval.end {
            let dayRecords = weekAttendanceRecords.filter {
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
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        }

        return points
    }

    /// Days present this week per child (nursery-wide view only).
    var childAttendanceFrequency: [ChildAttendanceFrequency] {
        guard childFilter == nil else { return [] }

        let presentRecords = weekAttendanceRecords.filter(\.isPresent)
        let grouped = Dictionary(grouping: presentRecords, by: \.childName)

        return grouped
            .map { name, records in
                let uniqueDays = Set(
                    records.map { Calendar.current.startOfDay(for: $0.date) }
                )
                return ChildAttendanceFrequency(childName: name, daysPresent: uniqueDays.count)
            }
            .sorted { $0.daysPresent > $1.daysPresent }
    }

    private var weekAttendanceRecords: [AttendanceRecord] {
        filteredAttendance.filter { isInCurrentWeek($0.date) }
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

    private func isInCurrentWeek(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
}
