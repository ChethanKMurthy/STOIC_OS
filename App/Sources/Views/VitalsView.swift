import SwiftUI

/// Vitals screen — physiological state from WHOOP.
struct VitalsView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenTitle("Vitals", subtitle: "Physiological state — from WHOOP.")
                content
            }
            .padding(24)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch app.whoop.state {
        case .disconnected:
            connectPrompt
        case .connecting:
            Card {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text("Authorizing with WHOOP — complete the login in your browser.")
                        .font(.callout)
                        .foregroundStyle(Theme.textDim)
                }
            }
        case .failed(let message):
            Card(accent: Theme.danger) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("WHOOP connection failed", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                        .foregroundStyle(Theme.danger)
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(Theme.textDim)
                    Button("Open Settings") { app.section = .settings }
                        .buttonStyle(GradientButtonStyle())
                }
            }
        case .connected:
            connectedBody
        }
    }

    private var connectPrompt: some View {
        Card(accent: Theme.danger) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel("WHOOP not connected", tint: Theme.danger)
                Text("Connect your WHOOP account to bring recovery, sleep, and strain into STOIC OS.")
                    .font(.callout)
                    .foregroundStyle(Theme.textDim)
                Button("Connect in Settings") { app.section = .settings }
                    .buttonStyle(GradientButtonStyle())
            }
        }
    }

    private var connectedBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            Card(accent: recoveryColor) {
                HStack(spacing: 24) {
                    RingGauge(value: Double(app.whoop.vitals.recoveryPercent ?? 0) / 100.0,
                              accent: recoveryColor)
                        .frame(width: 120, height: 120)
                        .overlay(
                            VStack(spacing: -2) {
                                Text(app.whoop.vitals.recoveryPercent.map { "\($0)" } ?? "--")
                                    .font(.system(size: 38, weight: .bold, design: .rounded))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("RECOVERY")
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                    .tracking(2)
                                    .foregroundStyle(Theme.textDim)
                            }
                        )
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Today", tint: recoveryColor)
                        Text(recoveryReadout)
                            .font(.callout)
                            .foregroundStyle(Theme.textDim)
                    }
                }
            }

            HStack(spacing: 16) {
                metricCard("HRV", value: app.whoop.vitals.hrvMs.map { String(format: "%.0f", $0) } ?? "--", unit: "ms")
                metricCard("Resting HR", value: app.whoop.vitals.restingHeartRate.map { "\($0)" } ?? "--", unit: "bpm")
            }
            HStack(spacing: 16) {
                metricCard("Sleep", value: app.whoop.vitals.sleepPerformance.map { "\($0)" } ?? "--", unit: "%")
                metricCard("Day strain", value: app.whoop.vitals.dayStrain.map { String(format: "%.1f", $0) } ?? "--", unit: "")
            }

            Card {
                HStack {
                    Text(syncLabel)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textDim)
                    Spacer()
                    Button("Sync now") { Task { await app.whoop.sync() } }
                        .buttonStyle(GradientButtonStyle())
                }
            }
        }
    }

    private func metricCard(_ label: String, value: String, unit: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(label)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text(unit)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textDim)
                }
            }
        }
    }

    private var recoveryColor: Color {
        switch app.whoop.vitals.recoveryPercent ?? -1 {
        case 67...:   return Theme.ok
        case 34..<67: return Theme.gold
        case 0..<34:  return Theme.danger
        default:      return Theme.cyan
        }
    }

    private var recoveryReadout: String {
        if app.whoop.vitals.isEmpty {
            return "No data yet — sync to pull your latest WHOOP readings."
        }
        switch app.whoop.vitals.recoveryPercent ?? -1 {
        case 67...:   return "Recovered. A day to take on demanding work."
        case 34..<67: return "Moderate. Train and decide, but do not overreach."
        case 0..<34:  return "Depleted. Protect recovery; defer heavy decisions."
        default:      return "Recovery score unavailable."
        }
    }

    private var syncLabel: String {
        guard let last = app.whoop.vitals.lastSync else { return "Never synced." }
        return "Last sync: " + last.formatted(date: .abbreviated, time: .shortened)
    }
}
