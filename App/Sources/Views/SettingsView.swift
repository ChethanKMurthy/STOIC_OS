import SwiftUI

/// Settings screen.
struct SettingsView: View {
    @Environment(AppState.self) private var app
    @State private var modelDraft = ""
    @State private var whoopID = ""
    @State private var whoopSecret = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle("Settings")
                aiModelCard
                whoopCard
                privacyCard
                aboutCard
            }
            .padding(24)
        }
        .onAppear {
            modelDraft = app.modelID
            whoopID = app.whoop.clientID
        }
    }

    private var aiModelCard: some View {
        Card(accent: app.modelDownloaded ? Theme.ok : Theme.gold) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel("AI model", tint: app.modelDownloaded ? Theme.ok : Theme.gold)

                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: app.modelDownloaded
                          ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(app.modelDownloaded ? Theme.ok : Theme.gold)
                    Text(app.modelDownloaded
                         ? "Model downloaded \u{2014} reasoning is ready."
                         : "Model not downloaded. Decisions, goal breakdown, and coaching will not work until you download it.")
                        .font(.callout)
                        .foregroundStyle(Theme.textPrimary)
                }

                Text("Active: \(app.modelID)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textDim)

                Text("Pick a model \u{2014} larger reasons better but downloads slower:")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
                HStack(spacing: 8) {
                    modelPick("Fast", id: "mlx-community/Qwen3-4B-4bit", size: "~2.5 GB")
                    modelPick("Balanced", id: "mlx-community/Qwen3-8B-4bit", size: "~4.5 GB")
                    modelPick("Max", id: "mlx-community/Qwen3-14B-4bit", size: "~8 GB")
                }

                if app.modelDownloading {
                    VStack(alignment: .leading, spacing: 4) {
                        HUDBar(value: app.modelProgress, accent: Theme.cyan)
                        Text("Downloading\u{2026} \(Int(app.modelProgress * 100))%  \u{2014} keep the app open.")
                            .font(.caption)
                            .foregroundStyle(Theme.textDim)
                    }
                } else {
                    Button {
                        app.downloadModel()
                    } label: {
                        Label(app.modelDownloaded ? "Reload model" : "Download model",
                              systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(GradientButtonStyle())
                }

                if let error = app.modelError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Theme.danger)
                }

                DisclosureGroup("Advanced \u{2014} custom model id") {
                    HStack {
                        TextField("model id", text: $modelDraft)
                            .textFieldStyle(.roundedBorder)
                        Button("Apply") {
                            let trimmed = modelDraft.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            app.setModelID(trimmed)
                        }
                    }
                    .padding(.top, 4)
                }
                .font(.caption)
                .foregroundStyle(Theme.textDim)
            }
        }
    }

    private func modelPick(_ label: String, id: String, size: String) -> some View {
        let selected = app.modelID == id
        return Button {
            app.setModelID(id)
            modelDraft = id
        } label: {
            VStack(spacing: 2) {
                Text(label).font(.caption.weight(.semibold))
                Text(size).font(.system(size: 9, design: .monospaced))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selected ? Theme.cyan.opacity(0.18) : Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 7)
                .stroke(selected ? Theme.cyan : Theme.cyanDim.opacity(0.4),
                        lineWidth: selected ? 1.5 : 1))
            .foregroundStyle(selected ? Theme.cyan : Theme.textDim)
        }
        .buttonStyle(.plain)
    }

    private var whoopCard: some View {
        Card(accent: Theme.danger) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel("WHOOP connection", tint: Theme.danger)
                Text(whoopStatus)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textDim)
                TextField("Client ID", text: $whoopID)
                    .textFieldStyle(.roundedBorder)
                SecureField("Client Secret", text: $whoopSecret)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Save credentials") {
                        app.whoop.saveCredentials(
                            clientID: whoopID.trimmingCharacters(in: .whitespaces),
                            clientSecret: whoopSecret.trimmingCharacters(in: .whitespaces))
                        whoopSecret = ""
                    }
                    Spacer()
                    whoopConnectButton
                }
                Text("Stored locally on this Mac. Redirect URL: http://localhost:8970/whoop/callback")
                    .font(.caption2).foregroundStyle(Theme.textDim)
            }
        }
    }

    @ViewBuilder
    private var whoopConnectButton: some View {
        switch app.whoop.state {
        case .connected:
            Button("Disconnect") { app.whoop.disconnect() }
        case .connecting:
            ProgressView().controlSize(.small)
        default:
            Button("Connect WHOOP") { Task { await app.whoop.connect() } }
                .buttonStyle(GradientButtonStyle())
        }
    }

    private var whoopStatus: String {
        switch app.whoop.state {
        case .disconnected: return "Not connected."
        case .connecting:   return "Authorizing — finish the login in your browser."
        case .connected:    return "Connected."
        case .failed(let message): return "Failed: \(message)"
        }
    }

    private var privacyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Privacy & security")
                Toggle("Require Touch ID / password to open", isOn: Binding(
                    get: { app.appLockEnabled },
                    set: { app.setAppLock($0) }))
                Text("\u{26A0} V0 stores data unencrypted on disk. The app lock guards the window, not the files — keep macOS FileVault on. WHOOP sync uses the network; reasoning stays on-device.")
                    .font(.caption).foregroundStyle(Theme.textDim)
                Text("Data folder: \(app.store.path)")
                    .font(.caption2).foregroundStyle(Theme.textDim).textSelection(.enabled)
            }
        }
    }

    private var aboutCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel("About")
                Text("\(AppConfig.appName) \(AppConfig.version)")
                    .font(.callout).foregroundStyle(Theme.textPrimary)
                Text("On-device reasoning companion. Early development build — see README.")
                    .font(.caption).foregroundStyle(Theme.textDim)
            }
        }
    }
}
