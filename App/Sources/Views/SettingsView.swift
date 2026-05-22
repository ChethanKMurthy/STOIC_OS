import SwiftUI

/// Settings screen.
struct SettingsView: View {
    @Environment(AppState.self) private var app
    @State private var modelDraft = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle("Settings")

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("AI model")
                        Text("MLX model identifier (Hugging Face). The first run downloads it once, then it is fully offline.")
                            .font(.caption).foregroundStyle(.secondary)
                        TextField("model id", text: $modelDraft)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            Text("Active: \(app.modelID)")
                                .font(.caption).foregroundStyle(.secondary)
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

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Privacy & security")
                        Toggle("Require Touch ID / password to open", isOn: Binding(
                            get: { app.appLockEnabled },
                            set: { app.setAppLock($0) }))
                        Text("⚠ V0 stores data unencrypted on disk. The app lock guards the window, not the files — keep macOS FileVault on. Nothing leaves this Mac.")
                            .font(.caption).foregroundStyle(.secondary)
                        Text("Data folder: \(app.store.path)")
                            .font(.caption2).foregroundStyle(.secondary).textSelection(.enabled)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel("About")
                        Text("\(AppConfig.appName) \(AppConfig.version)")
                            .font(.callout)
                        Text("On-device reasoning companion. Early development build — see README.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(24)
        }
        .onAppear { modelDraft = app.modelID }
    }
}
