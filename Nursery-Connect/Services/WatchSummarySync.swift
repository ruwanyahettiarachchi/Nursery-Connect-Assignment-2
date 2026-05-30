import Foundation
import SwiftData

enum WatchSummarySync {
    @MainActor
    static func publish(from context: ModelContext) {
        let children = (try? context.fetch(FetchDescriptor<Child>())) ?? []
        let diaryLogs = (try? context.fetch(FetchDescriptor<DiaryLog>())) ?? []
        let incidents = (try? context.fetch(FetchDescriptor<Incident>())) ?? []

        let calendar = Calendar.current
        let todayDiary = diaryLogs.filter { calendar.isDateInToday($0.date) }
        let todayIncidents = incidents.filter { calendar.isDateInToday($0.date) }

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

        let summary = WatchTodaySummary(
            updatedAt: Date(),
            childrenCount: children.count,
            diaryEntriesToday: todayDiary.count,
            incidentsToday: todayIncidents.count,
            recentIncidents: Array(recent)
        )

        WatchSummaryStore.save(summary)
    }
}
