// Copyright (C) 2026 gsanz.dev
// Licensed under GNU GPL version 3 only, with the additional notice-preservation
// term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

import SwiftUI

struct RoutineEditor: View {
    @Environment(RoutineStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var routine: Routine
    @State private var blockEditor: WorkoutBlock?
    @State private var confirmDiscard = false
    @State private var original: Routine?
    @State private var saveFailure: String?
    private var valid: Bool { !routine.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.text("Your routine")) {
                    TextField(L10n.text("Name, for example: Upper body"), text: $routine.name).accessibilityIdentifier("routineName")
                    Picker(L10n.text("Day"), selection: $routine.day) { ForEach(Weekday.allCases) { Text($0.title).tag($0) } }
                }
                Section {
                    ForEach(routine.blocks) { block in
                        Button { blockEditor = block } label: {
                            HStack(spacing: 12) {
                                Image(systemName: block.kind.symbol).foregroundStyle(Theme.lime).frame(width: 28)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(block.name).foregroundStyle(.primary)
                                    Text(L10n.text("%ld exercises · %@", block.exercises.count, block.kind.title)).font(.caption).foregroundStyle(Theme.muted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.muted)
                            }.padding(.vertical, 6)
                        }
                    }.onDelete { routine.blocks.remove(atOffsets: $0) }
                        .onMove { routine.blocks.move(fromOffsets: $0, toOffset: $1) }
                    Button { blockEditor = WorkoutBlock(name: L10n.text("Block %ld", routine.blocks.count + 1)) } label: { Label(L10n.text("Add block"), systemImage: "plus") }.accessibilityIdentifier("addBlock")
                } header: { Text(L10n.text("Blocks")) } footer: {
                    Text(L10n.text("Group your exercises into sets, circuits, or Tabata. Swipe to delete and use Edit to reorder."))
                }
            }
            .scrollContentBackground(.hidden).background(Theme.background)
            .navigationTitle(original?.name.isEmpty == false ? L10n.text("Edit routine") : L10n.text("New routine"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("Cancel")) { if routine == original { dismiss() } else { confirmDiscard = true } }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("Save")) {
                        routine.name = routine.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if store.save(routine) { dismiss() }
                        else { saveFailure = store.errorMessage; store.errorMessage = nil }
                    }.fontWeight(.bold).disabled(!valid).accessibilityIdentifier("saveRoutine")
                }
                ToolbarItem(placement: .bottomBar) { EditButton().disabled(routine.blocks.isEmpty) }
            }
            .sheet(item: $blockEditor) { block in
                BlockEditor(block: block) { updated in
                    if let index = routine.blocks.firstIndex(where: { $0.id == updated.id }) { routine.blocks[index] = updated }
                    else { routine.blocks.append(updated) }
                }
            }
            .confirmationDialog(L10n.text("Discard changes?"), isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button(L10n.text("Discard changes"), role: .destructive) { dismiss() }
            }
            .interactiveDismissDisabled(routine != original)
            .alert(L10n.text("Unable to save"), isPresented: Binding(get: { saveFailure != nil }, set: { if !$0 { saveFailure = nil } })) {
                Button(L10n.text("Got it"), role: .cancel) { saveFailure = nil }
            } message: { Text(saveFailure ?? "") }
            .onAppear { if original == nil { original = routine } }
        }
    }
}

