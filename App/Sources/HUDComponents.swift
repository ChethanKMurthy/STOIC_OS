import SwiftUI

/// A holographic circular gauge — a glowing ring that fills to `value` (0...1).
struct RingGauge: View {
    let value: Double
    var accent: Color = Theme.cyan
    var lineWidth: CGFloat = 10

    @State private var shown = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.cyanDim.opacity(0.22), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: shown ? max(0.001, min(value, 1)) : 0)
                .stroke(accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: accent.opacity(0.75), radius: 8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) { shown = true }
        }
    }
}

/// A holographic progress bar — glowing fill that animates to `value` (0...1).
struct HUDBar: View {
    let value: Double
    var accent: Color = Theme.cyan
    var height: CGFloat = 7

    @State private var shown = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.cyanDim.opacity(0.20))
                Capsule()
                    .fill(accent)
                    .frame(width: geo.size.width * CGFloat(shown ? clamped : 0))
                    .shadow(color: accent.opacity(0.6), radius: 4)
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { shown = true }
        }
    }

    private var clamped: Double { max(0, min(value, 1)) }
}

/// A thin labelled HUD divider.
struct HUDDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.cyanDim.opacity(0.3))
            .frame(height: 1)
    }
}

/// A horizontal scanning sweep — used while the system is processing.
struct ScanLineStrip: View {
    @State private var sweep = false

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(LinearGradient(colors: [.clear, Theme.cyan, .clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: geo.size.width * 0.42)
                .offset(x: sweep ? geo.size.width * 0.58 : -geo.size.width * 0.42)
                .onAppear {
                    withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                        sweep = true
                    }
                }
        }
        .frame(height: 2)
        .clipped()
    }
}
