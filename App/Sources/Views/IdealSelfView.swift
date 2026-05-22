import SwiftUI
import StoicKit

/// Ideal Self screen.
struct IdealSelfView: View {
    @Environment(AppState.self) private var app
    @State private var editing = false
    @State private var draftNarrative = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ScreenTitle("Ideal Self", subtitle: "Version \(app.idealSelf.version)")
                    Button(editing ? "Done" : "Edit") {
                        if editing {
                            var model = app.idealSelf
                            model.narrative = draftNarrative
                            app.saveIdealSelf(model)
                        } else {
                            draftNarrative = app.idealSelf.narrative
                        }
                        editing.toggle()
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("The person you are becoming")
                        if editing {
                            TextEditor(text: $draftNarrative)
                                .font(.body)
                                .frame(height: 110)
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(.secondary.opacity(0.3)))
                        } else {
                            Text(app.idealSelf.narrative.isEmpty
                                 ? "Not set." : app.idealSelf.narrative)
                                .font(.body)
                        }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Traits & weights")
                        if app.idealSelf.traits.isEmpty {
                            Text("No traits defined.").font(.callout).foregroundStyle(.secondary)
                        } else {
                            ForEach(app.idealSelf.traits) { trait in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(trait.name).font(.callout)
                                    ProgressView(value: trait.weight)
                                }
                            }
                        }
                    }
                }

                ComingSoonNote(module: "Action scoring against this model and the alignment trajectory chart")
            }
            .padding(24)
        }
    }
}
