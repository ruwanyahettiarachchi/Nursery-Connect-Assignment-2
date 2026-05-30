import SwiftUI
import SwiftData

struct AddIncidentView: View {
    let child: Child
    private let incidentToEdit: Incident?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var descriptionText: String
    @State private var bodyPart: String
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    private let maxDescriptionLength = 500

    init(child: Child, incidentToEdit: Incident? = nil) {
        self.child = child
        self.incidentToEdit = incidentToEdit
        if let incident = incidentToEdit {
            _date = State(initialValue: incident.date)
            _descriptionText = State(initialValue: incident.descriptionText)
            _bodyPart = State(initialValue: incident.bodyPart)
        } else {
            _date = State(initialValue: Date())
            _descriptionText = State(initialValue: "")
            _bodyPart = State(initialValue: "Other")
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

                Picker("Body Part", selection: $bodyPart) {
                    Text("Head").tag("Head")
                    Text("Arm").tag("Arm")
                    Text("Leg").tag("Leg")
                    Text("Other").tag("Other")
                }

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
            editing.descriptionText = trimmedDescription
            editing.bodyPart = bodyPart
            editing.childName = child.name
        } else {
            let newIncident = Incident(
                childName: child.name,
                date: date,
                descriptionText: trimmedDescription,
                bodyPart: bodyPart
            )
            modelContext.insert(newIncident)
            insertedIncident = newIncident
        }

        do {
            try modelContext.save()
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
    .modelContainer(for: [Child.self, DiaryLog.self, Incident.self], inMemory: true)
}
