// Copyright (C) 2026 gsanz.dev
// Licensed under GNU GPL version 3 only, with the additional notice-preservation
// term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

import Foundation
import Observation

@MainActor @Observable
final class ExerciseLibraryStore {
    private(set) var customExercises: [Exercise] = []
    var errorMessage: String?
    private let fileURL: URL
    private var canSave = true

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? URL.documentsDirectory.appending(path: "repit-exercises.json")
        do {
            if FileManager.default.fileExists(atPath: self.fileURL.path) {
                customExercises = try JSONDecoder().decode([Exercise].self, from: Data(contentsOf: self.fileURL))
            }
        } catch {
            canSave = false
            errorMessage = L10n.text("Your custom exercise library couldn’t be read. The original file is preserved. Reopen the app to try again.")
        }
    }

    var all: [CatalogExercise] {
        ExerciseCatalog.all + customExercises.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }.map {
            CatalogExercise(name: $0.name, muscle: $0.muscle, equipment: L10n.text("Custom"), videoURL: $0.videoURL, template: $0)
        }
    }

    var muscles: [String] {
        var result = ExerciseCatalog.muscles
        for exercise in customExercises {
            let category = ExerciseCatalog.canonicalMuscle(exercise.muscle, among: result)
            if !result.contains(where: { ExerciseCatalog.normalized($0) == ExerciseCatalog.normalized(category) }) { result.append(category) }
        }
        return result
    }

    func search(_ query: String, muscle: String = L10n.text("All")) -> [CatalogExercise] {
        ExerciseCatalog.search(query, muscle: muscle, in: all)
    }

    @discardableResult func saveCustom(_ exercise: Exercise) -> Bool {
        let name = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        if ExerciseCatalog.all.contains(where: { ExerciseCatalog.normalized($0.name) == ExerciseCatalog.normalized(name) }) { return true }
        guard canSave else {
            errorMessage = L10n.text("Your custom exercise library couldn’t be read. The original file is preserved. Reopen the app to try again.")
            return false
        }
        var entry = exercise
        entry.name = name
        entry.muscle = ExerciseCatalog.canonicalMuscle(exercise.muscle, among: muscles)
        var updated = customExercises
        if let index = updated.firstIndex(where: { ExerciseCatalog.normalized($0.name) == ExerciseCatalog.normalized(name) }) {
            entry.id = updated[index].id
            updated[index] = entry
        } else { updated.append(entry) }
        do {
            let data = try JSONEncoder().encode(updated)
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
            customExercises = updated
            return true
        } catch {
            errorMessage = L10n.text("Your custom exercise couldn’t be saved. Check available storage and try again.")
            return false
        }
    }
}
