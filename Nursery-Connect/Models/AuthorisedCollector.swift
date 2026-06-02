import Foundation
import SwiftData

/// Parent-managed list of authorised collectors (FR22).
/// In this prototype we do not implement parent login; keyworkers can view/select from this list.
@Model
final class AuthorisedCollector {
    var childName: String
    var name: String
    var relationship: String
    /// In a real system this would reference a secure photo ID store; here we keep a short note.
    var photoIDReference: String
    var createdAt: Date

    init(
        childName: String,
        name: String,
        relationship: String,
        photoIDReference: String = "",
        createdAt: Date = Date()
    ) {
        self.childName = childName
        self.name = name
        self.relationship = relationship
        self.photoIDReference = photoIDReference
        self.createdAt = createdAt
    }
}

