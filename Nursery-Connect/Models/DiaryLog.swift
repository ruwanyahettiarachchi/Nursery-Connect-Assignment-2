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

// Daily diary: supports EYFS-aligned recording of activities, care, and routine (e.g. rest, wellbeing).
@Model
final class DiaryLog {
    var childName: String
    var activity: String
    var mood: String
    var napStart: Date
    var napEnd: Date
    /// Whether nappy details were recorded for this entry (some entries won't include it).
    var nappyRecorded: Bool
    /// If `nappyRecorded` is true, whether a change occurred.
    var nappyChanged: Bool
    /// Persist meals as JSON to avoid SwiftData transformable inference issues.
    var mealsData: Data
    var date: Date
    /// Creation timestamp. SwiftData models use stored `var` properties; do not mutate after init.
    var createdAt: Date

    init(
        childName: String,
        activity: String,
        mood: String,
        napStart: Date,
        napEnd: Date,
        nappyRecorded: Bool = false,
        nappyChanged: Bool,
        meals: [MealEntry] = [],
        date: Date,
        createdAt: Date = Date()
    ) {
        self.childName = childName
        self.activity = activity
        self.mood = mood
        self.napStart = napStart
        self.napEnd = napEnd
        self.nappyRecorded = nappyRecorded
        self.nappyChanged = nappyChanged
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
