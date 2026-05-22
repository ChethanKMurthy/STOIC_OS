import SwiftUI

/// STOIC OS — application entry point.
///
/// A private, on-device reasoning companion. V0 is a single-process app with
/// the Decision Engine wired to a local MLX model. See README for status.
@main
struct StoicOSApp: App {
    @State private var app = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .frame(minWidth: 960, minHeight: 680)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        .windowResizability(.contentSize)
    }
}

/// Build-wide configuration constants.
enum AppConfig {
    /// Default MLX model — a strong 14B reasoning model (~8 GB at 4-bit),
    /// comfortable on Apple Silicon with 24 GB. Changeable in Settings.
    static let defaultModelID = "mlx-community/Qwen3-14B-4bit"
    static let appName = "STOIC OS"
    static let version = "0.1.0 (V0)"
}
