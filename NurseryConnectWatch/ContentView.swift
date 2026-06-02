import SwiftUI
import WatchKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var sessionManager = WatchSessionManager.shared
    @State private var summary: WatchTodaySummary?
    @AppStorage("lastSeenAttendanceAlertTime") private var lastSeenAttendanceAlertTime: Double = 0
    @State private var showAttendanceBanner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let summary {
                        if showAttendanceBanner, let alert = summary.attendanceAlert {
                            attendanceBanner(alert)
                        }
                        summarySection(summary)
                        if !summary.recentIncidents.isEmpty {
                            recentIncidentsSection(summary.recentIncidents)
                        }
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("Today")
        }
        .onAppear(perform: reload)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                reload()
            }
        }
        .onReceive(sessionManager.$summary) { _ in
            reload()
        }
    }

    private func attendanceBanner(_ alert: WatchAttendanceAlert) -> some View {
        HStack(spacing: 8) {
            Image(systemName: alert.kind == "signIn" ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(alert.kind == "signIn" ? WatchTheme.accent : WatchTheme.diaryTint)
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.kind == "signIn" ? "Sign in" : "Sign out")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(alert.message)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(WatchTheme.accent.opacity(0.2)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(alert.message)
    }

    private func summarySection(_ summary: WatchTodaySummary) -> some View {
        VStack(spacing: 8) {
            statCard(
                value: "\(summary.studentsInNurseryToday)",
                label: "In nursery now",
                systemImage: "figure.2.and.child.holdinghands",
                tint: WatchTheme.accent
            )
            statCard(
                value: "\(summary.childrenCount)",
                label: "On roll",
                systemImage: "person.3.fill",
                tint: WatchTheme.accent.opacity(0.85)
            )
            statCard(
                value: "\(summary.diaryEntriesToday)",
                label: "Diary today",
                systemImage: "book.pages.fill",
                tint: WatchTheme.diaryTint
            )
            statCard(
                value: "\(summary.incidentsToday)",
                label: "Incidents today",
                systemImage: "exclamationmark.shield.fill",
                tint: WatchTheme.incidentTint
            )

            Text("Updated \(summary.updatedAt, style: .time)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
        }
    }

    private func recentIncidentsSection(_ incidents: [WatchRecentIncident]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent incidents")
                .font(.headline)
                .foregroundStyle(WatchTheme.incidentTint)

            ForEach(incidents) { incident in
                VStack(alignment: .leading, spacing: 4) {
                    Text(incident.childName)
                        .font(.body.weight(.semibold))
                    HStack {
                        Text(incident.bodyPart)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(WatchTheme.incidentTint.opacity(0.25)))
                        Spacer(minLength: 0)
                        Text(incident.date, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(.quaternary))
            }
        }
    }

    private func statCard(value: String, label: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2.weight(.bold))
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(.quaternary))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "applewatch")
                .font(.title)
                .foregroundStyle(WatchTheme.accent.opacity(0.6))
            Text("No summary yet")
                .font(.headline)
            Text("Open Nursery Connect on iPhone or iPad to sync today's glance.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 12)
    }

    private func reload() {
        let loaded = WatchSummaryStore.load()
        summary = loaded

        guard let alert = loaded?.attendanceAlert else {
            showAttendanceBanner = false
            return
        }

        let alertTime = alert.date.timeIntervalSince1970
        let isNew = alertTime > lastSeenAttendanceAlertTime
        showAttendanceBanner = Calendar.current.isDateInToday(alert.date)

        if isNew && showAttendanceBanner {
            lastSeenAttendanceAlertTime = alertTime
            WKInterfaceDevice.current().play(.notification)
        }
    }
}

#Preview {
    ContentView()
}
