import SwiftUI
import SwiftData

private enum DetailTab: String, CaseIterable, Identifiable {
    case profile = "Profile"
    case analytics = "Analytics"

    var id: String { rawValue }
}

struct iPadRootView: View {
    @State private var selectedChild: Child?
    @State private var selectedTab: DetailTab = .profile
    @State private var showAttendanceRegister = false

    var body: some View {
        NavigationSplitView {
            ChildListView(style: .sidebar, selectedChild: $selectedChild)
                .navigationTitle("Little Stars Nursery")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            selectedChild = nil
                            showAttendanceRegister = true
                        } label: {
                            Label("Register", systemImage: "checklist")
                        }
                        .accessibilityIdentifier("ipad.attendanceRegister")
                    }
                }
        } detail: {
            detailContent
        }
        .onChange(of: selectedChild) { _, newValue in
            if newValue != nil {
                showAttendanceRegister = false
                selectedTab = .profile
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        if showAttendanceRegister {
            NavigationStack {
                AttendanceRegisterView()
            }
            .background(NurseryTheme.pageBackground.ignoresSafeArea())
        } else if let child = selectedChild {
            VStack(spacing: 0) {
                Picker("Detail section", selection: $selectedTab) {
                    ForEach(DetailTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)

                switch selectedTab {
                case .profile:
                    ChildDetailView(child: child)
                case .analytics:
                    NavigationStack {
                        AnalyticsView(child: child)
                    }
                }
            }
            .background(NurseryTheme.pageBackground.ignoresSafeArea())
        } else {
            selectChildPlaceholder
        }
    }

    private var selectChildPlaceholder: some View {
        ContentUnavailableView {
            Label("Select a child", systemImage: "person.crop.circle")
        } description: {
            Text("Choose a child from the sidebar to view their profile, diary logs, and analytics. Use Register for daily attendance.")
        } actions: {
            Button {
                showAttendanceRegister = true
            } label: {
                Label("Open attendance register", systemImage: "checklist")
            }
            .buttonStyle(.borderedProminent)
            .tint(NurseryTheme.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NurseryTheme.pageBackground.ignoresSafeArea())
        .accessibilityIdentifier("ipad.selectChildPlaceholder")
    }
}

#Preview {
    iPadRootView()
        .modelContainer(for: [Child.self, DiaryLog.self, Incident.self, AttendanceRecord.self], inMemory: true)
}
