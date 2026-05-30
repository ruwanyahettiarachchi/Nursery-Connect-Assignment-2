import SwiftUI
import SwiftData

struct AddDiaryView: View {
    let child: Child
    private let diaryLogToEdit: DiaryLog?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var activity: String
    @State private var mood: String
    @State private var napStart: Date
    @State private var napEnd: Date
    @State private var nappyRecorded: Bool
    @State private var nappyChanged: Bool
    @State private var meals: [MealEntry]
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    init(child: Child, diaryLogToEdit: DiaryLog? = nil) {
        self.child = child
        self.diaryLogToEdit = diaryLogToEdit
        if let log = diaryLogToEdit {
            _activity = State(initialValue: log.activity)
            _mood = State(initialValue: log.mood)
            _napStart = State(initialValue: log.napStart)
            _napEnd = State(initialValue: log.napEnd)
            // Older entries (before nappyRecorded existed) should still show nappy controls.
            _nappyRecorded = State(initialValue: true)
            _nappyChanged = State(initialValue: log.nappyChanged)
            _meals = State(initialValue: log.meals)
        } else {
            _activity = State(initialValue: "")
            _mood = State(initialValue: "Happy")
            _napStart = State(initialValue: Date())
            _napEnd = State(initialValue: Date())
            _nappyRecorded = State(initialValue: false)
            _nappyChanged = State(initialValue: false)
            _meals = State(initialValue: [])
        }
    }

    private var isEditing: Bool { diaryLogToEdit != nil }

    var body: some View {
        Form {
            Section("Activity") {
                TextField("Activity", text: $activity)
            }

            Section("Mood & Nap") {
                Picker("Mood", selection: $mood) {
                    Text("Happy").tag("Happy")
                    Text("Sad").tag("Sad")
                    Text("Tired").tag("Tired")
                }

                DatePicker(
                    "Nap Start",
                    selection: $napStart,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.compact)

                DatePicker(
                    "Nap End",
                    selection: $napEnd,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.compact)
            }

            Section("Nappy Change") {
                Toggle("Add nappy change", isOn: $nappyRecorded)
                    .onChange(of: nappyRecorded) { _, newValue in
                        if !newValue {
                            nappyChanged = false
                        }
                    }

                if nappyRecorded {
                    Toggle("Nappy changed", isOn: $nappyChanged)
                }
            }

            Section("Meals") {
                if meals.isEmpty {
                    Text("Add up to 3 meals (optional).")
                        .foregroundStyle(.secondary)
                }

                ForEach($meals) { $meal in
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Meal", selection: $meal.type) {
                            Text("Breakfast").tag("Breakfast")
                            Text("Lunch").tag("Lunch")
                            Text("Dinner").tag("Dinner")
                            Text("Snack").tag("Snack")
                        }

                        DatePicker("Time", selection: $meal.time, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.compact)

                        TextField("Notes (optional)", text: $meal.notes, axis: .vertical)
                            .lineLimit(2...4)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { offsets in
                    meals.remove(atOffsets: offsets)
                }

                Button {
                    guard meals.count < 3 else { return }
                    meals.append(MealEntry(type: "Lunch", time: Date(), notes: ""))
                } label: {
                    Label(meals.count >= 3 ? "Meal limit reached" : "Add meal", systemImage: "plus.circle")
                }
                .disabled(meals.count >= 3)
            }
        }
        .scrollContentBackground(.hidden)
        .background(NurseryTheme.pageBackground.ignoresSafeArea(edges: [.horizontal, .bottom]))
        .navigationTitle(isEditing ? "Edit Diary Entry" : "New Diary Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveDiaryEntry()
                }
            }
        }
        .alert("Unable to Save Diary Entry", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func timeOnSameDay(_ time: Date, day: Date) -> Date {
        let calendar = Calendar.current
        let t = calendar.dateComponents([.hour, .minute], from: time)
        let d = calendar.dateComponents([.year, .month, .day], from: day)
        var combined = DateComponents()
        combined.year = d.year
        combined.month = d.month
        combined.day = d.day
        combined.hour = t.hour
        combined.minute = t.minute
        return calendar.date(from: combined) ?? time
    }

    private func saveDiaryEntry() {
        let trimmedActivity = activity.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedActivity.isEmpty else {
            alertMessage = "Please enter the child's activity before saving."
            showAlert = true
            return
        }

        let entryDay = diaryLogToEdit?.date ?? Date()
        let normalizedNapStart = timeOnSameDay(napStart, day: entryDay)
        let normalizedNapEnd = timeOnSameDay(napEnd, day: entryDay)

        let cleanedMeals: [MealEntry] = meals.compactMap { meal in
            let trimmedNotes = meal.notes.trimmingCharacters(in: .whitespacesAndNewlines)
            return MealEntry(id: meal.id, type: meal.type, time: timeOnSameDay(meal.time, day: entryDay), notes: trimmedNotes)
        }

        var insertedLog: DiaryLog?

        if let editing = diaryLogToEdit {
            editing.activity = trimmedActivity
            editing.mood = mood
            editing.napStart = normalizedNapStart
            editing.napEnd = normalizedNapEnd
            editing.nappyRecorded = nappyRecorded
            editing.nappyChanged = nappyChanged
            editing.meals = cleanedMeals
            editing.childName = child.name
        } else {
            let newLog = DiaryLog(
                childName: child.name,
                activity: trimmedActivity,
                mood: mood,
                napStart: normalizedNapStart,
                napEnd: normalizedNapEnd,
                nappyRecorded: nappyRecorded,
                nappyChanged: nappyChanged,
                meals: cleanedMeals,
                date: Date()
            )
            modelContext.insert(newLog)
            insertedLog = newLog
        }

        do {
            try modelContext.save()
            Haptics.diarySaved()
            dismiss()
        } catch {
            if let insertedLog {
                modelContext.delete(insertedLog)
            }
            alertMessage = "We couldn't save this diary entry. Please try again."
            showAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        AddDiaryView(child: Child(name: "Ava", age: 3))
    }
    .modelContainer(for: [Child.self, DiaryLog.self, Incident.self], inMemory: true)
}
