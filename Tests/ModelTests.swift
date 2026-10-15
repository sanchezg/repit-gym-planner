// Copyright (C) 2026 gsanz.dev
// Licensed under GNU GPL version 3 only, with the additional notice-preservation
// term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

import Foundation

@main struct ModelTests {
    @MainActor static func main() throws {
        let temp = FileManager.default.temporaryDirectory.appending(path: "repit-tests-\(UUID())")
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }
        let file = temp.appending(path: "routines.json")
        let store = RoutineStore(fileURL: file)
        precondition(store.routines.isEmpty)
        var routine = Routine.example(day: .friday)
        precondition(store.save(routine))
        precondition(RoutineStore(fileURL: file).routines == [routine], "Must survive a restart")
        routine.name = "Updated"
        routine.blocks[0].exercises[0].weight = 22.5
        precondition(store.save(routine))
        precondition(store.routines.count == 1, "Editing must replace the routine")
        precondition(RoutineStore(fileURL: file).routines[0].blocks[0].exercises[0].weight == 22.5)
        var copy = routine; copy.id = UUID(); copy.day = .monday
        precondition(store.save(copy) && store.routines.count == 2)
        precondition(store.delete(routine))
        precondition(RoutineStore(fileURL: file).routines == [copy])
        let corrupted = temp.appending(path: "corrupted.json")
        let original = Data("broken data".utf8)
        try original.write(to: corrupted)
        let broken = RoutineStore(fileURL: corrupted)
        precondition(broken.errorMessage != nil)
        precondition(!broken.save(routine))
        let preserved = try Data(contentsOf: corrupted)
        precondition(preserved == original, "A failed load must never overwrite existing data")
        let impossible = RoutineStore(fileURL: file.appending(path: "child.json"))
        precondition(!impossible.save(routine))
        precondition(impossible.routines.isEmpty, "Failed writes must not change in-memory data")
        let extensionQuery = L10n.text("Triceps extension").folding(options: .diacriticInsensitive, locale: L10n.locale)
        precondition(ExerciseCatalog.search(extensionQuery).contains { $0.name == L10n.text("Triceps extension") })
        precondition(ExerciseCatalog.search(L10n.text("Barbell").uppercased(), muscle: L10n.text("Back")).count == 2)
        precondition(ExerciseCatalog.search("unknown").isEmpty)
        precondition(Exercise.youtubeURL("https://youtu.be/abc123") != nil)
        precondition(Exercise.youtubeURL("https://www.youtube.com/watch?v=abc123") != nil)
        precondition(Exercise.youtubeURL("https://youtube.com/shorts/abc123") != nil)
        for bad in ["javascript:alert(1)", "https://youtube.com.evil.com/watch?v=x", "http://youtube.com/watch?v=x", "https://youtube.com/", "https://youtube.com/watch?v=", "https://youtu.be/"] {
            precondition(Exercise.youtubeURL(bad) == nil, "Invalid video URL accepted: \(bad)")
        }
        let manual = Exercise(name: "Press & curl + shoulders")
        let query = URLComponents(url: manual.demonstrationURL, resolvingAgainstBaseURL: false)!.queryItems!.first!.value!
        precondition(query.contains("Press & curl + shoulders"), "Search names must be URL-encoded")
        let block = WorkoutBlock(name: "Tabata", kind: .tabata, rounds: 8, workSeconds: 20, restSeconds: 10, exercises: [Exercise(name: "A"), Exercise(name: "B")])
        precondition(block.tabataDuration == 240)
        precondition(IntervalState.at(elapsed: 0, block: block) == IntervalState(round: 1, resting: false, remaining: 20, exerciseIndex: 0, finished: false))
        precondition(IntervalState.at(elapsed: 20, block: block).resting)
        precondition(IntervalState.at(elapsed: 20, block: block).remaining == 10)
        precondition(IntervalState.at(elapsed: 30, block: block).exerciseIndex == 1)
        precondition(IntervalState.at(elapsed: 60, block: block).exerciseIndex == 0)
        precondition(!IntervalState.at(elapsed: 239, block: block).finished)
        precondition(IntervalState.at(elapsed: 240, block: block).finished)
        var noRest = block; noRest.restSeconds = 0
        precondition(!IntervalState.at(elapsed: 20, block: noRest).resting)
        precondition(IntervalState.at(elapsed: 160, block: noRest).finished)
        let circuit = WorkoutBlock(name: "Circuit", kind: .circuit, rounds: 3, exercises: [Exercise(name: "A", sets: 2), Exercise(name: "B", sets: 3)])
        precondition(Routine(name: "Test", day: .monday, blocks: [circuit, block]).setCount == 23)
        precondition(Routine(name: "Empty", day: .monday, blocks: [WorkoutBlock(kind: .tabata)]).setCount == 0)
        precondition(L10n.text("Monday") != "Monday", "Spanish resources must be bundled")
        precondition(Weekday.monday.short == String(Weekday.monday.title.prefix(1)))
        precondition(WorkoutBlock().name == L10n.text("Strength block"))
        for kind in BlockKind.allCases {
            let legacyValue = try JSONEncoder().encode(kind.title)
            let decoded = try JSONDecoder().decode(BlockKind.self, from: legacyValue)
            precondition(decoded == kind, "Previously saved block kinds must remain readable")
            let encoded = try JSONEncoder().encode(decoded)
            let storedValue = try JSONDecoder().decode(String.self, from: encoded)
            precondition(storedValue == kind.rawValue, "New saves must use English identifiers")
        }
        print("All model checks passed: persistence, edits, deletion, corruption protection, failed writes, catalog search, video URLs, Tabata boundaries, circuit totals.")
    }
}
