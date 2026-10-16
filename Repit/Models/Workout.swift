// Copyright (C) 2026 gsanz.dev
// Licensed under GNU GPL version 3 only, with the additional notice-preservation
// term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

import Foundation

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    var id: Int { rawValue }
    var title: String { [L10n.text("Monday"), L10n.text("Tuesday"), L10n.text("Wednesday"), L10n.text("Thursday"), L10n.text("Friday"), L10n.text("Saturday"), L10n.text("Sunday")][rawValue] }
    var short: String { String(title.prefix(1)) }
    static var today: Self { Self(rawValue: (Calendar.current.component(.weekday, from: Date()) + 5) % 7)! }
}

enum ExerciseMeasurement: String, Codable, CaseIterable, Identifiable {
    case repetitions, time
    var id: String { rawValue }
    var title: String { self == .repetitions ? L10n.text("Repetitions") : L10n.text("Time") }
}

struct Exercise: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var muscle: String = L10n.text("Custom")
    var sets: Int = 3
    var reps: Int = 12
    var measurement: ExerciseMeasurement = .repetitions
    var durationSeconds: Int = 30
    var weight: Double = 0
    var videoURL: String = ""
    var weightLabel: String { weight == 0 ? L10n.text("No added weight") : "\(weight.formatted(.number.precision(.fractionLength(0...2)))) kg" }
    var targetLabel: String {
        measurement == .time ? L10n.text("%ld s", durationSeconds) : L10n.text("%ld reps", reps)
    }
    var prescriptionLabel: String { "\(sets) × \(targetLabel) · \(weightLabel)" }

    private enum CodingKeys: String, CodingKey {
        case id, name, muscle, sets, reps, measurement, durationSeconds, weight, videoURL
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        muscle = try values.decodeIfPresent(String.self, forKey: .muscle) ?? L10n.text("Custom")
        sets = try values.decodeIfPresent(Int.self, forKey: .sets) ?? 3
        reps = try values.decodeIfPresent(Int.self, forKey: .reps) ?? 12
        measurement = try values.decodeIfPresent(ExerciseMeasurement.self, forKey: .measurement) ?? .repetitions
        durationSeconds = try values.decodeIfPresent(Int.self, forKey: .durationSeconds) ?? 30
        weight = try values.decodeIfPresent(Double.self, forKey: .weight) ?? 0
        videoURL = try values.decodeIfPresent(String.self, forKey: .videoURL) ?? ""
    }
    var demonstrationURL: URL {
        if let url = Self.youtubeURL(videoURL) { return url }
        var components = URLComponents(string: "https://www.youtube.com/results")!
        components.queryItems = [URLQueryItem(name: "search_query", value: L10n.text("%@ exercise technique demonstration", name))]
        return components.url!
    }
    static func youtubeURL(_ text: String) -> URL? {
        guard let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme == "https", let host = url.host?.lowercased(),
              ["youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be"].contains(host) else { return nil }
        if host == "youtu.be" { return url.path.count > 1 ? url : nil }
        if url.path == "/watch", URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains(where: { $0.name == "v" && !($0.value ?? "").isEmpty }) == true { return url }
        return url.path.hasPrefix("/shorts/") && url.path.count > 8 ? url : nil
    }
}

enum BlockKind: String, Codable, CaseIterable, Identifiable {
    case standard, circuit, tabata
    var id: String { rawValue }
    var title: String {
        switch self {
        case .standard: L10n.text("Sets")
        case .circuit: L10n.text("Circuit")
        case .tabata: "Tabata"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        // Accept the original localized values so existing routines remain readable.
        guard let kind = Self(rawValue: value) ?? Self.allCases.first(where: { $0.title == value }) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown workout block kind: \(value)")
        }
        self = kind
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var symbol: String { switch self { case .standard: "dumbbell"; case .circuit: "arrow.trianglehead.2.clockwise.rotate.90"; case .tabata: "timer" } }
}

struct WorkoutBlock: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String = L10n.text("Strength block")
    var kind: BlockKind = .standard
    var rounds: Int = 8
    var workSeconds: Int = 20
    var restSeconds: Int = 10
    var exercises: [Exercise] = []
    var subtitle: String {
        switch kind {
        case .standard: L10n.text("%ld total sets", exercises.reduce(0) { $0 + $1.sets })
        case .circuit: L10n.text("%ld rounds · exercises in sequence", rounds)
        case .tabata: L10n.text("%ld intervals · %lds work / %lds rest", rounds, workSeconds, restSeconds)
        }
    }
    // Each interval uses the next exercise, cycling through the block.
    var tabataDuration: Int { rounds * (workSeconds + restSeconds) }
}

