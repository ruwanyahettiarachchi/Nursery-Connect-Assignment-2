import Foundation
import SwiftData

// Incident report: documents events for safeguarding and EYFS-related duty of care and record-keeping.
@Model
final class Incident {
    var childName: String
    var date: Date
    var descriptionText: String
    var bodyPart: String
    /// Creation timestamp. SwiftData models use stored `var` properties; do not mutate after init.
    var createdAt: Date

    init(
        childName: String,
        date: Date,
        descriptionText: String,
        bodyPart: String,
        createdAt: Date = Date()
    ) {
        self.childName = childName
        self.date = date
        self.descriptionText = descriptionText
        self.bodyPart = bodyPart
        self.createdAt = createdAt
    }
}
