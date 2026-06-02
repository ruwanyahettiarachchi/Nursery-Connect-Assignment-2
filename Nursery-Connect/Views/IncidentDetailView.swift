import SwiftUI
import SwiftData

struct IncidentDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let incident: Incident

    @State private var exportURL: URL?
    @State private var showExportSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                detailsCard
                workflowCard
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .background(NurseryTheme.pageBackground.ignoresSafeArea(edges: [.horizontal, .bottom]))
        .navigationTitle("Incident")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    exportURL = IncidentPDFExporter.export(incident: incident)
                    showExportSheet = exportURL != nil
                } label: {
                    Label("Export PDF", systemImage: "doc.richtext")
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Share PDF", systemImage: "square.and.arrow.up")
                        .font(.headline)
                }
                .presentationDetents([.medium])
                .padding()
            }
        }
    }

    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(incident.childName)
                    .font(.title2.weight(.semibold))
                Text(incident.date, format: .dateTime.weekday(.wide).day().month(.wide).hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(incident.category)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(NurseryTheme.incidentTint.opacity(0.18)))
                .foregroundStyle(NurseryTheme.incidentTint)
        }
        .nurseryCard()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Location: \(incident.location.isEmpty ? "—" : incident.location)", systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Label("Body: \(incident.bodyPart) • \(incident.bodyMapSide)\(incident.bodyMapRegion.isEmpty ? "" : " • \(incident.bodyMapRegion)")", systemImage: "figure")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider().opacity(0.35)

            Text("Description")
                .font(.headline)
            Text(incident.descriptionText)
                .font(.body)

            if !incident.immediateActionTaken.isEmpty {
                Divider().opacity(0.35)
                Text("Immediate action")
                    .font(.headline)
                Text(incident.immediateActionTaken)
                    .font(.body)
            }

            if !incident.witnesses.isEmpty {
                Divider().opacity(0.35)
                Text("Witnesses")
                    .font(.headline)
                Text(incident.witnesses.map(\.name).joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .nurseryCard()
    }

    private var workflowCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workflow")
                .font(.headline)

            workflowRow(
                title: "Manager countersignature",
                status: incident.isManagerSigned ? "Signed" : "Pending"
            )

            Divider().opacity(0.35)

            workflowRow(
                title: "Parent acknowledgement",
                status: incident.isParentAcknowledged ? "Acknowledged" : "Pending"
            )
            Text("This prototype records countersignature and acknowledgement as workflow states. Actions are handled in staff policy; here they’re displayed for traceability.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .nurseryCard()
    }

    private func workflowRow(title: String, status: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(status)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.secondary.opacity(0.14)))
        }
    }
}

#Preview {
    NavigationStack {
        IncidentDetailView(
            incident: Incident(
                childName: "Ava",
                date: Date(),
                category: IncidentCategory.accidentMinor,
                location: "Playground",
                descriptionText: "Minor bump while running.",
                bodyPart: "Head",
                bodyMapSide: BodyMapSide.front,
                bodyMapRegion: "Forehead",
                immediateActionTaken: "Applied ice pack",
                witnesses: [IncidentWitness(name: "Sam")],
                managerCountersignRequired: true
            )
        )
    }
    .modelContainer(for: [Child.self, DiaryLog.self, Incident.self, AttendanceRecord.self, AuthorisedCollector.self, MoodCheckIn.self], inMemory: true)
}

