// Copyright (C) 2026 gsanz.dev
// Licensed under GNU GPL version 3 only, with the additional notice-preservation
// term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

import SwiftUI

struct ContentView: View {
    @Environment(RoutineStore.self) private var store
    var body: some View {
        @Bindable var store = store
        TabView {
            Tab(L10n.text("My week"), systemImage: "square.grid.2x2") { WeekView() }
            Tab(L10n.text("Exercises"), systemImage: "dumbbell") { CatalogView() }
        }
        .alert(L10n.text("Your routines"), isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            Button(L10n.text("Got it"), role: .cancel) { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
    }
}

private struct EditorDestination: Identifiable {
    let routine: Routine
    var id: UUID { routine.id }
}

struct WeekView: View {
    @Environment(RoutineStore.self) private var store
    @State private var day = Weekday.today
    @State private var editor: EditorDestination?
    @State private var training: Routine?
    @State private var deletion: Routine?
    @State private var showsAbout = false
    private var routines: [Routine] { store.routines.filter { $0.day == day } }
    private var activeDays: Int { Set(store.routines.map(\.day)).count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    weekSelector
                    HStack(alignment: .firstTextBaseline) {
                        Text(day.title).font(.system(.title, design: .rounded).weight(.bold))
                        Spacer()
                        Text(day == .today ? L10n.text("TODAY") : L10n.text("YOUR PLAN")).font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2).foregroundStyle(Theme.lime)
                    }
                    if routines.isEmpty { emptyState }
                    else {
                        ForEach(routines) { routine in routineCard(routine) }
                        Button { newRoutine() } label: {
                            Label(L10n.text("Add another routine"), systemImage: "plus").font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 18).stroke(Theme.elevated, style: StrokeStyle(lineWidth: 1, dash: [5])))
                        }.buttonStyle(.plain).foregroundStyle(Theme.muted)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "iphone")
                        Text(L10n.text("Your pace. Your routine. All on your iPhone."))
                    }.font(.caption2).foregroundStyle(Theme.muted).frame(maxWidth: .infinity).padding(.vertical, 8)
                }.padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 24)
            }
            .background(Theme.background).toolbar(.hidden, for: .navigationBar)
            .sheet(item: $editor) { destination in RoutineEditor(routine: destination.routine) }
            .sheet(isPresented: $showsAbout) { AboutView() }
            .fullScreenCover(item: $training) { SessionView(routine: $0) }
            .confirmationDialog(L10n.text("Delete %@?", deletion?.name ?? L10n.text("Routine")), isPresented: Binding(get: { deletion != nil }, set: { if !$0 { deletion = nil } }), titleVisibility: .visible) {
                Button(L10n.text("Delete routine"), role: .destructive) { if let deletion { store.delete(deletion) }; deletion = nil }
            }
            .onAppear {
                if ProcessInfo.processInfo.arguments.contains("--demo"), store.routines.isEmpty {
                    store.save(.example(day: .monday)); day = .monday
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                HStack(spacing: 5) {
                    Text("repit").font(.system(size: 29, weight: .heavy, design: .rounded)).tracking(-1.5)
                    Circle().fill(Theme.lime).frame(width: 7, height: 7).offset(y: 8)
                }
                Spacer()
                Button { showsAbout = true } label: {
                    Image(systemName: "info.circle").font(.system(size: 20, weight: .medium))
                        .frame(width: 44, height: 48).foregroundStyle(Theme.muted)
                }.accessibilityLabel(L10n.text("Credits and license")).accessibilityIdentifier("creditsAndLicense")
                Button { newRoutine() } label: {
                    Image(systemName: "plus").font(.system(size: 20, weight: .medium))
                        .frame(width: 48, height: 48).background(Theme.surface, in: Circle())
                }.accessibilityLabel(L10n.text("Create routine")).accessibilityIdentifier("createRoutine")
            }
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: L10n.text("Less fuss. More movement."))
                Text(L10n.text("Your week,\nat your pace.")).font(.system(size: 42, weight: .bold, design: .rounded)).tracking(-1.8).lineSpacing(-2)
            }
            HStack(spacing: 8) {
                Circle().fill(Theme.lime).frame(width: 6, height: 6)
                Text(activeDays == 0 ? L10n.text("A good plan starts with one day.") : L10n.text("%ld %@ this week", activeDays, activeDays == 1 ? L10n.text("training day") : L10n.text("training days")))
                    .font(.caption).foregroundStyle(Theme.muted)
            }
        }
    }

    private var weekSelector: some View {
        HStack(spacing: 6) {
            ForEach(Weekday.allCases) { item in
                Button { withAnimation(.easeInOut(duration: 0.18)) { day = item } } label: {
                    VStack(spacing: 12) {
                        Text(item.short).font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Circle().fill(store.routines.contains { $0.day == item } ? (day == item ? Theme.background : Theme.lime) : .clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity).frame(minHeight: 66)
                    .foregroundStyle(day == item ? Theme.background : Theme.muted)
                    .background(day == item ? Theme.lime : Theme.surface, in: RoundedRectangle(cornerRadius: 20))
                }.buttonStyle(.plain).accessibilityLabel(item.title)
                    .accessibilityAddTraits(day == item ? .isSelected : [])
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 22) {
            Image(systemName: "dumbbell").font(.system(size: 30)).foregroundStyle(Theme.lime)
                .padding(18).background(Theme.elevated, in: RoundedRectangle(cornerRadius: 20))
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("Make time for yourself.")).font(.title2.bold())
                Text(L10n.text("Build your %@ routine.\nOne exercise at a time.", day.title.lowercased()))
                    .font(.subheadline).foregroundStyle(Theme.muted).lineSpacing(4)
            }
            PrimaryButton(title: L10n.text("Create my routine")) { newRoutine() }
            Button(L10n.text("Try a sample routine")) { store.save(.example(day: day)) }
                .font(.caption).foregroundStyle(Theme.muted).frame(maxWidth: .infinity).padding(.bottom, 4)
        }.padding(24).background(Theme.surface, in: RoundedRectangle(cornerRadius: 28))
    }

    private func routineCard(_ routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: L10n.text("Your workout"))
                    Text(routine.name).font(.system(.title2, design: .rounded).weight(.bold))
                    Text(L10n.text("%ld exercises · %ld blocks", routine.exerciseCount, routine.blocks.count))
                        .font(.caption).foregroundStyle(Theme.muted)
                }
                Spacer()
                Menu {
                    Button(L10n.text("Edit routine"), systemImage: "pencil") { editor = .init(routine: routine) }.accessibilityIdentifier("editRoutine")
                    Button(L10n.text("Duplicate"), systemImage: "square.on.square") {
                        var copy = routine; copy.id = UUID(); copy.name += L10n.text(" · copy"); editor = .init(routine: copy)
                    }
                    Button(L10n.text("Delete routine"), systemImage: "trash", role: .destructive) { deletion = routine }
                } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44).foregroundStyle(Theme.muted).background(Theme.elevated, in: Circle()) }
                .accessibilityLabel(L10n.text("Options for %@", routine.name)).accessibilityIdentifier("routineOptions")
            }
            ForEach(Array(routine.blocks.enumerated()), id: \.element.id) { index, block in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(String(format: "%02d", index + 1)).foregroundStyle(Theme.lime)
                        Text(block.name.uppercased()).foregroundStyle(Theme.muted)
                        Spacer()
                        if block.kind != .standard {
                            Label(block.kind.title.uppercased(), systemImage: block.kind.symbol)
                                .font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.lime)
                                .padding(.horizontal, 9).padding(.vertical, 6).background(Theme.lime.opacity(0.09), in: Capsule())
                        }
                    }.font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1)
                    if block.kind != .standard { Text(block.subtitle).font(.caption2).foregroundStyle(Theme.muted) }
                    ForEach(block.exercises) { exercise in ExerciseRow(exercise: exercise) }
                    if block.exercises.isEmpty { Text(L10n.text("Add exercises from Edit routine.")).font(.caption).foregroundStyle(Theme.muted) }
                }
                if index < routine.blocks.count - 1 { Rectangle().fill(Theme.elevated).frame(height: 1) }
            }
            if routine.exerciseCount > 0 {
                PrimaryButton(title: L10n.text("Start workout"), icon: "play.fill") { training = routine }.accessibilityIdentifier("startWorkout")
            } else {
                PrimaryButton(title: L10n.text("Add exercises")) { editor = .init(routine: routine) }
            }
        }.padding(20).background(Theme.surface, in: RoundedRectangle(cornerRadius: 28))
    }
    private func newRoutine() { editor = .init(routine: Routine(name: "", day: day)) }
}

