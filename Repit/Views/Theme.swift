// Copyright (C) 2026 gsanz.dev
// Licensed under GNU GPL version 3 only, with the additional notice-preservation
// term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

import SwiftUI

enum Theme {
    static let background = Color(red: 0.055, green: 0.065, blue: 0.06)
    static let surface = Color(red: 0.095, green: 0.11, blue: 0.10)
    static let elevated = Color(red: 0.14, green: 0.16, blue: 0.145)
    static let lime = Color(red: 0.80, green: 0.96, blue: 0.42)
    static let muted = Color(red: 0.57, green: 0.62, blue: 0.58)
}

struct PrimaryButton: View {
    let title: String
    var icon: String = "plus"
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(.headline, design: .rounded))
                .frame(maxWidth: .infinity).padding(.vertical, 18)
                .foregroundStyle(Theme.background).background(Theme.lime, in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(.plain)
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased()).font(.system(size: 11, weight: .bold, design: .monospaced))
            .tracking(2).foregroundStyle(Theme.muted)
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    var index: Int? = nil
    @Environment(\.openURL) private var openURL
    var body: some View {
        Button { openURL(exercise.demonstrationURL) } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(Theme.elevated).frame(width: 44, height: 48)
                    if let index { Text(String(format: "%02d", index)).font(.system(.subheadline, design: .monospaced)).foregroundStyle(Theme.muted) }
                    else { Image(systemName: "dumbbell").foregroundStyle(Theme.lime) }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    Text("\(exercise.sets) × \(exercise.reps) reps  ·  \(exercise.weightLabel)")
                        .font(.caption).foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 4)
                Image(systemName: "play.circle").font(.title3).foregroundStyle(Theme.muted)
            }.padding(.vertical, 7).contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel(L10n.text("%@, %ld sets of %ld, %@. %@", exercise.name, exercise.sets, exercise.reps, exercise.weightLabel, exercise.videoURL.isEmpty ? L10n.text("Search YouTube for a demonstration") : L10n.text("Watch demonstration on YouTube")))
    }
}