struct Routine: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var day: Weekday
    var blocks: [WorkoutBlock] = []
    var exerciseCount: Int { blocks.reduce(0) { $0 + $1.exercises.count } }
    var setCount: Int {
        blocks.filter { !$0.exercises.isEmpty }.reduce(0) { sum, block in
            sum + (block.kind == .tabata ? block.rounds : block.exercises.reduce(0) { $0 + ($1.sets * (block.kind == .circuit ? block.rounds : 1)) })
        }
    }
    static func example(day: Weekday) -> Self {
        Routine(name: L10n.text("Upper body"), day: day, blocks: [
            WorkoutBlock(name: L10n.text("Strength"), exercises: [
                Exercise(name: L10n.text("Bench press"), muscle: L10n.text("Chest"), sets: 4, reps: 10, weight: 0),
                Exercise(name: L10n.text("Dumbbell row"), muscle: L10n.text("Back"), sets: 3, reps: 12),
                Exercise(name: L10n.text("Shoulder press"), muscle: L10n.text("Shoulders"), sets: 3, reps: 10, videoURL: "https://www.youtube.com/watch?v=qEwKCR5JCog")
            ]),
            WorkoutBlock(name: "Finisher", kind: .tabata, exercises: [
                Exercise(name: L10n.text("Air squat"), muscle: L10n.text("Legs"), videoURL: "https://www.youtube.com/watch?v=jQyKVKjucNU"),
                Exercise(name: "Mountain climbers", muscle: "Core")
            ])
        ])
    }
}

struct CatalogExercise: Identifiable {
    let name: String
    let muscle: String
    let equipment: String
    var videoURL = ""
    var template: Exercise? = nil
    var id: String { name }
    var exercise: Exercise {
        var result = template ?? Exercise(name: name, muscle: muscle, videoURL: videoURL)
        result.id = UUID()
        return result
    }
}

enum ExerciseCatalog {
    static let all: [CatalogExercise] = [
        .init(name: L10n.text("Bench press"), muscle: L10n.text("Chest"), equipment: L10n.text("Barbell")),
        .init(name: L10n.text("Incline press"), muscle: L10n.text("Chest"), equipment: L10n.text("Dumbbells")),
        .init(name: L10n.text("Chest fly"), muscle: L10n.text("Chest"), equipment: L10n.text("Dumbbells")),
        .init(name: L10n.text("Push-ups"), muscle: L10n.text("Chest"), equipment: L10n.text("Bodyweight")),
        .init(name: L10n.text("Pull-ups"), muscle: L10n.text("Back"), equipment: L10n.text("Pull-up bar")),
        .init(name: L10n.text("Lat pulldown"), muscle: L10n.text("Back"), equipment: L10n.text("Cable")),
        .init(name: L10n.text("Barbell row"), muscle: L10n.text("Back"), equipment: L10n.text("Barbell")),
        .init(name: L10n.text("Dumbbell row"), muscle: L10n.text("Back"), equipment: L10n.text("Dumbbell")),
        .init(name: L10n.text("Seated row"), muscle: L10n.text("Back"), equipment: L10n.text("Cable")),
        .init(name: L10n.text("Barbell squat"), muscle: L10n.text("Legs"), equipment: L10n.text("Barbell")),
        .init(name: L10n.text("Air squat"), muscle: L10n.text("Legs"), equipment: L10n.text("Bodyweight"), videoURL: "https://www.youtube.com/watch?v=jQyKVKjucNU"),
        .init(name: L10n.text("Leg press"), muscle: L10n.text("Legs"), equipment: L10n.text("Machine")),
        .init(name: L10n.text("Romanian deadlift"), muscle: L10n.text("Legs"), equipment: L10n.text("Barbell")),
        .init(name: L10n.text("Leg extension"), muscle: L10n.text("Legs"), equipment: L10n.text("Machine")),
        .init(name: L10n.text("Leg curl"), muscle: L10n.text("Legs"), equipment: L10n.text("Machine")),
        .init(name: L10n.text("Lunges"), muscle: L10n.text("Legs"), equipment: L10n.text("Dumbbells")),
        .init(name: L10n.text("Calf raise"), muscle: L10n.text("Legs"), equipment: L10n.text("Machine")),
        .init(name: "Hip thrust", muscle: L10n.text("Glutes"), equipment: L10n.text("Barbell")),
        .init(name: L10n.text("Glute bridge"), muscle: L10n.text("Glutes"), equipment: L10n.text("Bodyweight")),
        .init(name: L10n.text("Shoulder press"), muscle: L10n.text("Shoulders"), equipment: L10n.text("Dumbbells"), videoURL: "https://www.youtube.com/watch?v=qEwKCR5JCog"),
        .init(name: L10n.text("Lateral raises"), muscle: L10n.text("Shoulders"), equipment: L10n.text("Dumbbells")),
        .init(name: "Face pull", muscle: L10n.text("Shoulders"), equipment: L10n.text("Cable")),
        .init(name: L10n.text("Biceps curl"), muscle: L10n.text("Arms"), equipment: L10n.text("Dumbbells")),
        .init(name: L10n.text("Hammer curl"), muscle: L10n.text("Arms"), equipment: L10n.text("Dumbbells")),
        .init(name: L10n.text("Triceps extension"), muscle: L10n.text("Arms"), equipment: L10n.text("Cable")),
        .init(name: L10n.text("Parallel bar dips"), muscle: L10n.text("Arms"), equipment: L10n.text("Bodyweight")),
        .init(name: L10n.text("Plank"), muscle: "Core", equipment: L10n.text("Bodyweight")),
        .init(name: L10n.text("Abdominal crunch"), muscle: "Core", equipment: L10n.text("Bodyweight")),
        .init(name: L10n.text("Knee raise"), muscle: "Core", equipment: L10n.text("Pull-up bar")),
        .init(name: "Mountain climbers", muscle: "Core", equipment: L10n.text("Bodyweight")),
        .init(name: "Burpees", muscle: "Cardio", equipment: L10n.text("Bodyweight")),
        .init(name: "Jumping jacks", muscle: "Cardio", equipment: L10n.text("Bodyweight"))
    ]
    static let muscles = [L10n.text("All"), L10n.text("Chest"), L10n.text("Back"), L10n.text("Legs"), L10n.text("Glutes"), L10n.text("Shoulders"), L10n.text("Arms"), "Core", "Cardio"]
    static let muscleKeys = ["Chest", "Back", "Legs", "Glutes", "Shoulders", "Arms", "Core", "Cardio", "Custom"]

