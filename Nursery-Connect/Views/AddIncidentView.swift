import SwiftUI
import SwiftData

struct AddIncidentView: View {
    let child: Child
    private let incidentToEdit: Incident?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var category: String
    @State private var location: String
    @State private var descriptionText: String
    @State private var bodyPart: String
    @State private var bodyMapSide: String
    @State private var bodyMapRegion: String
    @State private var immediateActionTaken: String
    @State private var witnesses: [IncidentWitness]
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    private let maxDescriptionLength = 500

    init(child: Child, incidentToEdit: Incident? = nil) {
        self.child = child
        self.incidentToEdit = incidentToEdit
        if let incident = incidentToEdit {
            _date = State(initialValue: incident.date)
            _category = State(initialValue: incident.category)
            _location = State(initialValue: incident.location)
            _descriptionText = State(initialValue: incident.descriptionText)
            _bodyPart = State(initialValue: incident.bodyPart)
            _bodyMapSide = State(initialValue: incident.bodyMapSide)
            _bodyMapRegion = State(initialValue: incident.bodyMapRegion)
            _immediateActionTaken = State(initialValue: incident.immediateActionTaken)
            _witnesses = State(initialValue: incident.witnesses)
        } else {
            _date = State(initialValue: Date())
            _category = State(initialValue: IncidentCategory.accidentMinor)
            _location = State(initialValue: "")
            _descriptionText = State(initialValue: "")
            _bodyPart = State(initialValue: "Other")
            _bodyMapSide = State(initialValue: BodyMapSide.front)
            _bodyMapRegion = State(initialValue: "")
            _immediateActionTaken = State(initialValue: "")
            _witnesses = State(initialValue: [])
        }
    }

    private var isEditing: Bool { incidentToEdit != nil }

    private var latestSelectableDate: Date { Date() }

    var body: some View {
        Form {
            Section("Incident Details") {
                DatePicker(
                    "Date",
                    selection: $date,
                    in: ...latestSelectableDate,
                    displayedComponents: [.date, .hourAndMinute]
                )

                Picker("Category", selection: $category) {
                    Text(IncidentCategory.accidentMinor).tag(IncidentCategory.accidentMinor)
                    Text(IncidentCategory.accidentFirstAid).tag(IncidentCategory.accidentFirstAid)
                    Text(IncidentCategory.safeguarding).tag(IncidentCategory.safeguarding)
                    Text(IncidentCategory.nearMiss).tag(IncidentCategory.nearMiss)
                    Text(IncidentCategory.allergicReaction).tag(IncidentCategory.allergicReaction)
                    Text(IncidentCategory.medicalIncident).tag(IncidentCategory.medicalIncident)
                }

                TextField("Location (e.g., playground)", text: $location)

                Picker("Body Part", selection: $bodyPart) {
                    Text("Head").tag("Head")
                    Text("Arm").tag("Arm")
                    Text("Leg").tag("Leg")
                    Text("Other").tag("Other")
                }

                Picker("Body map side", selection: $bodyMapSide) {
                    Text(BodyMapSide.front).tag(BodyMapSide.front)
                    Text(BodyMapSide.back).tag(BodyMapSide.back)
                }

                TextField("Body map region (optional)", text: $bodyMapRegion)

                ZStack(alignment: .topLeading) {
                    if descriptionText.isEmpty {
                        Text("Describe what happened...")
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 140)
                        .accessibilityIdentifier("incident.description")
                        .onChange(of: descriptionText) { _, newValue in
                            if newValue.count > maxDescriptionLength {
                                descriptionText = String(newValue.prefix(maxDescriptionLength))
                            }
                        }
                }

                Text("\(descriptionText.count)/\(maxDescriptionLength)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Section("Immediate Action Taken") {
                TextField("e.g., applied ice pack, informed manager", text: $immediateActionTaken, axis: .vertical)
                    .lineLimit(2...5)
            }

            Section("Witnesses") {
                if witnesses.isEmpty {
                    Text("Add staff or witness names (optional).")
                        .foregroundStyle(.secondary)
                }

                ForEach($witnesses) { $witness in
                    TextField("Witness name", text: $witness.name)
                }
                .onDelete { offsets in
                    witnesses.remove(atOffsets: offsets)
                }

                Button {
                    witnesses.append(IncidentWitness(name: ""))
                } label: {
                    Label("Add witness", systemImage: "plus.circle")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(NurseryTheme.pageBackground.ignoresSafeArea(edges: [.horizontal, .bottom]))
        .navigationTitle(isEditing ? "Edit Incident" : "New Incident")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Submit") {
                    submitIncident()
                }
                .accessibilityIdentifier("incident.submit")
            }
        }
        .alert("Unable to Submit Incident", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func submitIncident() {
        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAction = immediateActionTaken.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedWitnesses = witnesses
            .map { IncidentWitness(id: $0.id, name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.name.isEmpty }

        guard !trimmedDescription.isEmpty else {
            alertMessage = "Please enter an incident description before submitting."
            showAlert = true
            return
        }

        if date > latestSelectableDate {
            alertMessage = "The incident date cannot be in the future. Please choose today or an earlier time."
            showAlert = true
            return
        }

        var insertedIncident: Incident?

        if let editing = incidentToEdit {
            editing.date = date
            editing.category = category
            editing.location = trimmedLocation
            editing.descriptionText = trimmedDescription
            editing.bodyPart = bodyPart
            editing.childName = child.name
            editing.bodyMapSide = bodyMapSide
            editing.bodyMapRegion = bodyMapRegion.trimmingCharacters(in: .whitespacesAndNewlines)
            editing.immediateActionTaken = trimmedAction
            editing.witnesses = cleanedWitnesses
            // Editing an incident resets workflow until manager countersigns again.
            editing.managerCountersignRequired = true
            editing.managerSignedAt = nil
            editing.managerSignedByName = ""
            editing.parentAcknowledgedAt = nil
        } else {
            let newIncident = Incident(
                childName: child.name,
                date: date,
                category: category,
                location: trimmedLocation,
                descriptionText: trimmedDescription,
                bodyPart: bodyPart,
                bodyMapSide: bodyMapSide,
                bodyMapRegion: bodyMapRegion.trimmingCharacters(in: .whitespacesAndNewlines),
                immediateActionTaken: trimmedAction,
                witnesses: cleanedWitnesses,
                managerCountersignRequired: true
            )
            modelContext.insert(newIncident)
            insertedIncident = newIncident
        }

        do {
            try modelContext.save()
            WatchSummarySync.publish(from: modelContext)
            Haptics.incidentSubmitted()
            dismiss()
        } catch {
            if let insertedIncident {
                modelContext.delete(insertedIncident)
            }
            alertMessage = "We couldn't submit this incident. Please try again."
            showAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        AddIncidentView(child: Child(name: "Ava", age: 3))
    }
    .modelContainer(for: [Child.self, DiaryLog.self, Incident.self, AttendanceRecord.self, AuthorisedCollector.self, MoodCheckIn.self], inMemory: true)
}
