import SwiftUI
import SwiftData

struct MoodCheckInsView: View {
    let child: Child

    @Environment(\.modelContext) private var modelContext
    @Query private var checkIns: [MoodCheckIn]

    @State private var arrivalMood: String = "Happy"
    @State private var arrivalNotes: String = ""
    @State private var middayMood: String = "Happy"
    @State private var middayNotes: String = ""
    @State private var departureMood: String = "Happy"
    @State private var departureNotes: String = ""

    init(child: Child) {
        self.child = child
        let childName = child.name
        _checkIns = Query(
            filter: #Predicate<MoodCheckIn> { $0.childName == childName },
            sort: \MoodCheckIn.date,
            order: .reverse
        )
    }

    var body: some View {
        Form {
            Section("Today") {
                moodEditor(title: MoodCheckInTimeOfDay.arrival, mood: $arrivalMood, notes: $arrivalNotes)
                moodEditor(title: MoodCheckInTimeOfDay.midday, mood: $middayMood, notes: $middayNotes)
                moodEditor(title: MoodCheckInTimeOfDay.departure, mood: $departureMood, notes: $departureNotes)

                Button {
                    saveToday()
                } label: {
                    Label("Save check-ins", systemImage: "checkmark.circle.fill")
                }
            }

            Section("Recent") {
                if checkIns.isEmpty {
                    ContentUnavailableView {
                        Label("No check-ins yet", systemImage: "face.smiling")
                    } description: {
                        Text("Record mood and wellbeing at arrival, midday, and departure.")
                    }
                } else {
                    ForEach(checkIns.prefix(9)) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(item.timeOfDay) • \(item.date.formatted(.dateTime.weekday().day().month()))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(item.mood)
                                .font(.headline)
                            if !item.notes.isEmpty {
                                Text(item.notes)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Mood check-ins")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadTodayIfExists)
    }

    private func moodEditor(title: String, mood: Binding<String>, notes: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Picker("Mood", selection: mood) {
                Text("Happy").tag("Happy")
                Text("Unsettled").tag("Unsettled")
                Text("Poorly").tag("Poorly")
                Text("Tired").tag("Tired")
                Text("Sad").tag("Sad")
            }
            TextField("Notes (optional)", text: notes, axis: .vertical)
                .lineLimit(2...4)
        }
        .padding(.vertical, 4)
    }

    private func loadTodayIfExists() {
        let today = Calendar.current.startOfDay(for: Date())
        let todays = checkIns.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }

        for item in todays {
            switch item.timeOfDay {
            case MoodCheckInTimeOfDay.arrival:
                arrivalMood = item.mood
                arrivalNotes = item.notes
            case MoodCheckInTimeOfDay.midday:
                middayMood = item.mood
                middayNotes = item.notes
            case MoodCheckInTimeOfDay.departure:
                departureMood = item.mood
                departureNotes = item.notes
            default:
                break
            }
        }
    }

    private func upsert(timeOfDay: String, mood: String, notes: String) {
        let today = Calendar.current.startOfDay(for: Date())
        if let existing = checkIns.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) && $0.timeOfDay == timeOfDay }) {
            existing.mood = mood
            existing.notes = notes
        } else {
            let item = MoodCheckIn(
                childName: child.name,
                date: today,
                timeOfDay: timeOfDay,
                mood: mood,
                notes: notes
            )
            modelContext.insert(item)
        }
    }

    private func saveToday() {
        upsert(timeOfDay: MoodCheckInTimeOfDay.arrival, mood: arrivalMood, notes: arrivalNotes.trimmingCharacters(in: .whitespacesAndNewlines))
        upsert(timeOfDay: MoodCheckInTimeOfDay.midday, mood: middayMood, notes: middayNotes.trimmingCharacters(in: .whitespacesAndNewlines))
        upsert(timeOfDay: MoodCheckInTimeOfDay.departure, mood: departureMood, notes: departureNotes.trimmingCharacters(in: .whitespacesAndNewlines))

        try? modelContext.save()
        WatchSummarySync.publish(from: modelContext)
    }
}

#Preview {
    NavigationStack {
        MoodCheckInsView(child: Child(name: "Ava", age: 3))
    }
    .modelContainer(for: [Child.self, DiaryLog.self, Incident.self, AttendanceRecord.self, AuthorisedCollector.self, MoodCheckIn.self], inMemory: true)
}

