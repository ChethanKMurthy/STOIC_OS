import SwiftUI
import StoicKit

/// Decision session — the core on-device reasoning flow.
struct DecisionView: View {
    @Environment(AppState.self) private var app
    @State private var vm = DecisionViewModel()
    @State private var outcomeFor: UUID?
    @State private var outcomeText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenTitle("New Decision",
                            subtitle: "Reasoned, on-device. Nothing leaves this Mac.")

                switch vm.phase {
                case .input:
                    inputForm
                case .preparing(let fraction):
                    preparingView(fraction)
                case .thinking:
                    thinkingView
                case .result(let output):
                    DecisionResultView(output: output) { vm.reset() }
                case .failed(let message):
                    failureView(message)
                }
            }
            .padding(24)
        }
    }

    /// The user's current physiology, passed to the reasoning engine as context.
    private var whoopContext: [String] {
        guard case .connected = app.whoop.state else { return [] }
        let vitals = app.whoop.vitals
        var parts: [String] = []
        if let recovery = vitals.recoveryPercent { parts.append("recovery \(recovery)%") }
        if let hrv = vitals.hrvMs { parts.append("HRV \(Int(hrv)) ms") }
        if let sleep = vitals.sleepPerformance { parts.append("sleep \(sleep)%") }
        if let strain = vitals.dayStrain { parts.append(String(format: "day strain %.1f", strain)) }
        guard !parts.isEmpty else { return [] }
        return ["The user's current WHOOP physiology: " + parts.joined(separator: ", ")
                + ". Factor their physical and mental state into the advice."]
    }

    /// Relevant past decisions retrieved from the user's own history.
    private var memoryContext: [String] {
        let situation = vm.situation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !situation.isEmpty else { return [] }
        let relevant = MemoryRetrieval.relevant(to: situation, from: app.decisions, limit: 4)
        guard !relevant.isEmpty else { return [] }
        let lines = relevant.map { record -> String in
            let outcome = (record.outcome?.isEmpty == false)
                ? record.outcome! : "outcome not recorded"
            return "- \"\(record.situation)\" -> \(outcome)"
        }
        return ["Relevant history from the user's own past decisions:"] + lines
    }

    private var inputForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("What are you deciding? Describe the situation in your own words.")
                        .font(.callout)
                        .foregroundStyle(Theme.textPrimary)
                    TextEditor(text: $vm.situation)
                        .font(.body)
                        .frame(height: 130)
                        .scrollContentBackground(.hidden)
                        .padding(6)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.cyanDim.opacity(0.4)))
                    Picker("Type", selection: $vm.isPast) {
                        Text("A choice ahead").tag(false)
                        Text("Something already happened").tag(true)
                    }
                    .pickerStyle(.radioGroup)
                    .horizontalRadioGroupLayout()
                }
            }
            Button {
                vm.run(engine: app.engine, context: whoopContext + memoryContext) { output, record in
                    app.saveDecision(record)
                    app.applyConstitutionImpact(direction: output.constitutionImpact.direction)
                }
            } label: {
                Label("Think it through", systemImage: "brain.head.profile")
            }
            .buttonStyle(GradientButtonStyle())
            .disabled(vm.situation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if !app.decisions.isEmpty {
                recentList
            }
        }
    }

    private var recentList: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel("Recent decisions  ·  log what actually happened")
                ForEach(app.decisions.prefix(6)) { record in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(record.situation)
                                .font(.callout)
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Text(record.createdAt.formatted(.relative(presentation: .named)))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(Theme.textDim)
                        }
                        outcomeRow(record)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func outcomeRow(_ record: DecisionRecord) -> some View {
        if let outcome = record.outcome, !outcome.isEmpty {
            Label(outcome, systemImage: "checkmark.seal")
                .font(.caption)
                .foregroundStyle(Theme.ok)
        } else if outcomeFor == record.id {
            HStack(spacing: 8) {
                TextField("What actually happened?", text: $outcomeText)
                    .textFieldStyle(.roundedBorder)
                Button("Save") {
                    let text = outcomeText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    app.recordDecisionOutcome(record, outcome: text)
                    outcomeFor = nil
                    outcomeText = ""
                }
            }
        } else {
            Button {
                outcomeFor = record.id
                outcomeText = ""
            } label: {
                Label("Log outcome", systemImage: "plus.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.cyan)
        }
    }

    private func preparingView(_ fraction: Double) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Label("Preparing the local model", systemImage: "arrow.down.circle")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                ProgressView(value: fraction)
                Text("First run downloads the model once (then it is fully offline). This can take several minutes.")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            }
        }
    }

    private var thinkingView: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Reasoning it through\u{2026}")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                }
                if !vm.streamingText.isEmpty {
                    Text(vm.streamingText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textDim)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button("Cancel") { vm.cancel() }
                    .buttonStyle(.bordered)
            }
        }
    }

    private func failureView(_ message: String) -> some View {
        Card(accent: Theme.danger) {
            VStack(alignment: .leading, spacing: 10) {
                Label("That didn't complete", systemImage: "exclamationmark.triangle")
                    .font(.headline)
                    .foregroundStyle(Theme.danger)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(Theme.textDim)
                Button("Try again") { vm.reset() }
                    .buttonStyle(GradientButtonStyle())
            }
        }
    }
}

