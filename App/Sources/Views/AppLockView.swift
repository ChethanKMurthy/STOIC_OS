import SwiftUI
import LocalAuthentication

/// App lock — a UI gate (not encryption).
struct AppLockView: View {
    @Environment(AppState.self) private var app
    @State private var failed = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "lock.shield")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("STOIC OS")
                .font(.largeTitle.weight(.semibold))
            Text("This Mac's record of how you think and decide.\nUnlock to continue.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button {
                authenticate()
            } label: {
                Label("Unlock", systemImage: "touchid")
                    .padding(.horizontal, 10)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            if failed {
                Text("Authentication failed — try again.")
                    .font(.callout)
                    .foregroundStyle(.red)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.appBackground.ignoresSafeArea())
        .onAppear { authenticate() }
    }

    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No biometrics or password set — do not lock the user out.
            app.isUnlocked = true
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication,
                               localizedReason: "Unlock STOIC OS") { success, _ in
            Task { @MainActor in
                if success { app.isUnlocked = true } else { failed = true }
            }
        }
    }
}
