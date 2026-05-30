import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \DiaryLog.date, order: .reverse) private var diaryLogs: [DiaryLog]
    @Query(sort: \Incident.date, order: .reverse) private var incidents: [Incident]
    @Query(sort: \AttendanceRecord.date, order: .reverse) private var attendanceRecords: [AttendanceRecord]

    let childFilter: String?

    init(child: Child? = nil) {
        self.childFilter = child?.name
    }

    private var viewModel: AnalyticsViewModel {
        AnalyticsViewModel(
            diaryLogs: diaryLogs,
            incidents: incidents,
            attendanceRecords: attendanceRecords,
            childFilter: childFilter
        )
    }

    private var hasAnyData: Bool {
        viewModel.hasDiaryData || viewModel.hasAttendanceData || !viewModel.bodyPartCounts.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerCard

                if !hasAnyData {
                    emptyStateCard
                }

                if viewModel.hasAttendanceData {
                    weeklyAttendanceChartCard
                    if !viewModel.childAttendanceFrequency.isEmpty {
                        childFrequencyChartCard
                    }
                }

                if viewModel.hasDiaryData {
                    moodChartCard
                    napTrendChartCard
                }

                if !viewModel.bodyPartCounts.isEmpty {
                    bodyPartChartCard
                }
            }
            .padding(.horizontal, NurseryTheme.horizontalPadding(for: horizontalSizeClass))
            .padding(.vertical, 16)
        }
        .background(NurseryTheme.pageBackground.ignoresSafeArea(edges: [.horizontal, .bottom]))
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title2)
                .foregroundStyle(NurseryTheme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Insights")
                    .font(.title2.weight(.semibold))
                if let childFilter {
                    Text("Showing data for \(childFilter)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Patterns across all children this week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .nurseryCard()
    }

    private var weeklyAttendanceChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            chartSectionTitle(
                childFilter == nil ? "Weekly attendance" : "Weekly attendance (days present)",
                systemImage: "calendar",
                tint: NurseryTheme.mint
            )

            Chart(viewModel.weeklyAttendance) { point in
                BarMark(
                    x: .value("Day", point.dayLabel),
                    y: .value("Present", point.presentCount)
                )
                .foregroundStyle(NurseryTheme.mint)
                .cornerRadius(6)
            }
            .frame(height: 220)
            .chartYAxisLabel(childFilter == nil ? "Children" : "Present")
            .accessibilityLabel("Weekly attendance bar chart")
            .accessibilityValue(weeklyAttendanceAccessibilitySummary)
        }
        .nurseryCard()
    }

    private var childFrequencyChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            chartSectionTitle(
                "Child attendance frequency",
                systemImage: "person.3.fill",
                tint: NurseryTheme.accent
            )

            Chart(viewModel.childAttendanceFrequency) { item in
                BarMark(
                    x: .value("Child", item.childName),
                    y: .value("Days", item.daysPresent)
                )
                .foregroundStyle(NurseryTheme.accent)
                .cornerRadius(6)
            }
            .frame(height: 220)
            .chartYAxisLabel("Days present")
            .accessibilityLabel("Child attendance frequency bar chart")
            .accessibilityValue(childFrequencyAccessibilitySummary)
        }
        .nurseryCard()
    }

    private var moodChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            chartSectionTitle("Mood this week", systemImage: "heart.fill", tint: NurseryTheme.accent)

            Chart(viewModel.moodCounts) { item in
                BarMark(
                    x: .value("Mood", item.mood),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(NurseryTheme.accent)
                .cornerRadius(6)
            }
            .frame(height: 220)
            .chartYAxisLabel("Entries")
            .accessibilityLabel("Mood this week bar chart")
            .accessibilityValue(moodChartAccessibilitySummary)
        }
        .nurseryCard()
    }

    private var napTrendChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            chartSectionTitle("Nap duration trend", systemImage: "moon.zzz.fill", tint: NurseryTheme.diaryTint)

            Chart(viewModel.napTrend) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Minutes", point.minutes)
                )
                .foregroundStyle(NurseryTheme.diaryTint)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Minutes", point.minutes)
                )
                .foregroundStyle(NurseryTheme.diaryTint)
            }
            .frame(height: 220)
            .chartYAxisLabel("Minutes")
            .accessibilityLabel("Nap duration trend line chart")
            .accessibilityValue(napChartAccessibilitySummary)
        }
        .nurseryCard()
    }

    private var bodyPartChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            chartSectionTitle("Incidents by body part", systemImage: "bandage.fill", tint: NurseryTheme.incidentTint)

            Chart(viewModel.bodyPartCounts) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Body part", item.bodyPart))
                .cornerRadius(4)
            }
            .frame(height: 220)
            .chartForegroundStyleScale(bodyPartColorScale)
            .accessibilityLabel("Incidents by body part chart")
            .accessibilityValue(bodyPartChartAccessibilitySummary)
        }
        .nurseryCard()
    }

    private var emptyStateCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(NurseryTheme.accent.opacity(0.5))
            Text("No trends yet")
                .font(.headline)
            Text("Log diary entries or take attendance to see trends")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .nurseryCard()
        .accessibilityIdentifier("analytics.emptyState")
    }

    private func chartSectionTitle(_ title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
            Text(title)
                .font(.headline)
        }
    }

    private var bodyPartColorScale: KeyValuePairs<String, Color> {
        [
            "Head": NurseryTheme.incidentTint,
            "Arm": NurseryTheme.sunshine,
            "Leg": NurseryTheme.mint,
            "Torso": NurseryTheme.diaryTint,
            "Hand": NurseryTheme.accent,
            "Foot": NurseryTheme.accent.opacity(0.7),
        ]
    }

    private var weeklyAttendanceAccessibilitySummary: String {
        viewModel.weeklyAttendance
            .map { "\($0.dayLabel): \($0.presentCount)" }
            .joined(separator: ", ")
    }

    private var childFrequencyAccessibilitySummary: String {
        viewModel.childAttendanceFrequency
            .map { "\($0.childName): \($0.daysPresent) days" }
            .joined(separator: ", ")
    }

    private var moodChartAccessibilitySummary: String {
        viewModel.moodCounts
            .map { "\($0.mood): \($0.count)" }
            .joined(separator: ", ")
    }

    private var napChartAccessibilitySummary: String {
        viewModel.napTrend
            .map { "\($0.minutes) minutes" }
            .joined(separator: ", ")
    }

    private var bodyPartChartAccessibilitySummary: String {
        viewModel.bodyPartCounts
            .map { "\($0.bodyPart): \($0.count)" }
            .joined(separator: ", ")
    }
}

#Preview {
    NavigationStack {
        AnalyticsView()
    }
    .modelContainer(for: [Child.self, DiaryLog.self, Incident.self, AttendanceRecord.self], inMemory: true)
}
