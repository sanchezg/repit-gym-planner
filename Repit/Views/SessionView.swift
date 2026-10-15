// Copyright (C) 2026 gsanz.dev
// Licensed under GNU GPL version 3 only, with the additional notice-preservation
// term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

import SwiftUI
import Combine
import UIKit

struct SessionView: View {
    let routine: Routine
    @Environment(\.dismiss) private var dismiss
    @State private var completed: Set<String> = []
    @State private var completedTabatas: Set<UUID> = []
    @State private var timerBlock: WorkoutBlock?
    @State private var confirmExit = false
    @State private var finished = false
    private var total: Int { routine.setCount }
    private var done: Int {
        completed.count + routine.blocks.filter { completedTabatas.contains($0.id) }.reduce(0) { $0 + $1.rounds }
    }

    var body: some View {
        NavigationStack {
            Group {
                if finished { finishView }
                else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Eyebrow(text: L10n.text("One step closer"))
                            Text(routine.name).font(.system(.largeTitle, design: .rounded).bold())
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(L10n.text("Your progress")).font(.subheadline)
                                    Spacer()
                                    Text("\(done) / \(total)").font(.system(.subheadline, design: .monospaced)).foregroundStyle(Theme.lime)
                                }
                                ProgressView(value: Double(done), total: Double(max(1, total))).tint(Theme.lime)
                            }
                            ForEach(routine.blocks.filter { !$0.exercises.isEmpty }) { block in
                                VStack(alignment: .leading, spacing: 18) {
                                    HStack {
                                        Text(block.name).font(.title3.bold())
                                        Spacer()
                                        Image(systemName: block.kind.symbol).foregroundStyle(Theme.lime)
                                    }
                                    Text(block.subtitle).font(.caption).foregroundStyle(Theme.muted)
                                    if block.kind == .tabata {
                                        ForEach(block.exercises) { ExerciseRow(exercise: $0) }
                                        if completedTabatas.contains(block.id) {
                                            Label(L10n.text("Block completed"), systemImage: "checkmark.circle.fill").foregroundStyle(Theme.lime)
                                        } else {
                                            PrimaryButton(title: L10n.text("Start Tabata"), icon: "timer") { timerBlock = block }
                                        }
                                    } else {
                                        let rounds = block.kind == .circuit ? block.rounds : 1
                                        ForEach(0..<rounds, id: \.self) { round in
                                            if rounds > 1 { Eyebrow(text: L10n.text("Round %ld of %ld", round + 1, rounds)) }
                                            ForEach(block.exercises) { exercise in
                                                VStack(alignment: .leading, spacing: 12) {
                                                    ExerciseRow(exercise: exercise)
                                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 8) {
                                                        ForEach(0..<exercise.sets, id: \.self) { set in
                                                            let key = "\(block.id)-\(round)-\(exercise.id)-\(set)"
                                                            let checked = completed.contains(key)
                                                            Button {
                                                                if checked { completed.remove(key) } else { completed.insert(key) }
                                                            } label: {
                                                                Group {
                                                                    if checked { Image(systemName: "checkmark") }
                                                                    else { Text("\(set + 1)") }
                                                                }.font(.subheadline.weight(.bold)).frame(maxWidth: .infinity).frame(height: 46)
                                                                    .foregroundStyle(checked ? Theme.background : Theme.muted)
                                                                    .background(checked ? Theme.lime : Theme.elevated, in: RoundedRectangle(cornerRadius: 14))
                                                            }.buttonStyle(.plain)
                                                                .accessibilityLabel(L10n.text("%@, set %ld, round %ld, %@", exercise.name, set + 1, round + 1, checked ? L10n.text("completed") : L10n.text("pending")))
                                                                .accessibilityIdentifier("exerciseSet.\(exercise.id).\(round).\(set)")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }.padding(20).background(Theme.surface, in: RoundedRectangle(cornerRadius: 24))
                            }
                            PrimaryButton(title: L10n.text("Finish workout"), icon: "checkmark") { finished = true }
                                .disabled(done < total).opacity(done < total ? 0.4 : 1)
                            Text(L10n.text("Tap each set when you finish it. Progress is kept while this screen stays open."))
                                .font(.caption).foregroundStyle(Theme.muted)
                        }.padding(24)
                    }
                }
            }.background(Theme.background)
                .navigationTitle(L10n.text("Time to train")).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(finished ? L10n.text("Close") : L10n.text("Exit")) { if finished { dismiss() } else { confirmExit = true } }.accessibilityIdentifier("exitWorkout") }
                }
                .confirmationDialog(L10n.text("Leave the workout?"), isPresented: $confirmExit, titleVisibility: .visible) {
                    Button(L10n.text("Exit and discard progress"), role: .destructive) { dismiss() }.accessibilityIdentifier("discardSession")
                } message: { Text(L10n.text("The routine stays saved. Completed sets from this session will be discarded.")) }
                .sheet(item: $timerBlock) { block in
                    TabataTimerView(block: block) { completedTabatas.insert(block.id) }
                }
                .sensoryFeedback(.success, trigger: completed.count)
                .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
                .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        }
    }

    private var finishView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark").font(.system(size: 52, weight: .medium))
                .foregroundStyle(Theme.lime).frame(width: 120, height: 120).background(Theme.surface, in: Circle())
            Eyebrow(text: L10n.text("You did it"))
            Text(L10n.text("Another day\nfor yourself.")).font(.system(size: 44, weight: .bold, design: .rounded)).multilineTextAlignment(.center)
            Text(L10n.text("%ld exercises completed.\nYour next routine is waiting.", routine.exerciseCount))
                .font(.subheadline).foregroundStyle(Theme.muted).multilineTextAlignment(.center).lineSpacing(4)
            Spacer()
            PrimaryButton(title: L10n.text("Back to my week"), icon: "arrow.right") { dismiss() }
        }.padding(28)
    }
}

