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
                .frame(minWidth: 940, minHeight: 660)
        }
        .windowResizability(.contentSize)
    }
}

/// Build-wide configuration constants.
enum AppConfig {
    /// Default MLX model. Small (~1.8 GB) so first-run download is reliable.
    /// Change in Settings to a 7B/14B for stronger reasoning.
    static let defaultModelID = "mlx-community/Llama-3.2-3B-Instruct-4bit"
    static let appName = "STOIC OS"
    static let version = "0.1.0 (V0)"
}
