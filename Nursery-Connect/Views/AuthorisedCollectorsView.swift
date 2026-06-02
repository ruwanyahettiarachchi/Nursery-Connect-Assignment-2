import SwiftUI
import SwiftData

struct AuthorisedCollectorsView: View {
    let child: Child

    @Environment(\.modelContext) private var modelContext
    @Query private var collectors: [AuthorisedCollector]

    @State private var name: String = ""
    @State private var relationship: String = ""
    @State private var photoIDReference: String = ""

    init(child: Child) {
        self.child = child
        let childName = child.name
        _collectors = Query(
            filter: #Predicate<AuthorisedCollector> { $0.childName == childName },
            sort: \AuthorisedCollector.createdAt,
            order: .reverse
        )
    }

    var body: some View {
        Form {
            Section("Add collector") {
                TextField("Name", text: $name)
                TextField("Relationship", text: $relationship)
                TextField("Photo ID reference (optional)", text: $photoIDReference)

                Button {
                    addCollector()
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || relationship.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section("Authorised collectors") {
                if collectors.isEmpty {
                    ContentUnavailableView {
                        Label("No collectors yet", systemImage: "person.crop.circle.badge.questionmark")
                    } description: {
                        Text("Add authorised adults for pick-up. Keyworkers will be alerted if an unknown collector is used at check-out.")
                    }
                } else {
                    ForEach(collectors) { collector in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(collector.name)
                                .font(.headline)
                            Text(collector.relationship)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if !collector.photoIDReference.isEmpty {
                                Text("ID: \(collector.photoIDReference)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteCollectors)
                }
            }
        }
        .navigationTitle("Collectors")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addCollector() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRelationship = relationship.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedID = photoIDReference.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedRelationship.isEmpty else { return }

        let newCollector = AuthorisedCollector(
            childName: child.name,
            name: trimmedName,
            relationship: trimmedRelationship,
            photoIDReference: trimmedID
        )
        modelContext.insert(newCollector)
        try? modelContext.save()

        name = ""
        relationship = ""
        photoIDReference = ""
    }

    private func deleteCollectors(at offsets: IndexSet) {
        for idx in offsets {
            modelContext.delete(collectors[idx])
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        AuthorisedCollectorsView(child: Child(name: "Ava", age: 3))
    }
    .modelContainer(for: [Child.self, DiaryLog.self, Incident.self, AttendanceRecord.self, AuthorisedCollector.self, MoodCheckIn.self], inMemory: true)
}

