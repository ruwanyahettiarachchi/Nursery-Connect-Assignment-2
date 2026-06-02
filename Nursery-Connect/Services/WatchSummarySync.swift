import Foundation
import SwiftData

enum WatchSummarySync {
    @MainActor
    static func publish(from context: ModelContext, attendanceAlert: WatchAttendanceAlert? = nil) {
        let children = (try? context.fetch(FetchDescriptor<Child>())) ?? []
        let diaryLogs = (try? context.fetch(FetchDescriptor<DiaryLog>())) ?? []
        let incidents = (try? context.fetch(FetchDescriptor<Incident>())) ?? []
        let attendance = (try? context.fetch(FetchDescriptor<AttendanceRecord>())) ?? []

        let calendar = Calendar.current
        let todayDiary = diaryLogs.filter { calendar.isDateInToday($0.date) }
        let todayIncidents = incidents.filter { calendar.isDateInToday($0.date) }
        let todayAttendance = attendance.filter { calendar.isDateInToday($0.date) }

        let studentsInNursery = todayAttendance.filter { record in
            !record.isAbsent && record.signInTime != nil && record.signOutTime == nil
        }.count

        let recent = incidents
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map {
                WatchRecentIncident(
                    id: UUID(),
                    childName: $0.childName,
                    bodyPart: $0.bodyPart,
                    date: $0.date
                )
            }

        let previous = WatchSummaryStore.load()
        let resolvedAlert: WatchAttendanceAlert?
        if let attendanceAlert {
            resolvedAlert = attendanceAlert
        } else if let previous, let existing = previous.attendanceAlert, calendar.isDateInToday(existing.date) {
            resolvedAlert = existing
        } else {
            resolvedAlert = nil
        }

        let summary = WatchTodaySummary(
            updatedAt: Date(),
            childrenCount: children.count,
            studentsInNurseryToday: studentsInNursery,
            diaryEntriesToday: todayDiary.count,
            incidentsToday: todayIncidents.count,
            recentIncidents: Array(recent),
            attendanceAlert: resolvedAlert
        )

        WatchSummaryStore.save(summary)
        WatchSessionManager.shared.sendSummary(summary)
    }
}

