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
    /// Person who dropped off the child (FR19).
    var droppedOffByName: String
    /// Relationship to the child, e.g. Mum/Dad/Grandparent (FR19).
    var droppedOffByRelationship: String
    /// Staff member who performed check-in (FR19).
    var checkedInByStaffName: String
    /// Authorised collector name (FR20/FR22).
    var collectedByName: String
    /// Collector relationship (FR20).
    var collectedByRelationship: String
    /// Whether the collector matched the authorised list (FR22).
    var collectorWasAuthorised: Bool
    /// Staff member who performed check-out (FR20).
    var checkedOutByStaffName: String
    /// Optional free-text notes (e.g. ID checked, late arrival).
    var notes: String
    var createdAt: Date

    init(
        childName: String,
        date: Date,
        signInTime: Date? = nil,
        signOutTime: Date? = nil,
        isAbsent: Bool = false,
        droppedOffByName: String = "",
        droppedOffByRelationship: String = "",
        checkedInByStaffName: String = "",
        collectedByName: String = "",
        collectedByRelationship: String = "",
        collectorWasAuthorised: Bool = true,
        checkedOutByStaffName: String = "",
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.childName = childName
        self.date = date
        self.signInTime = signInTime
        self.signOutTime = signOutTime
        self.isAbsent = isAbsent
        self.droppedOffByName = droppedOffByName
        self.droppedOffByRelationship = droppedOffByRelationship
        self.checkedInByStaffName = checkedInByStaffName
        self.collectedByName = collectedByName
        self.collectedByRelationship = collectedByRelationship
        self.collectorWasAuthorised = collectorWasAuthorised
        self.checkedOutByStaffName = checkedOutByStaffName
        self.notes = notes
        self.createdAt = createdAt
    }

    var isPresent: Bool {
        !isAbsent && signInTime != nil && signOutTime == nil
    }
}
