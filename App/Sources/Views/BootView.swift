import SwiftUI

/// The boot sequence — a brief cinematic HUD start-up shown on launch.
struct BootView: View {
    var onComplete: () -> Void

    @State private var bracketLength: CGFloat = 0
    @State private var titleShown = false
    @State private var statusIndex = 0

    private let statuses = [
        "INITIALISING KERNEL",
        "LOADING CONSTITUTION",
        "SYSTEMS ONLINE"
    ]

    var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()

            VStack(spacing: 18) {
                Text("STOIC OS")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .tracking(10)
                    .foregroundStyle(Theme.cyan)
                    .shadow(color: Theme.cyan.opacity(0.7), radius: 18)
                    .opacity(titleShown ? 1 : 0)
                    .scaleEffect(titleShown ? 1 : 0.92)

                Text(statuses[min(statusIndex, statuses.count - 1)])
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(Theme.textDim)

                if titleShown {
                    ScanLineStrip().frame(width: 220)
                }
            }
            .padding(54)
            .overlay(
                CornerBrackets(inset: 0, length: bracketLength)
                    .stroke(Theme.cyan, lineWidth: 2)
                    .shadow(color: Theme.cyan.opacity(0.6), radius: 8)
            )
        }
        .onAppear { runSequence() }
    }

    private func runSequence() {
        withAnimation(.easeOut(duration: 0.6)) { bracketLength = 50 }
        withAnimation(.easeOut(duration: 0.7).delay(0.3)) { titleShown = true }

        for index in 1..<statuses.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7 + Double(index) * 0.5) {
                statusIndex = index
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            onComplete()
        }
    }
}
