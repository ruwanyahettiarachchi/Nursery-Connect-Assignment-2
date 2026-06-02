import SwiftUI
import SwiftData

struct AttendanceRegisterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Child.name) private var children: [Child]
    @Query(sort: \AttendanceRecord.date, order: .reverse) private var attendanceRecords: [AttendanceRecord]
    @Query(sort: \AuthorisedCollector.createdAt, order: .reverse) private var authorisedCollectors: [AuthorisedCollector]

    @State private var sheetRoute: SheetRoute?
    @State private var showUnknownCollectorAlert = false
    @State private var unknownCollectorMessage = ""

    private var viewModel: AttendanceRegisterViewModel {
        AttendanceRegisterViewModel(children: children, records: attendanceRecords)
    }

    private enum SheetRoute: Identifiable {
        case checkIn(Child)
        case checkOut(Child)

        var id: String {
            switch self {
            case .checkIn(let c): return "checkIn-\(c.name)"
            case .checkOut(let c): return "checkOut-\(c.name)"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                summaryCard

                if children.isEmpty {
                    emptyStateCard
                } else {
                    VStack(spacing: 12) {
                        ForEach(children) { child in
                            childAttendanceRow(child)
                        }
                    }
                }
            }
            .padding(.horizontal, NurseryTheme.horizontalPadding(for: horizontalSizeClass))
            .padding(.vertical, 16)
        }
        .background(NurseryTheme.pageBackground.ignoresSafeArea(edges: [.horizontal, .bottom]))
        .navigationTitle("Attendance Register")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            AttendanceSeedCleanup.removeSeededTodayRecordsIfNeeded(in: modelContext)
        }
        .sheet(item: $sheetRoute) { route in
            switch route {
            case .checkIn(let child):
                NavigationStack {
                    AttendanceCheckInSheet(
                        child: child,
                        authorisedCollectors: authorisedCollectors.filter { $0.childName == child.name },
                        existingRecord: viewModel.record(for: child),
                        onSave: { droppedOffByName, droppedOffByRelationship, staffName, notes, saveToAuthorisedList in
                            saveCheckIn(
                                child: child,
                                droppedOffByName: droppedOffByName,
                                droppedOffByRelationship: droppedOffByRelationship,
                                staffName: staffName,
                                notes: notes,
                                saveToAuthorisedList: saveToAuthorisedList
                            )
                        }
                    )
                    .tint(NurseryTheme.accent)
                }
            case .checkOut(let child):
                NavigationStack {
                    AttendanceCheckOutSheet(
                        child: child,
                        existingRecord: viewModel.record(for: child),
                        authorisedCollectors: authorisedCollectors.filter { $0.childName == child.name },
                        onSave: { collectorName, collectorRelationship, isAuthorised, staffName, notes in
                            if !isAuthorised {
                                unknownCollectorMessage = "Collector “\(collectorName)” is not in the authorised list for \(child.name). Please verify photo ID and follow nursery policy."
                                showUnknownCollectorAlert = true
                            }

                            saveCheckOut(
                                child: child,
                                collectorName: collectorName,
                                collectorRelationship: collectorRelationship,
                                isAuthorised: isAuthorised,
                                staffName: staffName,
                                notes: notes
                            )
                        }
                    )
                    .tint(NurseryTheme.accent)
                }
            }
        }
        .alert("Unknown collector", isPresented: $showUnknownCollectorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(unknownCollectorMessage)
        }
    }

    private var headerCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.title2)
                .foregroundStyle(NurseryTheme.mint)
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily register")
                    .font(.title2.weight(.semibold))
                Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .nurseryCard()
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            summaryItem(value: viewModel.presentCount, label: "Present", tint: NurseryTheme.mint)
            Divider().frame(height: 36)
            summaryItem(value: viewModel.signedOutCount, label: "Signed out", tint: NurseryTheme.diaryTint)
            Divider().frame(height: 36)
            summaryItem(value: viewModel.absentCount, label: "Absent", tint: NurseryTheme.incidentTint)
        }
        .nurseryCard()
    }

    private func summaryItem(value: Int, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.weight(.bold))
                .foregroundStyle(tint)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func childAttendanceRow(_ child: Child) -> some View {
        let status = viewModel.status(for: child)
        let record = viewModel.record(for: child)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: status.systemImage)
                    .font(.title3)
                    .foregroundStyle(statusColor(status))

                VStack(alignment: .leading, spacing: 4) {
                    Text(child.name)
                        .font(.headline)
                    Text(statusDetail(status, record: record))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                statusBadge(status)
            }

            HStack(spacing: 10) {
                attendanceButton(
                    title: "Sign In",
                    systemImage: "arrow.down.circle.fill",
                    tint: NurseryTheme.mint,
                    disabled: isSignInDisabled(status)
                ) {
                    sheetRoute = .checkIn(child)
                }

                attendanceButton(
                    title: "Sign Out",
                    systemImage: "arrow.up.circle.fill",
                    tint: NurseryTheme.diaryTint,
                    disabled: !canSignOut(status)
                ) {
                    sheetRoute = .checkOut(child)
                }

                attendanceButton(
                    title: "Absent",
                    systemImage: "xmark.circle.fill",
                    tint: NurseryTheme.incidentTint,
                    disabled: status == .absent
                ) {
                    markAbsent(child)
                }
            }
        }
        .padding(16)
        .nurseryCard()
        .accessibilityIdentifier("attendance.row.\(child.name)")
    }

    private func statusBadge(_ status: AttendanceStatus) -> some View {
        Text(status.label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(statusColor(status).opacity(0.18)))
            .foregroundStyle(statusColor(status))
    }

    private func statusColor(_ status: AttendanceStatus) -> Color {
        switch status {
        case .notRecorded: return .secondary
        case .signedIn: return NurseryTheme.mint
        case .signedOut: return NurseryTheme.diaryTint
        case .absent: return NurseryTheme.incidentTint
        }
    }

    private func statusDetail(_ status: AttendanceStatus, record: AttendanceRecord?) -> String {
        switch status {
        case .notRecorded:
            return "Awaiting arrival"
        case .signedIn(let since):
            return "Since \(since.formatted(date: .omitted, time: .shortened))"
        case .signedOut:
            guard let record, let signIn = record.signInTime, let signOut = record.signOutTime else {
                return "Left for the day"
            }
            return "\(signIn.formatted(date: .omitted, time: .shortened)) – \(signOut.formatted(date: .omitted, time: .shortened))"
        case .absent:
            return "Marked absent today"
        }
    }

    private func attendanceButton(
        title: String,
        systemImage: String,
        tint: Color,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(disabled ? 0.12 : 0.28))
                )
                .foregroundStyle(disabled ? .secondary : tint)
        }
        .buttonStyle(NurseryTapAnimationStyle())
        .disabled(disabled)
    }

    private var emptyStateCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 40))
                .foregroundStyle(NurseryTheme.accent.opacity(0.5))
            Text("No children to register")
                .font(.headline)
            Text("Add children to the dashboard before taking attendance.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .nurseryCard()
    }

    private func signIn(_ child: Child) {
        let today = AttendanceRegisterViewModel.startOfDay(for: Date())
        if let existing = viewModel.record(for: child) {
            existing.isAbsent = false
            existing.signInTime = Date()
            existing.signOutTime = nil
        } else {
            let record = AttendanceRecord(
                childName: child.name,
                date: today,
                signInTime: Date(),
                isAbsent: false
            )
            modelContext.insert(record)
        }
        try? modelContext.save()
        WatchSummarySync.publish(
            from: modelContext,
            attendanceAlert: WatchAttendanceAlert(
                message: "\(child.name) signed in",
                date: Date(),
                kind: "signIn"
            )
        )
    }

    private func signOut(_ child: Child) {
        guard let existing = viewModel.record(for: child) else { return }
        existing.signOutTime = Date()
        try? modelContext.save()
        WatchSummarySync.publish(
            from: modelContext,
            attendanceAlert: WatchAttendanceAlert(
                message: "\(child.name) signed out",
                date: Date(),
                kind: "signOut"
            )
        )
    }

    private func isSignInDisabled(_ status: AttendanceStatus) -> Bool {
        switch status {
        case .notRecorded: return false
        case .signedIn, .signedOut, .absent: return true
        }
    }

    private func canSignOut(_ status: AttendanceStatus) -> Bool {
        if case .signedIn = status { return true }
        return false
    }

    private func markAbsent(_ child: Child) {
        let today = AttendanceRegisterViewModel.startOfDay(for: Date())
        if let existing = viewModel.record(for: child) {
            existing.isAbsent = true
            existing.signInTime = nil
            existing.signOutTime = nil
        } else {
            let record = AttendanceRecord(
                childName: child.name,
                date: today,
                isAbsent: true
            )
            modelContext.insert(record)
        }
        try? modelContext.save()
        WatchSummarySync.publish(from: modelContext)
    }

    private func saveCheckIn(
        child: Child,
        droppedOffByName: String,
        droppedOffByRelationship: String,
        staffName: String,
        notes: String,
        saveToAuthorisedList: Bool
    ) {
        let today = AttendanceRegisterViewModel.startOfDay(for: Date())

        if let existing = viewModel.record(for: child) {
            existing.isAbsent = false
            existing.signInTime = Date()
            existing.signOutTime = nil
            existing.droppedOffByName = droppedOffByName
            existing.droppedOffByRelationship = droppedOffByRelationship
            existing.checkedInByStaffName = staffName
            existing.notes = notes
        } else {
            let record = AttendanceRecord(
                childName: child.name,
                date: today,
                signInTime: Date(),
                isAbsent: false,
                droppedOffByName: droppedOffByName,
                droppedOffByRelationship: droppedOffByRelationship,
                checkedInByStaffName: staffName,
                notes: notes
            )
            modelContext.insert(record)
        }

        if saveToAuthorisedList {
            let alreadyListed = authorisedCollectors.contains {
                $0.childName == child.name
                    && $0.name == droppedOffByName
                    && $0.relationship == droppedOffByRelationship
            }
            if !alreadyListed {
                modelContext.insert(
                    AuthorisedCollector(
                        childName: child.name,
                        name: droppedOffByName,
                        relationship: droppedOffByRelationship
                    )
                )
            }
        }

        try? modelContext.save()
        WatchSummarySync.publish(
            from: modelContext,
            attendanceAlert: WatchAttendanceAlert(
                message: "\(child.name) signed in",
                date: Date(),
                kind: "signIn"
            )
        )
        sheetRoute = nil
    }

    private func saveCheckOut(
        child: Child,
        collectorName: String,
        collectorRelationship: String,
        isAuthorised: Bool,
        staffName: String,
        notes: String
    ) {
        guard let existing = viewModel.record(for: child) else { return }

        existing.signOutTime = Date()
        existing.collectedByName = collectorName
        existing.collectedByRelationship = collectorRelationship
        existing.collectorWasAuthorised = isAuthorised
        existing.checkedOutByStaffName = staffName
        existing.notes = notes

        try? modelContext.save()
        WatchSummarySync.publish(
            from: modelContext,
            attendanceAlert: WatchAttendanceAlert(
                message: "\(child.name) signed out",
                date: Date(),
                kind: "signOut"
            )
        )
        sheetRoute = nil
    }
}

#Preview {
    NavigationStack {
        AttendanceRegisterView()
    }
    .modelContainer(for: [Child.self, DiaryLog.self, Incident.self, AttendanceRecord.self, AuthorisedCollector.self, MoodCheckIn.self], inMemory: true)
}
