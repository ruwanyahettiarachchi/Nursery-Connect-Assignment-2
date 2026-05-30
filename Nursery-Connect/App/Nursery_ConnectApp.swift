//
//  Nursery_ConnectApp.swift
//  Nursery-Connect
//
//  Created by ruwanya hettiarachchi on 2026-03-25.
//

import SwiftUI
import SwiftData
import Foundation

// NurseryConnect processes special-category personal data (e.g. children's wellbeing). Under UK GDPR,
// such data falls within Article 9; handle it lawfully, proportionately, and in line with your policies.
// Persistence is on-device via SwiftData to prioritise privacy and local control of records.
// Diary and incident features align with EYFS expectations for recording daily experience and material events.

@main
struct Nursery_ConnectApp: App {
    /// Bump this when the persisted schema changes in a way that is not auto-migrated from older stores.
    private static let storeSchemaVersion = 2

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Child.self,
            DiaryLog.self,
            Incident.self,
        ])

        let supportDir = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)

        // Named store under Application Support — avoids loading the legacy default store after schema changes.
        let storeName = "NurseryConnect_v\(storeSchemaVersion)"
        let modelConfiguration = ModelConfiguration(
            storeName,
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Last resort: remove incompatible/corrupt store files for this configuration and try once.
            let storeURL = modelConfiguration.url
            try? FileManager.default.removeItem(at: storeURL)
            let shm = storeURL.appendingPathExtension("shm")
            let wal = storeURL.appendingPathExtension("wal")
            try? FileManager.default.removeItem(at: shm)
            try? FileManager.default.removeItem(at: wal)
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
