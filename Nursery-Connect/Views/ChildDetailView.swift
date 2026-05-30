import SwiftUI
import SwiftData

struct ChildDetailView: View {
    let child: Child

    @Environment(\.modelContext) private var modelContext
    @Query private var diaryLogs: [DiaryLog]
    @Query private var incidents: [Incident]

    private enum SheetRoute: Identifiable {
        case addDiary
        case editDiary(DiaryLog)
        case addIncident
        case editIncident(Incident)

        var id: String {
            switch self {
            case .addDiary:
                return "addDiary"
            case .editDiary(let log):
                return "editDiary-\(ObjectIdentifier(log))"
            case .addIncident:
                return "addIncident"
            case .editIncident(let incident):
                return "editIncident-\(ObjectIdentifier(incident))"
            }
        }
    }

    @State private var sheetRoute: SheetRoute?
    @State private var didAnimateListIn: Bool = false

    @State private var diaryLogPendingDelete: DiaryLog?
    @State private var showDeleteDiaryConfirmation = false

    @State private var incidentPendingDelete: Incident?
    @State private var showDeleteIncidentConfirmation = false

    init(child: Child) {
        self.child = child
        let childName = child.name
        _diaryLogs = Query(
            filter: #Predicate<DiaryLog> { log in
                log.childName == childName
            },
            sort: \DiaryLog.date,
            order: .reverse
        )
        _incidents = Query(
            filter: #Predicate<Incident> { incident in
                incident.childName == childName
            },
            sort: \Incident.date,
            order: .reverse
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard

                diarySectionCard

