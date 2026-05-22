import SwiftUI
import StoicKit

private let gymAccent = Color(red: 1.0, green: 0.55, blue: 0.3)

/// The workout-logging sheet — pick exercises by body part and enter sets.
struct LogWorkoutView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var muscle: MuscleGroup = .chest
    @State private var exercises: [LoggedExercise] = []
    @State private var duration = 60

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Log workout")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    pickerCard
                    ForEach($exercises) { $logged in
                        exerciseCard($logged)
                    }
                    Card {
                        Stepper("Duration  \(duration) min",
                                value: $duration, in: 10...240, step: 5)
                            .font(.system(.callout, design: .monospaced))
                    }
                }
                .padding([.horizontal, .bottom])
            }

            Button {
                save()
            } label: {
                Label("Save workout", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GradientButtonStyle())
            .disabled(!canSave)
            .padding()
        }
        .frame(minWidth: 540, minHeight: 580)
        .background(Theme.appBackground)
    }

    private var canSave: Bool {
        exercises.contains { !$0.sets.isEmpty }
    }

    private var pickerCard: some View {
        Card(accent: gymAccent) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Add exercise", tint: gymAccent)
                Picker("Muscle", selection: $muscle) {
                    ForEach(MuscleGroup.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                ForEach(ExerciseLibrary.forMuscle(muscle)) { exercise in
                    Button {
                        addExercise(exercise)
                    } label: {
                        HStack {
                            Text(exercise.name)
                                .font(.callout)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(gymAccent)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func exerciseCard(_ logged: Binding<LoggedExercise>) -> some View {
        Card(accent: gymAccent) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(logged.wrappedValue.name)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button {
                        exercises.removeAll { $0.id == logged.wrappedValue.id }
                    } label: {
                        Image(systemName: "trash").accessibilityLabel("Remove exercise")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.danger)
                }
                ForEach(logged.sets) { $set in
                    HStack(spacing: 6) {
                        TextField("kg", value: $set.weightKg, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 72)
                        Text("kg  \u{00D7}")
                            .font(.caption)
                            .foregroundStyle(Theme.textDim)
                        TextField("reps", value: $set.reps, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 62)
                        Text("reps")
                            .font(.caption)
                            .foregroundStyle(Theme.textDim)
                    }
                }
                Button {
                    addSet(to: logged)
                } label: {
                    Label("Set", systemImage: "plus").font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.cyan)
            }
        }
    }

    private func addExercise(_ exercise: Exercise) {
        // Pre-fill from the last time this lift was trained — a target to beat.
        let lastTop = GymAnalysis.lastTopSet(exercise: exercise.name, in: app.workouts)
        let firstSet = WorkoutSet(weightKg: lastTop?.weightKg ?? 0, reps: lastTop?.reps ?? 0)
        exercises.append(LoggedExercise(
            name: exercise.name,
            muscle: exercise.muscle,
            sets: [firstSet]))
    }

    private func addSet(to logged: Binding<LoggedExercise>) {
        let last = logged.wrappedValue.sets.last
        logged.wrappedValue.sets.append(
            WorkoutSet(weightKg: last?.weightKg ?? 0, reps: last?.reps ?? 0))
    }

    private func save() {
        let valid = exercises.filter { !$0.sets.isEmpty }
        guard !valid.isEmpty else { return }
        app.addWorkout(WorkoutSession(exercises: valid, durationMinutes: duration))
        dismiss()
    }
}
