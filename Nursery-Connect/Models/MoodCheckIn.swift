import Foundation
import SwiftData

enum MoodCheckInTimeOfDay {
    static let arrival = "Arrival"
    static let midday = "Midday"
    static let departure = "Departure"
}

/// Mood/wellbeing check-ins at arrival, midday, and departure (FR16).
@Model
final class MoodCheckIn {
    var childName: String
    var date: Date
    /// One of `MoodCheckInTimeOfDay.*`
    var timeOfDay: String
    /// e.g. Happy, Unsettled, Poorly
    var mood: String
    var notes: String
    var createdAt: Date

    init(
        childName: String,
        date: Date,
        timeOfDay: String,
        mood: String,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.childName = childName
        self.date = date
        self.timeOfDay = timeOfDay
        self.mood = mood
        self.notes = notes
        self.createdAt = createdAt
    }
}

