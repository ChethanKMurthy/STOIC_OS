import SwiftUI
import StoicKit

private let companionAccent = Color(red: 0.45, green: 0.85, blue: 0.7)

/// Companion screen — an always-open conversation that already holds context.
struct CompanionView: View {
    @Environment(AppState.self) private var app

    @State private var input = ""
    @State private var streaming = ""
    @State private var responding = false

    var body: some View {
        VStack(spacing: 0) {
            header
            messages
            inputBar
        }
        .background(Theme.appBackground)
    }

    private var header: some View {
        HStack {
            ScreenTitle("Companion",
                        subtitle: "Think out loud \u{2014} it knows your context.")
            Spacer()
            if !app.chatMessages.isEmpty {
                Button { app.clearChat() } label: {
                    Image(systemName: "trash").accessibilityLabel("Clear conversation")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.textDim)
            }
        }
        .padding(24)
    }

    private var messages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if app.chatMessages.isEmpty && !responding {
                        emptyState
                    }
                    ForEach(app.chatMessages) { message in
                        bubble(role: message.role, text: message.text)
                            .id(message.id)
                    }
                    if responding {
                        bubble(role: .assistant,
                               text: streaming.isEmpty ? "\u{2026}" : streaming)
                            .id("streaming")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            .onChange(of: app.chatMessages.count) { _, _ in
                withAnimation { proxy.scrollTo(app.chatMessages.last?.id, anchor: .bottom) }
            }
            .onChange(of: streaming) { _, _ in
                withAnimation { proxy.scrollTo("streaming", anchor: .bottom) }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Talk to STOIC OS.")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("Think a decision through, vent, ask for a read on a situation. It already knows your Constitution, your goals, your recovery, and your recent decisions.")
                .font(.callout)
                .foregroundStyle(Theme.textDim)
        }
        .padding(.top, 12)
    }

    private func bubble(role: ChatMessage.Role, text: String) -> some View {
        HStack {
            if role == .user { Spacer(minLength: 60) }
            Text(text)
                .font(.callout)
                .foregroundStyle(Theme.textPrimary)
                .textSelection(.enabled)
                .padding(10)
                .background(role == .user
                            ? Theme.cyan.opacity(0.16)
                            : companionAccent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .overlay(
                    RoundedRectangle(cornerRadius: 11).stroke(
                        (role == .user ? Theme.cyan : companionAccent).opacity(0.4))
                )
                .frame(maxWidth: 520, alignment: .leading)
            if role == .assistant { Spacer(minLength: 60) }
        }
        .frame(maxWidth: .infinity, alignment: role == .user ? .trailing : .leading)
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Talk to STOIC OS\u{2026}", text: $input, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(9)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9)
                    .stroke(Theme.cyanDim.opacity(0.35)))
                .onSubmit { send() }
            Button { send() } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 27))
                    .accessibilityLabel("Send")
            }
            .buttonStyle(.plain)
            .foregroundStyle(canSend ? companionAccent : Theme.textDim)
            .disabled(!canSend)
        }
        .padding(16)
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !responding
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !responding else { return }
        app.addChatMessage(ChatMessage(role: .user, text: text))
        input = ""

        // Acute distress steps out of reasoning and into support.
        if SafetyCheck.isCrisis(text) {
            let resources = SafetyCheck.resources
                .map { "\u{2022} \($0.name): \($0.contact)" }
                .joined(separator: "\n")
            app.addChatMessage(ChatMessage(
                role: .assistant,
                text: SafetyCheck.supportiveMessage + "\n\n" + resources))
            return
        }

        streaming = ""
        responding = true
        let transcript = renderTranscript()
        Task {
            for await event in app.engine.converse(transcript: transcript,
                                                   context: app.companionContext) {
                switch event {
                case .modelLoading:
                    break
                case .token(let token):
                    streaming += token
                case .finished(let full):
                    app.addChatMessage(ChatMessage(role: .assistant, text: full))
                    streaming = ""
                    responding = false
                case .failed(let message):
                    app.addChatMessage(ChatMessage(role: .assistant, text: "[\(message)]"))
                    streaming = ""
                    responding = false
                }
            }
        }
    }

    private func renderTranscript() -> String {
        app.chatMessages.suffix(20).map { message in
            (message.role == .user ? "User: " : "STOIC OS: ") + message.text
        }
        .joined(separator: "\n\n")
    }
}
