import SwiftUI
import SwiftData

private enum DropOffSelection: Hashable {
    case authorised(PersistentIdentifier)
    case otherVisitor
}

struct AttendanceCheckInSheet: View {
    let child: Child
    let authorisedCollectors: [AuthorisedCollector]
    let existingRecord: AttendanceRecord?
    let onSave: (
        _ droppedOffByName: String,
        _ droppedOffByRelationship: String,
        _ staffName: String,
        _ notes: String,
        _ saveToAuthorisedList: Bool
    ) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var dropOffSelection: DropOffSelection
    @State private var otherVisitorName: String
    @State private var otherVisitorRelationship: String
    @State private var saveToAuthorisedList: Bool
    @State private var staffName: String
    @State private var notes: String

    init(
        child: Child,
        authorisedCollectors: [AuthorisedCollector],
        existingRecord: AttendanceRecord?,
        onSave: @escaping (
            _ droppedOffByName: String,
            _ droppedOffByRelationship: String,
            _ staffName: String,
            _ notes: String,
            _ saveToAuthorisedList: Bool
        ) -> Void
    ) {
        self.child = child
        self.authorisedCollectors = authorisedCollectors
        self.existingRecord = existingRecord
        self.onSave = onSave

        var initialSelection: DropOffSelection = .otherVisitor
        var initialOtherName = ""
        var initialOtherRelationship = ""

        if let existingRecord, !existingRecord.droppedOffByName.isEmpty {
            if let match = authorisedCollectors.first(where: {
                $0.name == existingRecord.droppedOffByName && $0.relationship == existingRecord.droppedOffByRelationship
            }) {
                initialSelection = .authorised(match.persistentModelID)
            } else {
                initialSelection = .otherVisitor
                initialOtherName = existingRecord.droppedOffByName
                initialOtherRelationship = existingRecord.droppedOffByRelationship
            }
        } else if let first = authorisedCollectors.first {
            initialSelection = .authorised(first.persistentModelID)
        }

        _dropOffSelection = State(initialValue: initialSelection)
        _otherVisitorName = State(initialValue: initialOtherName)
        _otherVisitorRelationship = State(initialValue: initialOtherRelationship)
        _saveToAuthorisedList = State(initialValue: true)
        _staffName = State(initialValue: existingRecord?.checkedInByStaffName ?? "")
        _notes = State(initialValue: existingRecord?.notes ?? "")
    }

    var body: some View {
        Form {
            Section("Arrival") {
                Text(child.name)
                    .font(.headline)
                Text("Arrival time will be recorded automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Dropped off by") {
                if authorisedCollectors.isEmpty {
                    Text("No authorised collectors on file yet. Enter visitor details below.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Name", text: $otherVisitorName)
                    TextField("Relationship", text: $otherVisitorRelationship)
                    Toggle("Save to authorised collectors", isOn: $saveToAuthorisedList)
                } else {
                    Picker("Select person", selection: $dropOffSelection) {
                        ForEach(authorisedCollectors) { collector in
                            Text("\(collector.name) (\(collector.relationship))")
                                .tag(DropOffSelection.authorised(collector.persistentModelID))
                        }
                        Text("Other visitor (new)")
                            .tag(DropOffSelection.otherVisitor)
                    }

                    if case .authorised(let id) = dropOffSelection,
                       let collector = authorisedCollectors.first(where: { $0.persistentModelID == id }) {
                        LabeledContent("Name", value: collector.name)
                        LabeledContent("Relationship", value: collector.relationship)
                    }

                    if case .otherVisitor = dropOffSelection {
                        TextField("Name", text: $otherVisitorName)
                        TextField("Relationship", text: $otherVisitorRelationship)
                        Toggle("Save to authorised collectors", isOn: $saveToAuthorisedList)
                    }
                }
            }

            Section("Notes") {
                TextField("Optional notes", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle("Check in")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveTapped() }
                    .disabled(!canSave)
            }
        }
    }

    private var canSave: Bool {
        let (name, relationship) = resolvedDropOff()
        return !name.isEmpty && !relationship.isEmpty
    }

    private func resolvedDropOff() -> (String, String) {
        switch dropOffSelection {
        case .authorised(let id):
            guard let c = authorisedCollectors.first(where: { $0.persistentModelID == id }) else {
                return ("", "")
            }
            return (c.name, c.relationship)
        case .otherVisitor:
            return (
                otherVisitorName.trimmingCharacters(in: .whitespacesAndNewlines),
                otherVisitorRelationship.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }

    private func saveTapped() {
        let (name, relationship) = resolvedDropOff()
        let shouldSaveCollector: Bool
        if case .otherVisitor = dropOffSelection {
            shouldSaveCollector = saveToAuthorisedList
        } else {
            shouldSaveCollector = false
        }
        onSave(name, relationship, "Keyworker", notes.trimmingCharacters(in: .whitespacesAndNewlines), shouldSaveCollector)
    }
}
