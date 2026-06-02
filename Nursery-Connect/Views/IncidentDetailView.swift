import SwiftUI
import SwiftData

struct IncidentDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let incident: Incident

    @State private var exportURL: URL?
    @State private var showExportSheet = false
    @State private var signingRoute: SigningRoute?

    enum SigningRoute: Identifiable {
        case manager
        case parent

        var id: String {
            switch self {
            case .manager: return "manager"
            case .parent: return "parent"
            }
        }
    }

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
        .sheet(item: $signingRoute) { route in
            switch route {
            case .manager:
                ManagerSigningSheet(incident: incident)
            case .parent:
                ParentSigningSheet(incident: incident)
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Safeguarding & Workflow Sign-off")
                .font(.headline)
                .foregroundStyle(NurseryTheme.accent)

            // Manager Countersignature Row
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Manager Countersignature", systemImage: "signature")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(incident.isManagerSigned ? "Signed" : "Required")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(incident.isManagerSigned ? NurseryTheme.mint.opacity(0.15) : NurseryTheme.incidentTint.opacity(0.15)))
                        .foregroundStyle(incident.isManagerSigned ? NurseryTheme.mint : NurseryTheme.incidentTint)
                }

                if let signDate = incident.managerSignedAt {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Countersigned by \(incident.managerSignedByName) on \(signDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let signData = incident.managerSignatureData, let uiImage = UIImage(data: signData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                                .padding(6)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.1)))
                        }
                    }
                } else {
                    Button {
                        signingRoute = .manager
                    } label: {
                        Label("Manager Countersign", systemImage: "pencil.and.outline")
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 10).fill(NurseryTheme.accent.opacity(0.15)))
                            .foregroundStyle(NurseryTheme.accent)
                    }
                    .buttonStyle(NurseryTapAnimationStyle())
                }
            }

            Divider().opacity(0.35)

            // Parent Acknowledgment Row
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Parent Acknowledgment", systemImage: "person.crop.circle.badge.checkmark")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(incident.isParentAcknowledged ? "Acknowledged" : "Pending")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(incident.isParentAcknowledged ? NurseryTheme.mint.opacity(0.15) : NurseryTheme.diaryTint.opacity(0.15)))
                        .foregroundStyle(incident.isParentAcknowledged ? NurseryTheme.mint : NurseryTheme.diaryTint)
                }

                if let ackDate = incident.parentAcknowledgedAt {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Acknowledged on \(ackDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let signData = incident.parentSignatureData, let uiImage = UIImage(data: signData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                                .padding(6)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.1)))
                        }
                    }
                } else {
                    Button {
                        signingRoute = .parent
                    } label: {
                        Label("Parent Acknowledge", systemImage: "pencil.and.outline")
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 10).fill(NurseryTheme.diaryTint.opacity(0.15)))
                            .foregroundStyle(NurseryTheme.diaryTint)
                    }
                    .buttonStyle(NurseryTapAnimationStyle())
                }
            }

            Divider().opacity(0.35)

            Text("Countersignatures and parent acknowledgments are legally required under EYFS safeguarding standards to ensure clear communication of material minor and major events.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .nurseryCard()
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

