//
//  ContentView.swift
//  Nursery-Connect
//
//  Created by ruwanya hettiarachchi on 2026-03-25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        DashboardView()
            .tint(NurseryTheme.accent)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Child.self, DiaryLog.self, Incident.self], inMemory: true)
}
