import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.name) private var children: [Child]
    @State private var didAnimateListIn: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerBlock

                    if children.isEmpty {
                        emptyStateCard
                    } else {
                        VStack(spacing: 12) {
                            ForEach(children) { child in
                                NavigationLink {
                                    ChildDetailView(child: child)
                                } label: {
                                    childRow(child)
                                }
                                .accessibilityIdentifier("dashboard.child.\(child.name)")
                            }
                        }
                        .opacity(didAnimateListIn ? 1.0 : 0.0)
                        .offset(y: didAnimateListIn ? 0 : 12)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .background(NurseryTheme.pageBackground.ignoresSafeArea(edges: [.horizontal, .bottom]))
            .task {
                await seedSampleChildrenIfNeeded()
            }
            .navigationTitle("Little Stars Nursery")
            .onAppear {
                withAnimation(.easeOut(duration: 0.45)) {
                    didAnimateListIn = true
                }
            }
        }
    }

    @MainActor
    private func seedSampleChildrenIfNeeded() async {
        guard children.isEmpty else { return }

        let samples: [Child] = [
            Child(name: "Emma Brown", age: 3),
            Child(name: "Oliver Smith", age: 4),
            Child(name: "Mia Johnson", age: 2),
            Child(name: "Noah Williams", age: 5),
        ]

        for child in samples {
            modelContext.insert(child)
        }
        try? modelContext.save()
    }

    private var headerBlock: some View {
        HStack(spacing: 12) {
            Image(systemName: "sun.max.fill")
                .font(.title)
                .foregroundStyle(NurseryTheme.mint)
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Keyworker dashboard")
                    .font(.title3.weight(.semibold))
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .nurseryCard()
    }

    private func childRow(_ child: Child) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(NurseryTheme.accent.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(NurseryTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Label("\(child.age) years old", systemImage: "figure.child")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .nurseryCard()
    }

    private var emptyStateCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 40))
                .foregroundStyle(NurseryTheme.accent.opacity(0.5))
            Text("No children yet")
                .font(.headline)
            Text("Children you support will appear here for diary logs and incident reporting.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .nurseryCard()
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Child.self, DiaryLog.self, Incident.self], inMemory: true)
}
