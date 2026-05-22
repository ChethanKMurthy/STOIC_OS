import SwiftUI

/// Top-level routing: app lock → onboarding → main app.
struct RootView: View {
    @Environment(AppState.self) private var app

    var body: some View {
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
    }
}

/// The sidebar + content shell.
struct MainSplitView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app
        NavigationSplitView {
            List(AppSection.allCases, selection: $app.section) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 240)
            .navigationTitle("STOIC OS")
        } detail: {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        case .bragDoc:   BragDocView()
        case .idealSelf: IdealSelfView()
        case .settings:  SettingsView()
        }
    }
}
