import Foundation
import SwiftData

struct MealEntry: Codable, Hashable, Identifiable {
    var id: UUID
    var type: String
    var time: Date
    var notes: String

    init(id: UUID = UUID(), type: String, time: Date, notes: String) {
        self.id = id
        self.type = type
        self.time = time
        self.notes = notes
    }
}

/// Coarse activity types (FR13). Stored as strings in SwiftData.
enum DiaryActivityType {
    static let indoorPlay = "Indoor play"
    static let outdoorPlay = "Outdoor play"
    static let reading = "Reading"
    static let artsCrafts = "Arts & crafts"
    static let educationalSession = "Educational session"
    static let freePlay = "Free play"
    static let restPeriod = "Rest period"
}

/// Sleep position options (FR14). Stored as strings in SwiftData.
enum SleepPosition {
    static let onBack = "On back"
    static let onSide = "On side"
    static let onFront = "On front"
    static let unknown = "Unknown"
}

/// Nappy/toilet log types (FR15). Stored as strings in SwiftData.
enum NappyToiletType {
    static let wet = "Wet"
    static let soiled = "Soiled"
    static let toilet = "Toilet"
    static let none = "None"
}

// Daily diary: supports EYFS-aligned recording of activities, care, and routine (e.g. rest, wellbeing).
@Model
final class DiaryLog {
    var childName: String
    /// Free-text summary of the activity.
    var activity: String
    /// Structured activity type (FR13).
    var activityType: String
    /// Simple mood snapshot for the entry (kept for backwards compatibility).
    var mood: String
    /// Whether a nap was recorded for this entry (FR14).
    var napRecorded: Bool
    var napStart: Date
    var napEnd: Date
    /// Sleep position recorded for this nap session (FR14).
    var sleepPosition: String
    /// Whether nappy details were recorded for this entry (some entries won't include it).
    var nappyRecorded: Bool
    /// If `nappyRecorded` is true, whether a change occurred.
    var nappyChanged: Bool
    /// Time of nappy/toilet event (FR15). Optional to keep older entries valid.
    var nappyTime: Date?
    /// Nappy/toilet log type (FR15).
    var nappyType: String
    /// Observations of concern (FR15) — used for alerting in UI.
    var nappyConcernNotes: String
    /// Persist meals as JSON to avoid SwiftData transformable inference issues.
    var mealsData: Data
    var date: Date
    /// Creation timestamp. SwiftData models use stored `var` properties; do not mutate after init.
    var createdAt: Date

    init(
        childName: String,
        activity: String,
        activityType: String = DiaryActivityType.freePlay,
        mood: String,
        napRecorded: Bool = false,
        napStart: Date,
        napEnd: Date,
        sleepPosition: String = SleepPosition.unknown,
        nappyRecorded: Bool = false,
        nappyChanged: Bool,
        nappyTime: Date? = nil,
        nappyType: String = NappyToiletType.none,
        nappyConcernNotes: String = "",
        meals: [MealEntry] = [],
        date: Date,
        createdAt: Date = Date()
    ) {
        self.childName = childName
        self.activity = activity
        self.activityType = activityType
        self.mood = mood
        self.napRecorded = napRecorded
        self.napStart = napStart
        self.napEnd = napEnd
        self.sleepPosition = sleepPosition
        self.nappyRecorded = nappyRecorded
        self.nappyChanged = nappyChanged
        self.nappyTime = nappyTime
        self.nappyType = nappyType
        self.nappyConcernNotes = nappyConcernNotes
        self.mealsData = (try? JSONEncoder().encode(meals)) ?? Data()
        self.date = date
        self.createdAt = createdAt
    }

    var meals: [MealEntry] {
        get {
            (try? JSONDecoder().decode([MealEntry].self, from: mealsData)) ?? []
        }
        set {
            mealsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    /// Nap length in whole minutes (not persisted).
    var napDurationMinutes: Int {
        let seconds = napEnd.timeIntervalSince(napStart)
        let minutes = Int(seconds / 60.0)
        return max(0, minutes)
    }
}
