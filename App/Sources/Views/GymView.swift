import SwiftUI
import Charts
import StoicKit

private let gymAccent = Color(red: 1.0, green: 0.55, blue: 0.3)

/// Gym screen — training log, streak, body weight, exercise recommendations.
struct GymView: View {
    @Environment(AppState.self) private var app

    @State private var showingLog = false
    @State private var weightInput = ""
    @State private var targetInput = ""
    @State private var editingWeight = false
    @State private var recMuscle: MuscleGroup = .chest
    @State private var intakeInput = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ScreenTitle("Gym",
                                subtitle: "Hold the body to the same standard as everything else.")
                    Spacer()
                    Button {
                        app.addTimeBlock(TimeBlock(title: "Strength training", startHour: 18))
                    } label: {
                        Label("Schedule", systemImage: "calendar.badge.plus")
                    }
                    .buttonStyle(.bordered)
                    Button { showingLog = true } label: {
                        Label("Log workout", systemImage: "plus")
                    }
                    .buttonStyle(GradientButtonStyle())
                }

                HStack(alignment: .top, spacing: 16) {
                    streakCard
                    bodyWeightCard
                }
                readinessCard
                strengthCard
                energyCard
                trajectoryCard
                muscleVolumeCard
                recordsCard
                recommendationsCard
                historySection
            }
            .padding(24)
        }
        .sheet(isPresented: $showingLog) {
            LogWorkoutView().environment(app)
        }
    }

    private var streakCard: some View {
        Card(accent: gymAccent) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Streak", tint: gymAccent)
                HStack(spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(gymAccent)
                        .shadow(color: gymAccent.opacity(0.6), radius: 8)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(app.workoutStreak)")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text(app.workoutStreak == 1 ? "day" : "days")
                            .font(.caption)
                            .foregroundStyle(Theme.textDim)
                    }
                }
                Text("\(app.workouts.count) workouts logged")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var bodyWeightCard: some View {
        Card(accent: gymAccent) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Body weight", tint: gymAccent)
                if let current = app.currentBodyWeightKg {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", current))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text("kg").font(.caption).foregroundStyle(Theme.textDim)
                    }
                    if app.targetBodyWeightKg > 0 {
                        Text("Target \(String(format: "%.1f", app.targetBodyWeightKg)) kg")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Theme.textDim)
                    }
                } else {
                    Text("No weight logged yet.")
                        .font(.callout)
                        .foregroundStyle(Theme.textDim)
                }
                if editingWeight {
                    HStack(spacing: 6) {
                        TextField("kg now", text: $weightInput)
                            .textFieldStyle(.roundedBorder).frame(width: 76)
                        TextField("target", text: $targetInput)
                            .textFieldStyle(.roundedBorder).frame(width: 76)
                        Button("Save") { saveWeights() }.buttonStyle(.bordered)
                    }
                } else {
                    Button("Update") {
                        weightInput = app.currentBodyWeightKg.map { String(format: "%.1f", $0) } ?? ""
                        targetInput = app.targetBodyWeightKg > 0
                            ? String(format: "%.1f", app.targetBodyWeightKg) : ""
                        editingWeight = true
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(Theme.cyan)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var readinessCard: some View {
        Card(accent: gymAccent) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel("Training readiness", tint: gymAccent)
                if case .connected = app.whoop.state,
                   let recovery = app.whoop.vitals.recoveryPercent {
                    let verdict = readinessVerdict(recovery)
                    HStack(spacing: 8) {
                        Circle().fill(verdict.color).frame(width: 11, height: 11)
                        Text(verdict.headline)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("recovery \(recovery)%")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Theme.textDim)
                    }
                    Text(verdict.detail)
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                } else {
                    Text("Connect WHOOP in Vitals for a recovery-based training verdict.")
                        .font(.callout)
                        .foregroundStyle(Theme.textDim)
                }
            }
        }
    }

    private func readinessVerdict(_ recovery: Int) -> (color: Color, headline: String, detail: String) {
        switch recovery {
        case 67...:
            return (Theme.ok, "Push \u{2014} add load today",
                    "Recovery is high. This is a day to chase a PR.")
        case 34..<67:
            return (Theme.gold, "Maintain \u{2014} train, don't grind",
                    "Moderate recovery. Hold your numbers; stop short of failure.")
        default:
            return (Theme.danger, "Deload or rest",
                    "Recovery is low. Training hard today is a withdrawal, not a deposit.")
        }
    }

    private var energyCard: some View {
        let intake = app.todayCalorieIntake
        let burned = app.todayTrainingBurn
        let net = intake - burned
        return Card(accent: gymAccent) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Energy \u{2014} today", tint: gymAccent)
                HStack(spacing: 18) {
                    metric("\(intake)", "kcal in")
                    metric("~\(burned)", "training burn")
                    metric("\(net >= 0 ? "+" : "")\(net)", "net (excl. BMR)")
                }
                HStack(spacing: 6) {
                    TextField("Log calories eaten", text: $intakeInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                    Button("Add") {
                        if let kcal = Int(intakeInput.trimmingCharacters(in: .whitespaces)),
                           kcal > 0 {
                            app.addCalorieIntake(kcal)
                        }
                        intakeInput = ""
                    }
                    .buttonStyle(.bordered)
                }
                if app.targetBodyWeightKg > 0, let current = app.currentBodyWeightKg {
                    Text(current > app.targetBodyWeightKg
                         ? "Goal is fat loss \u{2014} keep intake under your full daily burn."
                         : (current < app.targetBodyWeightKg
                            ? "Goal is gaining \u{2014} intake must clear your full daily burn."
                            : "You are at your target weight \u{2014} hold the balance."))
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                }
            }
        }
    }

    private var strengthCard: some View {
        let score = GymAnalysis.strengthScore(sessions: app.workouts,
                                              bodyWeightKg: app.currentBodyWeightKg ?? 0)
        return Card(accent: gymAccent) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Strength score", tint: gymAccent)
                if let score {
                    HStack(spacing: 14) {
                        RingGauge(value: Double(score) / 100, accent: gymAccent, lineWidth: 7)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text("\(score)")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(Theme.textPrimary)
                            )
                        Text("Your main lifts measured against bodyweight-multiple standards \u{2014} novice to elite.")
                            .font(.caption)
                            .foregroundStyle(Theme.textDim)
                    }
                } else {
                    Text("Log the big lifts (bench, squat, deadlift, overhead press) and your body weight to earn a strength score.")
                        .font(.callout)
                        .foregroundStyle(Theme.textDim)
                }
            }
        }
    }

    private var trajectoryCard: some View {
        Card(accent: gymAccent) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Body-weight trajectory", tint: gymAccent)
                if app.bodyWeights.count < 2 {
                    Text("Log your body weight over time to see the trajectory.")
                        .font(.callout)
                        .foregroundStyle(Theme.textDim)
                } else {
                    Chart {
                        ForEach(app.bodyWeights.sorted { $0.date < $1.date }) { entry in
                            LineMark(x: .value("Date", entry.date),
                                     y: .value("kg", entry.weightKg))
                                .foregroundStyle(gymAccent)
                                .interpolationMethod(.catmullRom)
                        }
                        if app.targetBodyWeightKg > 0 {
                            RuleMark(y: .value("Target", app.targetBodyWeightKg))
                                .foregroundStyle(Theme.cyan.opacity(0.7))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        }
                    }
                    .frame(height: 150)
                    if let verdict = trajectoryVerdict {
                        Text(verdict).font(.caption).foregroundStyle(Theme.textDim)
                    }
                }
            }
        }
    }

    private var trajectoryVerdict: String? {
        guard app.targetBodyWeightKg > 0, let current = app.currentBodyWeightKg else { return nil }
        if let days = GymAnalysis.daysToTarget(app.bodyWeights, target: app.targetBodyWeightKg) {
            if days <= 0 { return "You are at your target. Hold it." }
            let weeks = max(1, days / 7)
            return "At the current rate you reach \(String(format: "%.1f", app.targetBodyWeightKg)) kg in about \(weeks) week\(weeks == 1 ? "" : "s")."
        }
        let gap = abs(current - app.targetBodyWeightKg)
        return "You are \(String(format: "%.1f", gap)) kg from target and not moving toward it. The rate, not the wish, decides this."
    }

    private var muscleVolumeCard: some View {
        let volume = GymAnalysis.weeklyVolume(in: app.workouts)
        let peak = max(volume.values.max() ?? 0, 1)
        return Card(accent: gymAccent) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Muscle volume \u{2014} last 7 days", tint: gymAccent)
                ForEach(MuscleGroup.allCases) { muscle in
                    let sets = volume[muscle] ?? 0
                    HStack(spacing: 8) {
                        Text(muscle.label)
                            .font(.caption)
                            .frame(width: 78, alignment: .leading)
                            .foregroundStyle(Theme.textPrimary)
                        HUDBar(value: Double(sets) / Double(peak), accent: heatColor(sets))
                        Text("\(sets)")
                            .font(.system(.caption, design: .monospaced))
                            .frame(width: 26, alignment: .trailing)
                            .foregroundStyle(Theme.textDim)
                    }
                }
                if let note = imbalanceNote(volume) {
                    Text(note).font(.caption).foregroundStyle(Theme.gold)
                }
            }
        }
    }

    private func heatColor(_ sets: Int) -> Color {
        switch sets {
        case 0:    return Theme.textDim.opacity(0.4)
        case 1...6: return gymAccent.opacity(0.6)
        default:   return gymAccent
        }
    }

    private func imbalanceNote(_ volume: [MuscleGroup: Int]) -> String? {
        let push = (volume[.chest] ?? 0) + (volume[.shoulders] ?? 0)
        let pull = volume[.back] ?? 0
        if push >= 6 && pull == 0 {
            return "All push, no pull this week \u{2014} you are building an imbalance."
        }
        if pull >= 6 && push == 0 {
            return "All pull, no push this week \u{2014} balance it."
        }
        let trained = volume.values.filter { $0 > 0 }.count
        if trained > 0 && trained <= 2 {
            return "Only \(trained) muscle group\(trained == 1 ? "" : "s") trained this week."
        }
        return nil
    }

    private var recordsCard: some View {
        let records = GymAnalysis.personalRecords(in: app.workouts)
        return Card(accent: gymAccent) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Personal records", tint: gymAccent)
                if records.isEmpty {
                    Text("No lifts logged yet.")
                        .font(.callout)
                        .foregroundStyle(Theme.textDim)
                } else {
                    ForEach(records.prefix(6), id: \.exercise) { record in
                        HStack {
                            Text(record.exercise)
                                .font(.callout)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("\(Int(record.oneRepMax)) kg")
                                .font(.system(.callout, design: .rounded).weight(.semibold))
                                .foregroundStyle(gymAccent)
                            Text("est. 1RM")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Theme.textDim)
                        }
                    }
                }
            }
        }
    }

    private var recommendationsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Exercises by body part")
                Picker("Muscle", selection: $recMuscle) {
                    ForEach(MuscleGroup.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                ForEach(ExerciseLibrary.forMuscle(recMuscle)) { exercise in
                    HStack(spacing: 6) {
                        Image(systemName: "dumbbell.fill")
                            .font(.caption2)
                            .foregroundStyle(gymAccent)
                        Text(exercise.name)
                            .font(.callout)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("Recent workouts")
            if app.workouts.isEmpty {
                Text("No workouts logged. Log your first session above.")
                    .font(.callout)
                    .foregroundStyle(Theme.textDim)
            } else {
                ForEach(app.workouts) { session in
                    workoutRow(session)
                }
            }
        }
    }

    private func workoutRow(_ session: WorkoutSession) -> some View {
        let calories = GymMath.estimatedCalories(
            durationMinutes: session.durationMinutes,
            bodyWeightKg: app.currentBodyWeightKg ?? 75)
        return Card(accent: gymAccent) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(session.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button { app.deleteWorkout(session) } label: {
                        Image(systemName: "trash").accessibilityLabel("Delete workout")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.danger)
                }
                HStack(spacing: 16) {
                    metric("\(session.exercises.count)", "exercises")
                    metric("\(session.totalSets)", "sets")
                    metric("\(Int(session.totalVolumeKg))", "kg vol")
                    metric("~\(calories)", "kcal")
                    metric("\(session.durationMinutes)", "min")
                }
                if !session.exercises.isEmpty {
                    Text(session.exercises.map(\.name).joined(separator: "  \u{00B7}  "))
                        .font(.caption)
                        .foregroundStyle(Theme.textDim)
                }
            }
        }
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.system(.callout, design: .rounded).weight(.semibold))
                .foregroundStyle(gymAccent)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Theme.textDim)
        }
    }

    private func saveWeights() {
        if let weight = Double(weightInput.trimmingCharacters(in: .whitespaces)), weight > 0 {
            app.addBodyWeight(weight)
        }
        if let target = Double(targetInput.trimmingCharacters(in: .whitespaces)), target > 0 {
            app.setTargetBodyWeight(target)
        }
        editingWeight = false
    }
}