struct BlockEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var block: WorkoutBlock
    let onSave: (WorkoutBlock) -> Void
    @State private var exerciseEditor: Exercise?
    @State private var original: WorkoutBlock?
    @State private var confirmDiscard = false

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.text("Block")) {
                    TextField(L10n.text("Block name"), text: $block.name)
                    Picker(L10n.text("Format"), selection: $block.kind) { ForEach(BlockKind.allCases) { Text($0.title).tag($0) } }.pickerStyle(.segmented)
                }
                if block.kind != .standard {
                    Section {
                        Stepper(L10n.text("%ld %@", block.rounds, block.kind == .tabata ? L10n.text("intervals") : L10n.text("rounds")), value: $block.rounds, in: 1...50)
                        if block.kind == .tabata {
                            Stepper(L10n.text("Work: %ld s", block.workSeconds), value: $block.workSeconds, in: 5...180, step: 5)
                            Stepper(L10n.text("Rest: %ld s", block.restSeconds), value: $block.restSeconds, in: 0...120, step: 5)
                            LabeledContent(L10n.text("Duration"), value: "\(block.tabataDuration / 60) min \(block.tabataDuration % 60) s")
                        }
                    } header: { Text(block.kind.title) } footer: {
                        Text(block.kind == .tabata ? L10n.text("One exercise per interval, alternating in order. Sets and repetitions are not used by the timer. Includes the final interval’s rest.") : L10n.text("Each round includes all exercises with their sets and repetitions."))
                    }
                }
                Section {
                    ForEach(block.exercises) { exercise in
                        Button { exerciseEditor = exercise } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(exercise.name).foregroundStyle(.primary)
                                Text(exercise.prescriptionLabel).font(.caption).foregroundStyle(Theme.muted)
                            }.padding(.vertical, 6)
                        }
                    }.onDelete { block.exercises.remove(atOffsets: $0) }
                        .onMove { block.exercises.move(fromOffsets: $0, toOffset: $1) }
                    Button { exerciseEditor = Exercise(name: "") } label: { Label(L10n.text("Add exercise"), systemImage: "plus") }.accessibilityIdentifier("addExercise")
                } header: { Text(L10n.text("Exercises")) } footer: { Text(L10n.text("Tap an exercise to edit it. Swipe to delete.")) }
            }.scrollContentBackground(.hidden).background(Theme.background)
                .navigationTitle(L10n.text("Edit block")).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.text("Cancel")) { if block == original { dismiss() } else { confirmDiscard = true } }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.text("Done")) {
                            block.name = block.name.trimmingCharacters(in: .whitespacesAndNewlines)
                            onSave(block); dismiss()
                        }.fontWeight(.bold).disabled(block.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("saveBlock")
                    }
                    ToolbarItem(placement: .bottomBar) { EditButton().disabled(block.exercises.isEmpty) }
                }
                .sheet(item: $exerciseEditor) { exercise in
                    ExerciseComposer(exercise: exercise) { updated in
                        if let index = block.exercises.firstIndex(where: { $0.id == updated.id }) { block.exercises[index] = updated }
                        else { block.exercises.append(updated) }
                    }
                }
                .interactiveDismissDisabled(block != original)
                .onAppear { if original == nil { original = block } }
                .confirmationDialog(L10n.text("Discard block changes?"), isPresented: $confirmDiscard, titleVisibility: .visible) {
                    Button(L10n.text("Discard changes"), role: .destructive) { dismiss() }
                }
        }
    }
}

