import SwiftUI
import SwiftData

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            ChildListView(style: .phone)
                .navigationTitle("Little Stars Nursery")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        NavigationLink {
                            AttendanceRegisterView()
                        } label: {
                            Label("Register", systemImage: "checklist")
                        }
                        .accessibilityIdentifier("phone.attendanceRegister")
                    }
                }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Child.self, DiaryLog.self, Incident.self, AttendanceRecord.self], inMemory: true)
}