struct TabataTimerView: View {
    let block: WorkoutBlock
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var elapsed: TimeInterval = 0
    @State private var startedAt: Date?
    @State private var running = false
    @State private var reported = false
    @State private var confirmExit = false
    private let ticker = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    private var state: IntervalState { .at(elapsed: Int(elapsed), block: block) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Eyebrow(text: "\(block.name) · Tabata")
                Text(state.finished ? L10n.text("Completed") : (state.resting ? L10n.text("Breathe.") : L10n.text("Let’s move.")))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                Text(L10n.text("Interval %ld of %ld", state.round, block.rounds)).font(.subheadline).foregroundStyle(Theme.muted)
                Spacer()
                ZStack {
                    Circle().stroke(Theme.elevated, lineWidth: 8)
                    Circle().trim(from: 0, to: min(1, elapsed / Double(max(1, block.tabataDuration))))
                        .stroke(Theme.lime, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90))
                    VStack(spacing: 8) {
                        Text(state.finished ? "✓" : "\(state.remaining)")
                            .font(.system(size: 82, weight: .medium, design: .rounded)).monospacedDigit()
                        Text(state.finished ? L10n.text("WELL DONE") : L10n.text("SECONDS")).font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(3).foregroundStyle(Theme.muted)
                    }
                }.frame(maxWidth: 270, maxHeight: 270).aspectRatio(1, contentMode: .fit).foregroundStyle(Theme.lime)
                if !state.finished, !block.exercises.isEmpty {
                    Text(block.exercises[(state.exerciseIndex + (state.resting ? 1 : 0)) % block.exercises.count].name).font(.title3.bold()).multilineTextAlignment(.center)
                    Text(state.resting ? L10n.text("Prepare for the next movement.") : block.exercises[state.exerciseIndex].weightLabel)
                        .font(.caption).foregroundStyle(Theme.muted)
                }
                Spacer()
                PrimaryButton(title: state.finished ? L10n.text("Done") : (running ? L10n.text("Pause") : (elapsed == 0 ? L10n.text("Start") : L10n.text("Continue"))), icon: state.finished ? "checkmark" : (running ? "pause.fill" : "play.fill")) {
                    if state.finished { dismiss() }
                    else if running { pause() }
                    else { startedAt = Date().addingTimeInterval(-elapsed); running = true }
                }
                Text(L10n.text("The timer pauses when you leave the app.")).font(.caption2).foregroundStyle(Theme.muted)
            }.padding(28).background(Theme.background)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L10n.text("Close")) { if state.finished || elapsed == 0 { dismiss() } else { pause(); confirmExit = true } } } }
                .onReceive(ticker) { _ in
                    guard running, let startedAt else { return }
                    elapsed = min(Double(block.tabataDuration), Date().timeIntervalSince(startedAt))
                    completeIfNeeded()
                }
                .onChange(of: scenePhase) { _, phase in if phase != .active { pause() } }
                .interactiveDismissDisabled(elapsed > 0 && !state.finished)
                .confirmationDialog(L10n.text("Close the timer?"), isPresented: $confirmExit, titleVisibility: .visible) {
                    Button(L10n.text("Close and discard this interval"), role: .destructive) { dismiss() }
                } message: { Text(L10n.text("The block will need to start again.")) }
                .sensoryFeedback(.impact, trigger: state.round)
                .sensoryFeedback(.impact, trigger: state.resting)
        }
    }
    private func pause() {
        if running, let startedAt { elapsed = min(Double(block.tabataDuration), Date().timeIntervalSince(startedAt)) }
        running = false; startedAt = nil
        completeIfNeeded()
    }
    private func completeIfNeeded() {
        if state.finished {
            running = false
            if !reported { reported = true; onComplete() }
        }
    }
}
