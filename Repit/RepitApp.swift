// Copyright (C) 2026 gsanz.dev
// Licensed under GNU GPL version 3 only, with the additional notice-preservation
// term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

import SwiftUI

@main
struct RepitApp: App {
    @State private var store = makeStore()
    @State private var library = makeLibraryStore()
    private static func makeLibraryStore() -> ExerciseLibraryStore {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            let url = URL.documentsDirectory.appending(path: "repit-exercises-uitests.json")
            if ProcessInfo.processInfo.arguments.contains("--reset-uitests") { try? FileManager.default.removeItem(at: url) }
            return ExerciseLibraryStore(fileURL: url)
        }
        #endif
        return ExerciseLibraryStore()
    }
    private static func makeStore() -> RoutineStore {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            let url = URL.documentsDirectory.appending(path: "repit-uitests.json")
            if ProcessInfo.processInfo.arguments.contains("--reset-uitests") { try? FileManager.default.removeItem(at: url) }
            return RoutineStore(fileURL: url)
        }
        #endif
        return RoutineStore()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(library)
                .environment(\.locale, L10n.locale)
                .tint(Theme.lime)
                .preferredColorScheme(.dark)
        }
    }
}
