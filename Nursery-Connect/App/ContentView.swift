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
            WatchSummarySync.publish(from: modelContext)
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
