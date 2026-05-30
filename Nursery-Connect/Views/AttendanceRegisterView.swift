import SwiftUI
import SwiftData

struct AttendanceRegisterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Child.name) private var children: [Child]
    @Query(sort: \AttendanceRecord.date, order: .reverse) private var attendanceRecords: [AttendanceRecord]

    private var viewModel: AttendanceRegisterViewModel {
        AttendanceRegisterViewModel(children: children, records: attendanceRecords)
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
                    signIn(child)
                }

                attendanceButton(
                    title: "Sign Out",
                    systemImage: "arrow.up.circle.fill",
                    tint: NurseryTheme.diaryTint,
                    disabled: !canSignOut(status)
                ) {
                    signOut(child)
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
    }

    private func signOut(_ child: Child) {
        guard let existing = viewModel.record(for: child) else { return }
        existing.signOutTime = Date()
        try? modelContext.save()
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
    }
}

#Preview {
    NavigationStack {
        AttendanceRegisterView()
    }
    .modelContainer(for: [Child.self, DiaryLog.self, Incident.self, AttendanceRecord.self], inMemory: true)
}
