import Foundation
import SwiftData

/// Removes same-day attendance rows created by older sample seeding (sign-in + sign-out pre-filled).
enum AttendanceSeedCleanup {
    private static let didRunKey = "didClearSeededTodayAttendance_v1"

    @MainActor
    static func removeSeededTodayRecordsIfNeeded(in context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: didRunKey) else { return }

        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let records = (try? context.fetch(FetchDescriptor<AttendanceRecord>())) ?? []
        let todayRecords = records.filter { calendar.isDate($0.date, inSameDayAs: todayStart) }

        defer { UserDefaults.standard.set(true, forKey: didRunKey) }

        guard !todayRecords.isEmpty else { return }

        let looksLikeOldSeed = todayRecords.allSatisfy { record in
            record.signInTime != nil && record.signOutTime != nil
        }
        guard looksLikeOldSeed else { return }

        for record in todayRecords {
            context.delete(record)
        }
        try? context.save()
        WatchSummarySync.publish(from: context)
    }
}