    static func normalized(_ value: String) -> String {
        value.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: L10n.locale)
    }

    static func canonicalMuscle(_ value: String, among categories: [String] = []) -> String {
        let trimmed = value.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        guard !trimmed.isEmpty, normalized(trimmed) != normalized(L10n.text("All")) else { return L10n.text("Custom") }
        if let key = muscleKeys.first(where: { normalized($0) == normalized(trimmed) || normalized(L10n.text($0)) == normalized(trimmed) }) {
            return L10n.text(key)
        }
        return categories.first { normalized($0) == normalized(trimmed) } ?? trimmed
    }

    static func categoryIdentifier(_ category: String) -> String {
        let key = muscleKeys.first { normalized(L10n.text($0)) == normalized(category) }
        return normalized(key ?? category)
    }

    static func search(_ query: String, muscle: String = L10n.text("All"), in exercises: [CatalogExercise] = all) -> [CatalogExercise] {
        exercises.filter { item in
            (muscle == L10n.text("All") || normalized(item.muscle) == normalized(muscle)) &&
            (query.isEmpty || normalized("\(item.name) \(item.muscle) \(item.equipment)").contains(normalized(query)))
        }
    }
}

// Keep the memberwise initializer while decoding older saves without measurement fields.
extension Exercise {
    init(name: String, muscle: String = L10n.text("Custom"), sets: Int = 3, reps: Int = 12,
         measurement: ExerciseMeasurement = .repetitions, durationSeconds: Int = 30,
         weight: Double = 0, videoURL: String = "") {
        self.name = name; self.muscle = muscle; self.sets = sets; self.reps = reps
        self.measurement = measurement; self.durationSeconds = durationSeconds
        self.weight = weight; self.videoURL = videoURL
    }
}

struct IntervalState: Equatable {
    let round: Int
    let resting: Bool
    let remaining: Int
    let exerciseIndex: Int
    let finished: Bool
    static func at(elapsed: Int, block: WorkoutBlock) -> Self {
        let cycle = max(1, block.workSeconds + block.restSeconds)
        let elapsed = max(0, elapsed)
        let finished = elapsed >= block.tabataDuration
        let position = elapsed % cycle
        return Self(round: min(block.rounds, elapsed / cycle + 1), resting: position >= block.workSeconds,
                    remaining: finished ? 0 : (position < block.workSeconds ? block.workSeconds - position : cycle - position),
                    exerciseIndex: (elapsed / cycle) % max(1, block.exercises.count), finished: finished)
    }
}
