import SwiftUI
import SwiftData

struct AddDiaryView: View {
    let child: Child
    private let diaryLogToEdit: DiaryLog?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var activity: String
    @State private var activityType: String
    @State private var mood: String
    @State private var napRecorded: Bool
    @State private var napStart: Date
    @State private var napEnd: Date
    @State private var sleepPosition: String
    @State private var nappyRecorded: Bool
    @State private var nappyChanged: Bool
    @State private var nappyTime: Date
    @State private var nappyType: String
    @State private var nappyConcernNotes: String
    @State private var meals: [MealEntry]
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var showConcernAlert: Bool = false

    init(child: Child, diaryLogToEdit: DiaryLog? = nil) {
        self.child = child
        self.diaryLogToEdit = diaryLogToEdit
        if let log = diaryLogToEdit {
            _activity = State(initialValue: log.activity)
            _activityType = State(initialValue: log.activityType)
            _mood = State(initialValue: log.mood)
            _napRecorded = State(initialValue: log.napRecorded)
            _napStart = State(initialValue: log.napStart)
            _napEnd = State(initialValue: log.napEnd)
            _sleepPosition = State(initialValue: log.sleepPosition)
            // Older entries (before nappyRecorded existed) should still show nappy controls.
            _nappyRecorded = State(initialValue: true)
            _nappyChanged = State(initialValue: log.nappyChanged)
            _nappyTime = State(initialValue: log.nappyTime ?? log.date)
            _nappyType = State(initialValue: log.nappyType)
            _nappyConcernNotes = State(initialValue: log.nappyConcernNotes)
            _meals = State(initialValue: log.meals)
        } else {
            _activity = State(initialValue: "")
            _activityType = State(initialValue: DiaryActivityType.freePlay)
            _mood = State(initialValue: "Happy")
            _napRecorded = State(initialValue: false)
            _napStart = State(initialValue: Date())
            _napEnd = State(initialValue: Date())
            _sleepPosition = State(initialValue: SleepPosition.unknown)
            _nappyRecorded = State(initialValue: false)
            _nappyChanged = State(initialValue: false)
            _nappyTime = State(initialValue: Date())
            _nappyType = State(initialValue: NappyToiletType.none)
            _nappyConcernNotes = State(initialValue: "")
            _meals = State(initialValue: [])
        }
    }

    private var isEditing: Bool { diaryLogToEdit != nil }

