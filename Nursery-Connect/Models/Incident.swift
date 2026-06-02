import Foundation
import SwiftData

struct IncidentWitness: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

enum IncidentCategory {
    static let accidentMinor = "Accident (minor)"
    static let accidentFirstAid = "Accident (first aid)"
    static let safeguarding = "Safeguarding concern"
    static let nearMiss = "Near miss"
    static let allergicReaction = "Allergic reaction"
    static let medicalIncident = "Medical incident"
}

enum BodyMapSide {
    static let front = "Front"
    static let back = "Back"
}

// Incident report: documents events for safeguarding and EYFS-related duty of care and record-keeping.
@Model
final class Incident {
    var childName: String
    var date: Date
    /// Category (FR25).
    var category: String
    /// Location (FR24).
    var location: String
    var descriptionText: String
    /// Body part (kept) + optional body map region (FR24).
    var bodyPart: String
    var bodyMapSide: String
    var bodyMapRegion: String
    /// Immediate action taken (FR24).
    var immediateActionTaken: String
    /// Witnesses (FR24).
    var witnessesData: Data

    /// Workflow: manager countersign required before finalisation (FR26).
    var managerCountersignRequired: Bool
    var managerSignedByName: String
    var managerSignedAt: Date?
    /// Workflow: parent must acknowledge receipt (FR27).
    var parentAcknowledgedAt: Date?
    /// Creation timestamp. SwiftData models use stored `var` properties; do not mutate after init.
    var createdAt: Date

    init(
        childName: String,
        date: Date,
        category: String = IncidentCategory.accidentMinor,
        location: String = "",
        descriptionText: String,
        bodyPart: String,
        bodyMapSide: String = BodyMapSide.front,
        bodyMapRegion: String = "",
        immediateActionTaken: String = "",
        witnesses: [IncidentWitness] = [],
        managerCountersignRequired: Bool = true,
        managerSignedByName: String = "",
        managerSignedAt: Date? = nil,
        parentAcknowledgedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.childName = childName
        self.date = date
        self.category = category
        self.location = location
        self.descriptionText = descriptionText
        self.bodyPart = bodyPart
        self.bodyMapSide = bodyMapSide
        self.bodyMapRegion = bodyMapRegion
        self.immediateActionTaken = immediateActionTaken
        self.witnessesData = (try? JSONEncoder().encode(witnesses)) ?? Data()
        self.managerCountersignRequired = managerCountersignRequired
        self.managerSignedByName = managerSignedByName
        self.managerSignedAt = managerSignedAt
        self.parentAcknowledgedAt = parentAcknowledgedAt
        self.createdAt = createdAt
    }

    var witnesses: [IncidentWitness] {
        get {
            (try? JSONDecoder().decode([IncidentWitness].self, from: witnessesData)) ?? []
        }
        set {
            witnessesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var isManagerSigned: Bool {
        managerSignedAt != nil
    }

    var isParentAcknowledged: Bool {
        parentAcknowledgedAt != nil
    }
}