// MARK: - View model

@MainActor
@Observable
final class DecisionViewModel {
    enum Phase: Equatable {
        case input
        case preparing(Double)
        case thinking
        case result(DecisionOutput)
        case failed(String)
    }

    var situation = ""
    var isPast = false
    var phase: Phase = .input
    var streamingText = ""

    private var task: Task<Void, Never>?

    func run(engine: ReasoningEngine,
             context: [String],
             onFinished: @escaping (DecisionOutput, DecisionRecord) -> Void) {
        let trimmed = situation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        streamingText = ""
        phase = .thinking
        let past = isPast

        task = Task {
            for await event in engine.decide(situation: trimmed, isPast: past, context: context) {
                switch event {
                case .modelLoading(let fraction):
                    if fraction < 1.0 { phase = .preparing(fraction) }
                case .token(let delta):
                    if case .result = phase { } else { phase = .thinking }
                    streamingText += delta
                case .finished(let output):
                    phase = .result(output)
                    let data = (try? JSONEncoder.stoic.encode(output)) ?? Data()
                    let json = String(data: data, encoding: .utf8) ?? "{}"
                    let record = DecisionRecord(situation: trimmed, isPast: past, outputJSON: json)
                    onFinished(output, record)
                case .failed(let message):
                    phase = .failed(message)
                }
            }
        }
    }

    func cancel() {
        task?.cancel()
        phase = .input
    }

    func reset() {
        task?.cancel()
        phase = .input
        streamingText = ""
        situation = ""
    }
}

// MARK: - Result rendering

/// Renders a ``DecisionOutput`` as native sections.
struct DecisionResultView: View {
    let output: DecisionOutput
    var onNew: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            section("The real question") {
                Text(output.realQuestion)
            }

            section("Your options") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(output.options) { option in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: option.blocked
                                  ? "xmark.octagon.fill" : "circle")
                                .foregroundStyle(option.blocked ? Theme.danger : Theme.textDim)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.label).font(.callout.weight(.medium))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(option.assessment)
                                    .font(.callout)
                                    .foregroundStyle(Theme.textDim)
                            }
                        }
                    }
                }
            }

            section("Recommendation") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(output.recommendation.choice)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    if let condition = output.recommendation.condition,
                       !condition.isEmpty, condition.lowercased() != "null" {
                        Text("Condition: \(condition)")
                            .font(.callout)
                            .foregroundStyle(Theme.textDim)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cyan.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 8))
            }

            HStack(alignment: .top, spacing: 16) {
                section("Steps") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(output.steps.enumerated()), id: \.offset) { index, step in
                            Text("\(index + 1). \(step)").font(.callout)
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                }
                section("Consequences") {
                    VStack(alignment: .leading, spacing: 6) {
                        consequence("Mental health", output.consequences.mentalHealth)
                        consequence("Character", output.consequences.character)
                        consequence("Identity", output.consequences.identity)
                    }
                }
            }

            section("Most diplomatic approach") {
                Text(output.diplomaticApproach)
            }

            section("Strongest case against") {
                Text(output.counterArgument)
            }

            if let rationalization = output.namedRationalization,
               !rationalization.isEmpty, rationalization.lowercased() != "null" {
                section("A rationalisation to watch") {
                    Text(rationalization)
                }
            }

            if !output.dontDoThis.isEmpty {
                section("\u{26A0} \"Don't do this\" filter") {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(output.dontDoThis, id: \.self) { item in
                            Text("\u{2022} \(item)").font(.callout)
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                }
            }

            section("Constitution impact") {
                Text("\(output.constitutionImpact.direction.capitalized) — \(output.constitutionImpact.summary)")
            }

            Button("New decision", action: onNew)
                .buttonStyle(GradientButtonStyle())
        }
    }

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(title)
                content()
                    .foregroundStyle(Theme.textPrimary)
            }
        }
    }

    private func consequence(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.caption.weight(.semibold))
                .foregroundStyle(Theme.cyan)
            Text(text).font(.callout).foregroundStyle(Theme.textDim)
        }
    }
}
