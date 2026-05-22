import SwiftUI

/// Top-level routing: app lock → onboarding → main app.
struct RootView: View {
    @Environment(AppState.self) private var app
    @State private var booted = false

    var body: some View {
        ZStack {
            Group {
                if app.appLockEnabled && !app.isUnlocked {
                    AppLockView()
                } else if !app.hasCompletedOnboarding {
                    OnboardingView()
                } else {
                    MainSplitView()
                }
            }
            .animation(.default, value: app.isUnlocked)
            .animation(.default, value: app.hasCompletedOnboarding)

            if !booted {
                BootView {
                    withAnimation(.easeOut(duration: 0.4)) { booted = true }
                }
                .transition(.opacity)
            }
        }
        .task { NotificationManager.requestAndSchedule() }
    }
}

/// The sidebar + content shell.
struct MainSplitView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app
        NavigationSplitView {
            List(AppSection.allCases, selection: $app.section) { section in
                Label {
                    Text(section.title)
                } icon: {
                    Image(systemName: section.systemImage)
                        .foregroundStyle(section.accent)
                }
                .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 216, max: 252)
            .navigationTitle("STOIC OS")
        } detail: {
            ZStack {
                Theme.appBackground.ignoresSafeArea()
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch app.section {
        case .dashboard: DashboardView()
        case .decisions: DecisionView()
        case .goals:     GoalsView()
        case .timetable: TimetableView()
        case .timeAudit: TimeAuditView()
        case .vitals:    VitalsView()
        case .bragDoc:      BragDocView()
        case .constitution: ConstitutionView()
        case .discipline:   DisciplineView()
        case .settings:     SettingsView()
        }
    }
}
