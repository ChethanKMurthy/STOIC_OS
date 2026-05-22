import SwiftUI
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ScreenTitle("Gym",
                                subtitle: "Hold the body to the same standard as everything else.")
                    Spacer()
                    Button { showingLog = true } label: {
                        Label("Log workout", systemImage: "plus")
                    }
                    .buttonStyle(GradientButtonStyle())
                }

                HStack(alignment: .top, spacing: 16) {
                    streakCard
                    bodyWeightCard
                }
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