    var body: some View {
        Form {
            Section("Activity") {
                Picker("Type", selection: $activityType) {
                    Text(DiaryActivityType.indoorPlay).tag(DiaryActivityType.indoorPlay)
                    Text(DiaryActivityType.outdoorPlay).tag(DiaryActivityType.outdoorPlay)
                    Text(DiaryActivityType.reading).tag(DiaryActivityType.reading)
                    Text(DiaryActivityType.artsCrafts).tag(DiaryActivityType.artsCrafts)
                    Text(DiaryActivityType.educationalSession).tag(DiaryActivityType.educationalSession)
                    Text(DiaryActivityType.freePlay).tag(DiaryActivityType.freePlay)
                    Text(DiaryActivityType.restPeriod).tag(DiaryActivityType.restPeriod)
                }
                TextField("Activity", text: $activity)
            }

            Section("Mood & Nap") {
                Picker("Mood", selection: $mood) {
                    Text("Happy").tag("Happy")
                    Text("Sad").tag("Sad")
                    Text("Tired").tag("Tired")
                    Text("Unsettled").tag("Unsettled")
                    Text("Poorly").tag("Poorly")
                }

                Toggle("Add nap", isOn: $napRecorded)
                    .onChange(of: napRecorded) { _, newValue in
                        if !newValue {
                            let now = Date()
                            napStart = now
                            napEnd = now
                            sleepPosition = SleepPosition.unknown
                        }
                    }

                if napRecorded {
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

                    Picker("Sleep position", selection: $sleepPosition) {
                        Text(SleepPosition.onBack).tag(SleepPosition.onBack)
                        Text(SleepPosition.onSide).tag(SleepPosition.onSide)
                        Text(SleepPosition.onFront).tag(SleepPosition.onFront)
                        Text(SleepPosition.unknown).tag(SleepPosition.unknown)
                    }
                }
            }

            Section("Nappy / Toilet") {
                Toggle("Add nappy/toilet log", isOn: $nappyRecorded)
                    .onChange(of: nappyRecorded) { _, newValue in
                        if !newValue {
                            nappyChanged = false
                            nappyType = NappyToiletType.none
                            nappyConcernNotes = ""
                        }
                    }

                if nappyRecorded {
                    DatePicker("Time", selection: $nappyTime, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(.compact)

                    Picker("Type", selection: $nappyType) {
                        Text(NappyToiletType.wet).tag(NappyToiletType.wet)
                        Text(NappyToiletType.soiled).tag(NappyToiletType.soiled)
                        Text(NappyToiletType.toilet).tag(NappyToiletType.toilet)
                    }

                    Toggle("Change occurred", isOn: $nappyChanged)

                    TextField("Observations of concern (optional)", text: $nappyConcernNotes, axis: .vertical)
                        .lineLimit(2...4)
                        .onChange(of: nappyConcernNotes) { _, newValue in
                            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                showConcernAlert = true
                            }
                        }
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
        .alert("Concern noted", isPresented: $showConcernAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A concern note has been added. In a real nursery workflow, this could trigger an alert/escalation according to policy.")
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
        let normalizedNappyTime = timeOnSameDay(nappyTime, day: entryDay)
        let cleanedConcernNotes = nappyConcernNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        let cleanedMeals: [MealEntry] = meals.compactMap { meal in
            let trimmedNotes = meal.notes.trimmingCharacters(in: .whitespacesAndNewlines)
            return MealEntry(id: meal.id, type: meal.type, time: timeOnSameDay(meal.time, day: entryDay), notes: trimmedNotes)
        }

        var insertedLog: DiaryLog?

        if let editing = diaryLogToEdit {
            editing.activity = trimmedActivity
            editing.activityType = activityType
            editing.mood = mood
            editing.napRecorded = napRecorded
            editing.napStart = napRecorded ? normalizedNapStart : entryDay
            editing.napEnd = napRecorded ? normalizedNapEnd : entryDay
            editing.sleepPosition = napRecorded ? sleepPosition : SleepPosition.unknown
            editing.nappyRecorded = nappyRecorded
            editing.nappyChanged = nappyChanged
            editing.nappyTime = nappyRecorded ? normalizedNappyTime : nil
            editing.nappyType = nappyRecorded ? nappyType : NappyToiletType.none
            editing.nappyConcernNotes = nappyRecorded ? cleanedConcernNotes : ""
            editing.meals = cleanedMeals
            editing.childName = child.name
        } else {
            let newLog = DiaryLog(
                childName: child.name,
                activity: trimmedActivity,
                activityType: activityType,
                mood: mood,
                napRecorded: napRecorded,
                napStart: napRecorded ? normalizedNapStart : entryDay,
                napEnd: napRecorded ? normalizedNapEnd : entryDay,
                sleepPosition: napRecorded ? sleepPosition : SleepPosition.unknown,
                nappyRecorded: nappyRecorded,
                nappyChanged: nappyChanged,
                nappyTime: nappyRecorded ? normalizedNappyTime : nil,
                nappyType: nappyRecorded ? nappyType : NappyToiletType.none,
                nappyConcernNotes: nappyRecorded ? cleanedConcernNotes : "",
                meals: cleanedMeals,
                date: Date()
            )
            modelContext.insert(newLog)
            insertedLog = newLog
        }

        do {
            try modelContext.save()
            WatchSummarySync.publish(from: modelContext)
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
    .modelContainer(for: [Child.self, DiaryLog.self, Incident.self, AttendanceRecord.self, AuthorisedCollector.self, MoodCheckIn.self], inMemory: true)
}
