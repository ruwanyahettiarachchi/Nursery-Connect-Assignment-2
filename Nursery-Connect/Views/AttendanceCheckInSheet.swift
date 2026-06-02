import SwiftUI

struct AttendanceCheckInSheet: View {
    let child: Child
    let existingRecord: AttendanceRecord?
    let onSave: (_ droppedOffByName: String, _ droppedOffByRelationship: String, _ staffName: String, _ notes: String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var droppedOffByName: String
    @State private var droppedOffByRelationship: String
    @State private var staffName: String
    @State private var notes: String

    init(
        child: Child,
        existingRecord: AttendanceRecord?,
        onSave: @escaping (_ droppedOffByName: String, _ droppedOffByRelationship: String, _ staffName: String, _ notes: String) -> Void
    ) {
        self.child = child
        self.existingRecord = existingRecord
        self.onSave = onSave

        _droppedOffByName = State(initialValue: existingRecord?.droppedOffByName ?? "")
        _droppedOffByRelationship = State(initialValue: existingRecord?.droppedOffByRelationship ?? "")
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
                TextField("Name", text: $droppedOffByName)
                TextField("Relationship", text: $droppedOffByRelationship)
            }

            Section("Checked in by staff") {
                TextField("Staff name", text: $staffName)
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
                Button("Save") {
                    onSave(
                        droppedOffByName.trimmingCharacters(in: .whitespacesAndNewlines),
                        droppedOffByRelationship.trimmingCharacters(in: .whitespacesAndNewlines),
                        staffName.trimmingCharacters(in: .whitespacesAndNewlines),
                        notes.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                }
                .disabled(droppedOffByName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || droppedOffByRelationship.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

