import Foundation
import SwiftData

// Identifies a child in the setting; treat as sensitive personal data (UK GDPR Article 9 context).
@Model
final class Child {
    var name: String
    var age: Int

    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
}