struct ExerciseComposer: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExerciseLibraryStore.self) private var library
    @State var exercise: Exercise
    let onSave: (Exercise) -> Void
    @State private var configuring = false
    @State private var query = ""
    @State private var muscle = L10n.text("All")
    @State private var weight = ""
    @State private var confirmDiscard = false
    @State private var original: Exercise?
    @State private var saveFailure: String?
    private var parsedWeight: Double? {
        if weight.trimmingCharacters(in: .whitespaces).isEmpty { return 0 }
        guard let number = Double(weight.replacingOccurrences(of: ",", with: ".")), number.isFinite, number >= 0, number <= 10_000 else { return nil }
        return number
    }
    private var valid: Bool {
        !exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedWeight != nil &&
        (exercise.videoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Exercise.youtubeURL(exercise.videoURL) != nil)
    }
    private var changed: Bool { exercise != original || parsedWeight != original?.weight }

    var body: some View {
        NavigationStack {
            Group {
                if configuring { configuration }
                else { picker }
            }
            .background(Theme.background).navigationTitle(configuring ? L10n.text("Your exercise") : L10n.text("Choose exercise"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("Cancel")) { if changed { confirmDiscard = true } else { dismiss() } }
                }
                if configuring {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.text("Done")) {
                            exercise.weight = parsedWeight ?? 0
                            exercise.name = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
                            exercise.muscle = ExerciseCatalog.canonicalMuscle(exercise.muscle, among: library.muscles)
                            exercise.videoURL = exercise.videoURL.trimmingCharacters(in: .whitespacesAndNewlines)
                            if library.saveCustom(exercise) { onSave(exercise); dismiss() }
                            else { saveFailure = library.errorMessage; library.errorMessage = nil }
                        }.fontWeight(.bold).disabled(!valid).accessibilityIdentifier("saveExercise")
                    }
                }
            }
            .onAppear {
                if original == nil {
                    original = exercise; configuring = !exercise.name.isEmpty
                    weight = exercise.weight == 0 ? "" : String(exercise.weight)
                }
            }
            .interactiveDismissDisabled(changed)
            .alert(L10n.text("Unable to save"), isPresented: Binding(get: { saveFailure != nil }, set: { if !$0 { saveFailure = nil } })) {
                Button(L10n.text("Got it"), role: .cancel) { saveFailure = nil }
            } message: { Text(saveFailure ?? "") }
            .confirmationDialog(L10n.text("Discard this exercise?"), isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button(L10n.text("Discard changes"), role: .destructive) { dismiss() }
            }
        }
    }

    private var picker: some View {
        List {
            Section {
                Button { exercise.name = query; configuring = true } label: { Label(L10n.text("Enter an exercise manually"), systemImage: "square.and.pencil") }.accessibilityIdentifier("manualExercise")
            }
            Section {
                MuscleFilter(selection: $muscle, categories: library.muscles).listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            }
            Section(L10n.text("Shared catalog")) {
                let results = library.search(query, muscle: muscle)
                if results.isEmpty { Text(L10n.text("No matches. You can enter it manually.")).foregroundStyle(Theme.muted) }
                ForEach(results) { item in
                    Button {
                        let id = exercise.id; exercise = item.exercise; exercise.id = id; configuring = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.name).foregroundStyle(.primary)
                                Text("\(item.muscle) · \(item.equipment)").font(.caption).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Image(systemName: "plus.circle").foregroundStyle(Theme.lime)
                        }.padding(.vertical, 5)
                    }.accessibilityIdentifier("catalogExercise.\(item.id)")
                }
            }
        }.scrollContentBackground(.hidden).searchable(text: $query, prompt: L10n.text("Search exercises"))
    }

    private var configuration: some View {
        Form {
            Section(L10n.text("Exercise")) {
                TextField(L10n.text("Exercise name"), text: $exercise.name).accessibilityIdentifier("exerciseName")
                HStack {
                    TextField(L10n.text("Muscle group"), text: $exercise.muscle).accessibilityIdentifier("exerciseMuscle")
                    Menu {
                        ForEach(library.muscles.dropFirst(), id: \.self) { category in
                            Button(category) { exercise.muscle = category }
                        }
                    } label: { Image(systemName: "chevron.down").frame(width: 44, height: 44) }
                        .accessibilityLabel(L10n.text("Choose muscle group"))
                }
                Text(L10n.text("Custom exercises are saved to your library when you tap Done."))
                    .font(.caption).foregroundStyle(Theme.muted)
            }
            Section {
                Stepper(L10n.text("%ld sets", exercise.sets), value: $exercise.sets, in: 1...30)
                Picker(L10n.text("Measure by"), selection: $exercise.measurement) {
                    ForEach(ExerciseMeasurement.allCases) { measurement in
                        Text(measurement.title).tag(measurement).accessibilityIdentifier("measurement.\(measurement.rawValue)")
                    }
                }.pickerStyle(.segmented).accessibilityIdentifier("exerciseMeasurement")
                if exercise.measurement == .repetitions {
                    Stepper(L10n.text("%ld repetitions", exercise.reps), value: $exercise.reps, in: 1...200)
                        .accessibilityIdentifier("exerciseRepetitions")
                } else {
                    Stepper(L10n.text("Time per set: %ld s", exercise.durationSeconds), value: $exercise.durationSeconds, in: 5...3600, step: 5)
                        .accessibilityIdentifier("exerciseDuration")
                }
                HStack {
                    Text(L10n.text("Weight"))
                    Spacer()
                    TextField(L10n.text("No added weight"), text: $weight).accessibilityIdentifier("exerciseWeight").keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    Text("kg").foregroundStyle(Theme.muted)
                }
                if parsedWeight == nil { Text(L10n.text("Enter a valid weight between 0 and 10,000 kg.")).font(.caption).foregroundStyle(.orange) }
            } header: { Text(L10n.text("Sets and load")) } footer: { Text(L10n.text("Use 0 or leave the weight empty for unloaded exercises. Tabata uses the block’s timing.")) }
            Section {
                TextField("https://www.youtube.com/watch?v=…", text: $exercise.videoURL)
                    .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                if !exercise.videoURL.isEmpty && Exercise.youtubeURL(exercise.videoURL) == nil {
                    Text(L10n.text("Paste an HTTPS YouTube video or Shorts link.")).font(.caption).foregroundStyle(.orange)
                }
            } header: { Text(L10n.text("YouTube video · optional")) } footer: {
                Text(L10n.text("A link opens the video directly. Without a link, YouTube opens a search for the exercise."))
            }
        }.scrollContentBackground(.hidden)
    }
}
