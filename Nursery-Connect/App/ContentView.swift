//
//  ContentView.swift
//  Nursery-Connect
//
//  Created by ruwanya hettiarachchi on 2026-03-25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadRootView()
            } else {
                DashboardView()
            }
        }
        .tint(NurseryTheme.accent)
        .task {
            WatchSessionManager.shared.activate()
            WatchSummarySync.publish(from: modelContext)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                WatchSummarySync.publish(from: modelContext)
            }
        }
    }
}

#Preview("iPhone") {
    ContentView()
        .modelContainer(for: [Child.self, DiaryLog.self, Incident.self, AttendanceRecord.self], inMemory: true)
}

#Preview("iPad") {
    ContentView()
        .modelContainer(for: [Child.self, DiaryLog.self, Incident.self, AttendanceRecord.self], inMemory: true)
}
