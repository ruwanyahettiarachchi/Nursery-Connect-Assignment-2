import Foundation
import SwiftData

// Daily sign-in/out record for safeguarding and staffing ratios (EYFS record-keeping).
@Model
final class AttendanceRecord {
    var childName: String
    /// The calendar day this record applies to.
    var date: Date
    var signInTime: Date?
    var signOutTime: Date?
    var isAbsent: Bool
    var createdAt: Date

    init(
        childName: String,
        date: Date,
        signInTime: Date? = nil,
        signOutTime: Date? = nil,
        isAbsent: Bool = false,
        createdAt: Date = Date()
    ) {
        self.childName = childName
        self.date = date
        self.signInTime = signInTime
        self.signOutTime = signOutTime
        self.isAbsent = isAbsent
        self.createdAt = createdAt
    }

    var isPresent: Bool {
        !isAbsent && signInTime != nil
    }
}
