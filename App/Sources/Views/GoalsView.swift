import SwiftUI
import StoicKit

/// Goals screen — capture goals and decompose them into a plan.
struct GoalsView: View {
    @Environment(AppState.self) private var app
    @State private var showingAdd = false
    @State private var title = ""
    @State private var timeline = ""
    @State private var baseline = ""
    @State private var planningGoalId: UUID?
    @State private var planError: String?
    @State private var planProgress: Double = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ScreenTitle("Goals")
                    Spacer()
                    Button {
                        showingAdd.toggle()
                    } label: {
                        Label("New Goal", systemImage: "plus")
                    }
                    .buttonStyle(GradientButtonStyle())
                }

                if showingAdd { addForm }

                if let planError {
                    Card(accent: Theme.danger) {
                        Label(planError, systemImage: "exclamationmark.triangle")
                            .font(.callout)
                            .foregroundStyle(Theme.danger)
                    }
                }

                if app.goals.isEmpty {
                    Text("No goals yet. Add one above.")
                        .foregroundStyle(Theme.textDim)
                } else {
                    ForEach(app.goals) { goal in
                        goalCard(goal)
                    }
                }
            }
            .padding(24)
        }
    }

    private var addForm: some View {
        Card(accent: Theme.closer) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("New goal", tint: Theme.closer)
                TextField("Goal — who you want to become / what to achieve", text: $title)
                    .textFieldStyle(.roundedBorder)
                TextField("Timeline (e.g. by Dec 2026)", text: $timeline)
                    .textFieldStyle(.roundedBorder)
                TextField("Where you are now (baseline)", text: $baseline)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Spacer()
                    Button("Cancel") { reset() }
                    Button("Add goal") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        app.addGoal(Goal(title: title, timeline: timeline, baseline: baseline))
                        reset()
                    }
                    .buttonStyle(GradientButtonStyle())
                }
            }
        }
    }

    private func goalCard(_ goal: Goal) -> some View {
        let tasks = app.tasksFor(goal)
        let milestones = app.milestonesFor(goal)
        let progress = tasks.isEmpty
            ? goal.progress
            : Double(tasks.filter { $0.status == .done }.count) / Double(tasks.count)

        return Card(accent: Theme.closer) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button {
                        app.deleteGoal(goal)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.danger)
                    .help("Delete goal")
                    .accessibilityLabel("Delete goal")
                }
                HStack {
                    HUDBar(value: progress, accent: Theme.closer)
                    Text("\(Int(progress * 100))%")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textDim)
                }
                if !goal.timeline.isEmpty {
                    Text(goal.timeline).font(.caption).foregroundStyle(Theme.textDim)
                }

                if planningGoalId == goal.id {
                    if planProgress > 0 && planProgress < 1 {
                        VStack(alignment: .leading, spacing: 4) {
                            HUDBar(value: planProgress, accent: Theme.cyan)
                            Text("Loading model\u{2026} \(Int(planProgress * 100))%  \u{2014} first run downloads it once.")
                                .font(.caption)
                                .foregroundStyle(Theme.textDim)
                        }
                    } else {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text("Breaking it down\u{2026}")
                                .font(.callout)
                                .foregroundStyle(Theme.textDim)
                        }
                    }
                } else if milestones.isEmpty && tasks.isEmpty {
                    Button {
                        breakDown(goal)
                    } label: {
                        Label("Break this down", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(GradientButtonStyle())
                } else {
                    planView(goal: goal, milestones: milestones, tasks: tasks)
                }
            }
        }
    }

    @ViewBuilder
    private func planView(goal: Goal, milestones: [Milestone], tasks: [MicroTask]) -> some View {
        if !milestones.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                SectionLabel("Milestones")
                ForEach(milestones) { milestone in
                    Button {
                        app.toggleMilestone(milestone)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: milestone.done ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(milestone.done ? Theme.ok : Theme.textDim)
                            Text(milestone.title)
                                .font(.callout)
                                .foregroundStyle(Theme.textPrimary)
                                .strikethrough(milestone.done)
                            Spacer()
                            if !milestone.targetDate.isEmpty {
                                Text(milestone.targetDate)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(Theme.textDim)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        if !tasks.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                SectionLabel("Micro-tasks")
                ForEach(tasks) { task in
                    Button {
                        app.toggleMicroTask(task)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: task.status == .done ? "checkmark.square.fill" : "square")
                                .foregroundStyle(task.status == .done ? Theme.ok : Theme.textDim)
                            Text(task.title)
                                .font(.callout)
                                .foregroundStyle(Theme.textPrimary)
                                .strikethrough(task.status == .done)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        if let reading = goal.readingSuggestions, !reading.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                SectionLabel("Reading & activities", tint: Theme.gold)
                ForEach(reading, id: \.self) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Text("\u{2022}").foregroundStyle(Theme.gold)
                        Text(item).font(.callout).foregroundStyle(Theme.textDim)
                    }
                }
            }
        }
        Button {
            breakDown(goal)
        } label: {
            Label("Re-plan", systemImage: "arrow.clockwise").font(.caption)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.cyan)
    }

    private func breakDown(_ goal: Goal) {
        planError = nil
        planProgress = 0
        planningGoalId = goal.id
        Task {
            for await event in app.engine.plan(goal: goal.title,
                                               timeline: goal.timeline,
                                               baseline: goal.baseline) {
                switch event {
                case .modelLoading(let fraction):
                    planProgress = fraction
                case .finished(let output):
                    app.applyGoalPlan(output, to: goal)
                case .failed(let message):
                    planError = message
                }
            }
            planningGoalId = nil
            planProgress = 0
        }
    }

    private func reset() {
        title = ""
        timeline = ""
        baseline = ""
        showingAdd = false
    }
}
