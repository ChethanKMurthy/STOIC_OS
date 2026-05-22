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
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("AI model")
                Text("MLX model identifier (Hugging Face). The first run downloads it once, then it is fully offline.")
                    .font(.caption).foregroundStyle(Theme.textDim)
                TextField("model id", text: $modelDraft)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Text("Active: \(app.modelID)")
                        .font(.caption).foregroundStyle(Theme.textDim)
                    Spacer()
                    Button("Apply model") {
                        let trimmed = modelDraft.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        app.setModelID(trimmed)
                    }
                    .disabled(modelDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
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
                Text("Stored only in your macOS Keychain. Redirect URL: http://localhost:8970/whoop/callback")
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
