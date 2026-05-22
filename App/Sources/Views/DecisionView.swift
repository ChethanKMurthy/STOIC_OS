import SwiftUI
import StoicKit

/// Decision session — the core on-device reasoning flow.
struct DecisionView: View {
    @Environment(AppState.self) private var app
    @State private var vm = DecisionViewModel()

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

    private var inputForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("What are you deciding? Describe the situation in your own words.")
                        .font(.callout)
                    TextEditor(text: $vm.situation)
                        .font(.body)
                        .frame(height: 130)
                        .padding(6)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(.secondary.opacity(0.3)))
                    Picker("Type", selection: $vm.isPast) {
                        Text("A choice ahead").tag(false)
                        Text("Something already happened").tag(true)
                    }
                    .pickerStyle(.radioGroup)
                    .horizontalRadioGroupLayout()
                }
            }
            Button {
                vm.run(engine: app.engine) { record in app.saveDecision(record) }
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
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Recent decisions")
                ForEach(app.decisions.prefix(5)) { record in
                    HStack {
                        Text(record.situation)
                            .font(.callout)
                            .lineLimit(1)
                        Spacer()
                        Text(record.createdAt.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func preparingView(_ fraction: Double) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Label("Preparing the local model", systemImage: "arrow.down.circle")
                    .font(.headline)
                ProgressView(value: fraction)
                Text("First run downloads the model once (then it is fully offline). This can take several minutes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var thinkingView: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Reasoning it through…").font(.headline)
                }
                if !vm.streamingText.isEmpty {
                    Text(vm.streamingText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button("Cancel") { vm.cancel() }
                    .buttonStyle(.bordered)
            }
        }
    }

    private func failureView(_ message: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Label("That didn't complete", systemImage: "exclamationmark.triangle")
                    .font(.headline)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Try again") { vm.reset() }
                    .buttonStyle(.borderedProminent)
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

    func run(engine: ReasoningEngine, onSaved: @escaping (DecisionRecord) -> Void) {
        let trimmed = situation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        streamingText = ""
        phase = .thinking
        let past = isPast

        task = Task {
            for await event in engine.decide(situation: trimmed, isPast: past) {
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
                    onSaved(DecisionRecord(situation: trimmed, isPast: past, outputJSON: json))
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
                                .foregroundStyle(option.blocked ? .red : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.label).font(.callout.weight(.medium))
                                Text(option.assessment)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            section("Recommendation") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(output.recommendation.choice)
                        .font(.callout.weight(.semibold))
                    if let condition = output.recommendation.condition,
                       !condition.isEmpty, condition.lowercased() != "null" {
                        Text("Condition: \(condition)")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 8))
            }

            HStack(alignment: .top, spacing: 16) {
                section("Steps") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(output.steps.enumerated()), id: \.offset) { index, step in
                            Text("\(index + 1). \(step)").font(.callout)
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
                section("⚠ \"Don't do this\" filter") {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(output.dontDoThis, id: \.self) { item in
                            Text("• \(item)").font(.callout)
                        }
                    }
                }
            }

            section("Constitution impact") {
                Text("\(output.constitutionImpact.direction.capitalized) — \(output.constitutionImpact.summary)")
            }

            Button("New decision", action: onNew)
                .buttonStyle(.borderedProminent)
        }
    }

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(title)
                content()
            }
        }
    }

    private func consequence(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.caption.weight(.semibold))
            Text(text).font(.callout).foregroundStyle(.secondary)
        }
    }
}
