import SwiftUI
import StoicKit

/// Corporate Navigator — the brag document and the growth-network map.
struct BragDocView: View {
    @Environment(AppState.self) private var app

    @State private var showingAddWin = false
    @State private var win = ""
    @State private var metric = ""
    @State private var stakeholders = ""
    @State private var outcome = ""

    @State private var showingAddContact = false
    @State private var contactName = ""
    @State private var contactRole = ""
    @State private var contactRelationship: ContactRelationship = .neutral
    @State private var contactInfluence: InfluenceLevel = .medium

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenTitle("Navigator",
                            subtitle: "Evidence and alliances for your growth.")
                bragSection
                networkSection
            }
            .padding(24)
        }
    }

    // MARK: - Brag document

    private var bragSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel("Brag document", tint: Theme.gold)
                Spacer()
                Button { showingAddWin.toggle() } label: {
                    Label("Log a win", systemImage: "plus").font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.cyan)
            }

            if showingAddWin {
                Card(accent: Theme.gold) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("What did you accomplish?", text: $win)
                        TextField("Metric (e.g. 4.1s -> 2.4s p95)", text: $metric)
                        TextField("Stakeholders", text: $stakeholders)
                        TextField("Business outcome", text: $outcome)
                        HStack {
                            Spacer()
                            Button("Cancel") { resetWin() }
                            Button("Add win") {
                                guard !win.isEmpty else { return }
                                app.addBragEntry(BragEntry(win: win, metric: metric,
                                                           stakeholders: stakeholders,
                                                           outcome: outcome))
                                resetWin()
                            }
                            .buttonStyle(GradientButtonStyle())
                        }
                    }
                }
            }

            if app.bragEntries.isEmpty {
                Text("No wins logged yet.")
                    .font(.callout).foregroundStyle(Theme.textDim)
            } else {
                ForEach(app.bragEntries) { entry in
                    Card(accent: Theme.gold) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.win).font(.headline).foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Button { app.deleteBragEntry(entry) } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.plain).foregroundStyle(Theme.danger)
                            }
                            if !entry.metric.isEmpty { detail("Metric", entry.metric) }
                            if !entry.stakeholders.isEmpty { detail("Stakeholders", entry.stakeholders) }
                            if !entry.outcome.isEmpty { detail("Outcome", entry.outcome) }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Network map

    private var networkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel("Network map")
                Spacer()
                Button { showingAddContact.toggle() } label: {
                    Label("Add contact", systemImage: "plus").font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.cyan)
            }

            if showingAddContact {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Name", text: $contactName)
                        TextField("Role (e.g. skip-level, PM, peer)", text: $contactRole)
                        Picker("Relationship", selection: $contactRelationship) {
                            ForEach(ContactRelationship.allCases, id: \.self) {
                                Text($0.label).tag($0)
                            }
                        }
                        .pickerStyle(.segmented).labelsHidden()
                        Picker("Influence", selection: $contactInfluence) {
                            ForEach(InfluenceLevel.allCases, id: \.self) {
                                Text($0.label).tag($0)
                            }
                        }
                        .pickerStyle(.segmented).labelsHidden()
                        HStack {
                            Spacer()
                            Button("Cancel") { resetContact() }
                            Button("Add") {
                                guard !contactName.isEmpty else { return }
                                app.addContact(Contact(name: contactName, role: contactRole,
                                                       relationship: contactRelationship,
                                                       influence: contactInfluence))
                                resetContact()
                            }
                            .buttonStyle(GradientButtonStyle())
                        }
                    }
                }
            }

            if app.contacts.isEmpty {
                Card {
                    Text("No contacts mapped. Add the people who matter for your growth — manager, skip-level, allies, rivals — and read the power honestly.")
                        .font(.callout).foregroundStyle(Theme.textDim)
                }
            } else {
                ForEach(app.contacts) { contact in
                    Card(accent: color(for: contact.relationship)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contact.name)
                                    .font(.callout.weight(.medium))
                                    .foregroundStyle(Theme.textPrimary)
                                if !contact.role.isEmpty {
                                    Text(contact.role)
                                        .font(.caption).foregroundStyle(Theme.textDim)
                                }
                            }
                            Spacer()
                            Text(contact.relationship.label.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(color(for: contact.relationship))
                            Text("· \(contact.influence.label) influence")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(Theme.textDim)
                            Button { app.deleteContact(contact) } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain).foregroundStyle(Theme.danger)
                        }
                    }
                }
            }
        }
    }

    private func color(for relationship: ContactRelationship) -> Color {
        switch relationship {
        case .advocate: return Theme.ok
        case .neutral:  return Theme.textDim
        case .rival:    return Theme.danger
        }
    }

    private func detail(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(key + ":")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textDim)
            Text(value).font(.caption).foregroundStyle(Theme.textPrimary)
        }
    }

    private func resetWin() {
        win = ""; metric = ""; stakeholders = ""; outcome = ""; showingAddWin = false
    }

    private func resetContact() {
        contactName = ""; contactRole = ""
        contactRelationship = .neutral; contactInfluence = .medium
        showingAddContact = false
    }
}
