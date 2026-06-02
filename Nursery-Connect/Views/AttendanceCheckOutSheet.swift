import SwiftUI
import SwiftData

struct AttendanceCheckOutSheet: View {
    let child: Child
    let existingRecord: AttendanceRecord?
    let authorisedCollectors: [AuthorisedCollector]
    let onSave: (_ collectorName: String, _ collectorRelationship: String, _ isAuthorised: Bool, _ staffName: String, _ notes: String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedCollectorID: PersistentIdentifier?
    @State private var unknownCollector: Bool
    @State private var collectorName: String
    @State private var collectorRelationship: String
    @State private var staffName: String
    @State private var notes: String

    init(
        child: Child,
        existingRecord: AttendanceRecord?,
        authorisedCollectors: [AuthorisedCollector],
        onSave: @escaping (_ collectorName: String, _ collectorRelationship: String, _ isAuthorised: Bool, _ staffName: String, _ notes: String) -> Void
    ) {
        self.child = child
        self.existingRecord = existingRecord
        self.authorisedCollectors = authorisedCollectors
        self.onSave = onSave

        _selectedCollectorID = State(initialValue: authorisedCollectors.first?.persistentModelID)
        _unknownCollector = State(initialValue: false)
        _collectorName = State(initialValue: existingRecord?.collectedByName ?? "")
        _collectorRelationship = State(initialValue: existingRecord?.collectedByRelationship ?? "")
        _staffName = State(initialValue: existingRecord?.checkedOutByStaffName ?? "")
        _notes = State(initialValue: existingRecord?.notes ?? "")
    }

    var body: some View {
        Form {
            Section("Departure") {
                Text(child.name)
                    .font(.headline)
                Text("Departure time will be recorded automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Collector") {
                if authorisedCollectors.isEmpty {
                    Text("No authorised collectors on file.")
                        .foregroundStyle(.secondary)
                    Toggle("Unknown collector", isOn: $unknownCollector)
                        .onChange(of: unknownCollector) { _, _ in
                            if !unknownCollector {
                                collectorName = ""
                                collectorRelationship = ""
                            }
                        }
                } else {
                    Toggle("Unknown collector", isOn: $unknownCollector)
                        .onChange(of: unknownCollector) { _, newValue in
                            if !newValue {
                                syncFromSelectedCollector()
                            }
                        }

                    if unknownCollector {
                        TextField("Name", text: $collectorName)
                        TextField("Relationship", text: $collectorRelationship)
                    } else {
                        Picker("Authorised collector", selection: $selectedCollectorID) {
                            ForEach(authorisedCollectors) { collector in
                                Text("\(collector.name) (\(collector.relationship))")
                                    .tag(collector.persistentModelID as PersistentIdentifier?)
                            }
                        }
                        .onChange(of: selectedCollectorID) { _, _ in
                            syncFromSelectedCollector()
                        }
                    }
                }
            }

            Section("Checked out by staff") {
                TextField("Staff name", text: $staffName)
            }

            Section("Notes") {
                TextField("Optional notes", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle("Check out")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !unknownCollector {
                syncFromSelectedCollector()
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let (name, relationship, authorised) = collectorValues()
                    onSave(
                        name,
                        relationship,
                        authorised,
                        staffName.trimmingCharacters(in: .whitespacesAndNewlines),
                        notes.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                }
                .disabled(collectorValues().0.isEmpty || collectorValues().1.isEmpty)
            }
        }
    }

    private func collectorValues() -> (String, String, Bool) {
        if unknownCollector {
            return (
                collectorName.trimmingCharacters(in: .whitespacesAndNewlines),
                collectorRelationship.trimmingCharacters(in: .whitespacesAndNewlines),
                false
            )
        }

        guard let selectedCollectorID,
              let c = authorisedCollectors.first(where: { $0.persistentModelID == selectedCollectorID })
        else {
            return ("", "", true)
        }
        return (c.name, c.relationship, true)
    }

    private func syncFromSelectedCollector() {
        guard let selectedCollectorID,
              let c = authorisedCollectors.first(where: { $0.persistentModelID == selectedCollectorID })
        else { return }

        collectorName = c.name
        collectorRelationship = c.relationship
    }
}