struct CatalogView: View {
    @Environment(\.openURL) private var openURL
    @State private var query = ""
    @State private var muscle = L10n.text("All")
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Eyebrow(text: L10n.text("Your movement library"))
                    Text(L10n.text("Find your\nnext exercise.")).font(.system(size: 34, weight: .bold, design: .rounded)).tracking(-1)
                    Text(L10n.text("%ld exercises · Tap to see the technique on YouTube.", ExerciseCatalog.all.count))
                        .font(.caption).foregroundStyle(Theme.muted)
                    MuscleFilter(selection: $muscle)
                    let results = ExerciseCatalog.search(query, muscle: muscle)
                    if results.isEmpty { ContentUnavailableView.search(text: query) }
                    ForEach(results) { item in
                        Button { openURL(item.exercise.demonstrationURL) } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "dumbbell").foregroundStyle(Theme.lime)
                                    .frame(width: 44, height: 48).background(Theme.elevated, in: RoundedRectangle(cornerRadius: 14))
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.name).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                                    Text("\(item.muscle) · \(item.equipment)").font(.caption2).foregroundStyle(Theme.muted)
                                }
                                Spacer(minLength: 4)
                                Image(systemName: "play.circle").font(.title3).foregroundStyle(Theme.muted)
                            }.padding(14).background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
                        }.buttonStyle(.plain).accessibilityLabel(L10n.text("%@, %@, %@. See technique on YouTube", item.name, item.muscle, item.equipment))
                    }
                }.padding(24)
            }.background(Theme.background)
                .navigationTitle(L10n.text("Exercises")).navigationBarTitleDisplayMode(.inline)
                .searchable(text: $query, prompt: L10n.text("Name, muscle, or equipment"))
        }
    }
}

struct MuscleFilter: View {
    @Binding var selection: String
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ExerciseCatalog.muscles, id: \.self) { muscle in
                    Button { selection = muscle } label: {
                        Text(muscle).font(.caption.weight(.semibold)).padding(.horizontal, 16).padding(.vertical, 12)
                            .foregroundStyle(selection == muscle ? Theme.background : Theme.muted)
                            .background(selection == muscle ? Theme.lime : Theme.elevated, in: Capsule())
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}