                incidentSectionCard
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .padding(.bottom, 8)
            .opacity(didAnimateListIn ? 1.0 : 0.0)
            .offset(y: didAnimateListIn ? 0 : 10)
        }
        // Do not extend background under the nav bar — full-screen ignoresSafeArea can block the back button.
        .background(NurseryTheme.pageBackground.ignoresSafeArea(edges: [.horizontal, .bottom]))
        .navigationTitle(child.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                didAnimateListIn = true
            }
        }
        .sheet(item: $sheetRoute) { route in
            NavigationStack {
                Group {
                    switch route {
                    case .addDiary:
                        AddDiaryView(child: child)
                    case .editDiary(let log):
                        AddDiaryView(child: child, diaryLogToEdit: log)
                    case .addIncident:
                        AddIncidentView(child: child)
                    case .editIncident(let incident):
                        AddIncidentView(child: child, incidentToEdit: incident)
                    }
                }
                .tint(NurseryTheme.accent)
            }
            .presentationDragIndicator(.visible)
        }
        .alert("Delete diary entry?", isPresented: $showDeleteDiaryConfirmation) {
            Button("Cancel", role: .cancel) {
                diaryLogPendingDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let log = diaryLogPendingDelete {
                    modelContext.delete(log)
                    try? modelContext.save()
                }
                diaryLogPendingDelete = nil
            }
        } message: {
            Text("This will permanently remove this diary entry from the device.")
        }
        .alert("Delete incident report?", isPresented: $showDeleteIncidentConfirmation) {
            Button("Cancel", role: .cancel) {
                incidentPendingDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let incident = incidentPendingDelete {
                    modelContext.delete(incident)
                    try? modelContext.save()
                }
                incidentPendingDelete = nil
            }
        } message: {
            Text("This will permanently remove this incident from the device.")
        }
    }

    private var headerCard: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [NurseryTheme.accent.opacity(0.35), NurseryTheme.mint.opacity(0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(NurseryTheme.accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(child.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Label {
                    Text("\(child.age) years old")
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "figure.child")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .nurseryCard()
    }

    private var diarySectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Daily Diary Logs",
                systemImage: "book.pages.fill",
                tint: NurseryTheme.diaryTint
            )

            if diaryLogs.isEmpty {
                emptyPlaceholder(
                    title: "No diary entries yet",
                    subtitle: "Tap below to record activities, mood, and rest.",
                    systemImage: "book.closed.fill"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(diaryLogs) { log in
                        diaryEntryRow(log)
                    }
                }
            }

            Button {
                sheetRoute = .addDiary
            } label: {
                Label("Add Diary Entry", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [NurseryTheme.diaryTint.opacity(0.35), NurseryTheme.mint.opacity(0.4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(NurseryTapAnimationStyle())
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .nurseryCard()
    }

    private var incidentSectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Incident Reports",
                systemImage: "exclamationmark.shield.fill",
                tint: NurseryTheme.incidentTint
            )

            if incidents.isEmpty {
                emptyPlaceholder(
                    title: "No incidents reported",
                    subtitle: "Record any bumps or concerns when they happen.",
                    systemImage: "checkmark.shield.fill"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(incidents) { incident in
                        incidentRow(incident)
                    }
                }
            }

            Button {
                sheetRoute = .addIncident
            } label: {
                Label("Add Incident", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [NurseryTheme.incidentTint.opacity(0.85), NurseryTheme.sunshine.opacity(0.75)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(NurseryTapAnimationStyle())
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityIdentifier("detail.addIncident")
        }
        .nurseryCard()
    }

    private func sectionHeader(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }

    private func emptyPlaceholder(title: String, subtitle: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(NurseryTheme.accent.opacity(0.45))
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func diaryEntryRow(_ log: DiaryLog) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: moodSymbol(for: log.mood))
                    .font(.title3)
                    .foregroundStyle(NurseryTheme.diaryTint)
                    .frame(width: 28, alignment: .center)

                VStack(alignment: .leading, spacing: 6) {
                    Text(log.activity)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Label(log.mood, systemImage: "heart.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(NurseryTheme.accent)
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Label {
                            Text(log.date, style: .date)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                Menu {
                    Button("Edit", systemImage: "pencil") {
                        sheetRoute = .editDiary(log)
                    }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        diaryLogPendingDelete = log
                        showDeleteDiaryConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(NurseryTheme.accent.opacity(0.85))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
            }

            Divider()
                .opacity(0.35)

            HStack(spacing: 12) {
                Label {
                    Text("\(log.napStart, style: .time) – \(log.napEnd, style: .time)")
                } icon: {
                    Image(systemName: "moon.zzz.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("(\(log.napDurationMinutes) min)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                if log.nappyRecorded {
                    Label(
                        log.nappyChanged ? "Nappy changed" : "No change",
                        systemImage: log.nappyChanged ? "checkmark.circle.fill" : "circle"
                    )
                    .font(.caption)
                    .foregroundStyle(log.nappyChanged ? NurseryTheme.mint : .secondary)
                }
            }

            if !log.meals.isEmpty {
                let types = Array(Set(log.meals.map(\.type))).sorted().joined(separator: ", ")
                Label("\(log.meals.count) meal\(log.meals.count == 1 ? "" : "s") • \(types)", systemImage: "fork.knife")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.65))
        )
    }

    private func incidentRow(_ incident: Incident) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "bandage.fill")
                    .font(.title3)
                    .foregroundStyle(NurseryTheme.incidentTint)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(incident.bodyPart)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(NurseryTheme.incidentTint.opacity(0.22))
                            )
                            .foregroundStyle(.primary)

                        Spacer(minLength: 0)

                        Label {
                            HStack(spacing: 4) {
                                Text(incident.date, style: .date)
                                Text("·")
                                    .foregroundStyle(.tertiary)
                                Text(incident.date, style: .time)
                            }
                        } icon: {
                            Image(systemName: "clock.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Menu {
                            Button("Edit", systemImage: "pencil") {
                                sheetRoute = .editIncident(incident)
                            }
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                incidentPendingDelete = incident
                                showDeleteIncidentConfirmation = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                                .foregroundStyle(NurseryTheme.incidentTint.opacity(0.9))
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                    }

                    Text(incident.descriptionText)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.65))
        )
    }

    private func moodSymbol(for mood: String) -> String {
        switch mood {
        case "Happy": return "face.smiling.fill"
        case "Sad": return "cloud.rain.fill"
        case "Tired": return "bed.double.fill"
        default: return "leaf.fill"
        }
    }
}

#Preview {
    NavigationStack {
        ChildDetailView(child: Child(name: "Ava", age: 3))
    }
    .modelContainer(for: [Child.self, DiaryLog.self, Incident.self], inMemory: true)
}
