import SwiftUI
import StoicKit

/// Daily timetable screen — editable blocks. Automatic planning and calendar
/// sync are planned.
struct TimetableView: View {
    @Environment(AppState.self) private var app
    @State private var showingAdd = false
    @State private var newTitle = ""
    @State private var newHour = 9

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ScreenTitle("Timetable",
                                subtitle: Date.now.formatted(date: .abbreviated, time: .omitted))
                    Spacer()
                    Button {
                        app.planDay()
                    } label: {
                        Label("Plan my day", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(GradientButtonStyle())
                    Button {
                        showingAdd.toggle()
                    } label: {
                        Label("Add block", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                }

                recoveryBanner

                if showingAdd { addForm }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel("Today")
                        if app.timeBlocks.isEmpty {
                            Text("No blocks scheduled. Add one above.")
                                .font(.callout)
                                .foregroundStyle(Theme.textDim)
                        } else {
                            ForEach(app.timeBlocks.sorted { $0.startHour < $1.startHour }) { block in
                                blockRow(block)
                            }
                        }
                    }
                }

                ComingSoonNote(module: "Automatic planning and Google / Teams calendar sync")
            }
            .padding(24)
        }
    }

    @ViewBuilder
    private var recoveryBanner: some View {
        if case .connected = app.whoop.state, let recovery = app.whoop.vitals.recoveryPercent {
            if recovery < 34 {
                Card(accent: Theme.danger) {
                    Label("Recovery \(recovery)% — depleted. Defer the demanding blocks today.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(Theme.danger)
                }
            } else if recovery < 67 {
                Card(accent: Theme.gold) {
                    Label("Recovery \(recovery)% — moderate. Pace the demanding blocks.",
                          systemImage: "gauge.medium")
                        .font(.callout)
                        .foregroundStyle(Theme.gold)
                }
            }
        }
    }

    private var addForm: some View {
        Card(accent: Theme.further) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel("New block", tint: Theme.further)
                TextField("What is this block?", text: $newTitle)
                    .textFieldStyle(.roundedBorder)
                Stepper("Start  \(hourLabel(newHour))", value: $newHour, in: 0...23)
                    .font(.system(.callout, design: .monospaced))
                HStack {
                    Spacer()
                    Button("Cancel") { reset() }
                    Button("Add") {
                        guard !newTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        app.addTimeBlock(TimeBlock(title: newTitle, startHour: newHour))
                        reset()
                    }
                    .buttonStyle(GradientButtonStyle())
                }
            }
        }
    }

    private func blockRow(_ block: TimeBlock) -> some View {
        HStack(spacing: 12) {
            Text(hourLabel(block.startHour))
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(Theme.cyan)
                .frame(width: 60, alignment: .leading)
            Rectangle()
                .fill(block.done ? Theme.ok
                      : (block.sourceTaskId != nil ? Theme.closer : Theme.cyan))
                .frame(width: 3, height: 22)
            Text(block.title)
                .font(.callout)
                .foregroundStyle(block.done ? Theme.textDim : Theme.textPrimary)
                .strikethrough(block.done)
            Spacer()
            Button { move(block, by: -1) } label: {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.plain).foregroundStyle(Theme.textDim)
            .accessibilityLabel("Move earlier")
            Button { move(block, by: 1) } label: {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.plain).foregroundStyle(Theme.textDim)
            .accessibilityLabel("Move later")
            Button { toggleDone(block) } label: {
                Image(systemName: block.done ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.plain).foregroundStyle(block.done ? Theme.ok : Theme.textDim)
            .accessibilityLabel(block.done ? "Mark not done" : "Mark done")
            Button { app.deleteTimeBlock(block) } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain).foregroundStyle(Theme.danger)
            .accessibilityLabel("Delete block")
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        String(format: "%02d:00", ((hour % 24) + 24) % 24)
    }

    private func move(_ block: TimeBlock, by delta: Int) {
        var updated = block
        updated.startHour = min(23, max(0, updated.startHour + delta))
        app.updateTimeBlock(updated)
    }

    private func toggleDone(_ block: TimeBlock) {
        var updated = block
        updated.done.toggle()
        app.updateTimeBlock(updated)
    }

    private func reset() {
        newTitle = ""
        newHour = 9
        showingAdd = false
    }
}
