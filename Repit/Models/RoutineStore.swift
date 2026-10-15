// Copyright (C) 2026 gsanz.dev
// Licensed under GNU GPL version 3 only, with the additional notice-preservation
// term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

import Foundation
import Observation

@MainActor @Observable
final class RoutineStore {
    private(set) var routines: [Routine] = []
    var errorMessage: String?
    private let fileURL: URL
    private var canSave = true

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? URL.documentsDirectory.appending(path: "repit-routines.json")
        do {
            if FileManager.default.fileExists(atPath: self.fileURL.path) {
                routines = try JSONDecoder().decode([Routine].self, from: Data(contentsOf: self.fileURL))
            }
        } catch {
            canSave = false
            errorMessage = L10n.text("We couldn’t read your routines. The original file is preserved. Reopen the app to try again.")
        }
    }

    @discardableResult func save(_ routine: Routine) -> Bool {
        var updated = routines
        if let index = updated.firstIndex(where: { $0.id == routine.id }) { updated[index] = routine }
        else { updated.append(routine) }
        return persist(updated)
    }

    @discardableResult func delete(_ routine: Routine) -> Bool {
        persist(routines.filter { $0.id != routine.id })
    }

    private func persist(_ updated: [Routine]) -> Bool {
        guard canSave else {
            errorMessage = L10n.text("The routine file couldn’t be read. Close and reopen the app to retry before saving changes.")
            return false
        }
        do {
            let data = try JSONEncoder().encode(updated)
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
            routines = updated
            return true
        } catch {
            errorMessage = L10n.text("Changes couldn’t be saved. Check available storage and try again.")
            return false
        }
    }
}
