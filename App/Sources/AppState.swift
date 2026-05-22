import SwiftUI
import Observation
import StoicKit

/// The navigable sections of the app.
enum AppSection: String, CaseIterable, Identifiable {
    case dashboard, decisions, goals, timetable, timeAudit, bragDoc, idealSelf, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .decisions: return "Decisions"
        case .goals:     return "Goals"
        case .timetable: return "Timetable"
        case .timeAudit: return "Time Audit"
        case .bragDoc:   return "Brag Doc"
        case .idealSelf: return "Ideal Self"
        case .settings:  return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .decisions: return "brain.head.profile"
        case .goals:     return "target"
        case .timetable: return "calendar.day.timeline.left"
        case .timeAudit: return "clock.badge.checkmark"
        case .bragDoc:   return "trophy"
        case .idealSelf: return "figure.stand"
        case .settings:  return "gearshape"
        }
    }
}

/// App-wide observable state. Owns persistence and the reasoning engine.
@MainActor
@Observable
final class AppState {

    var isUnlocked: Bool = false
    var hasCompletedOnboarding: Bool
    var section: AppSection = .dashboard
    var appLockEnabled: Bool

    var idealSelf: IdealSelfModel
    var goals: [Goal]
    var bragEntries: [BragEntry]
    var checkins: [HourlyCheckin]
    var decisions: [DecisionRecord]

    var modelID: String

    let store: FileStore
    private(set) var engine: ReasoningEngine

    init() {
        let store = FileStore()
        let modelID = store.string("modelID") ?? AppConfig.defaultModelID
        self.store = store
        self.modelID = modelID
        self.hasCompletedOnboarding = store.flag("onboarded")
        self.appLockEnabled = store.flag("appLockEnabled_set") ? store.flag("appLockEnabled") : true
        self.idealSelf = store.load(IdealSelfModel.self, "idealself") ?? IdealSelfModel()
        self.goals = store.load([Goal].self, "goals") ?? AppState.seedGoals
        self.bragEntries = store.load([BragEntry].self, "brag") ?? AppState.seedBrag
        self.checkins = store.load([HourlyCheckin].self, "checkins") ?? []
        self.decisions = store.load([DecisionRecord].self, "decisions") ?? []
        self.engine = ReasoningEngine(provider: LocalLLMProvider(modelID: modelID))
    }

    // MARK: - Lifecycle

    func completeOnboarding(idealSelf: IdealSelfModel) {
        self.idealSelf = idealSelf
        store.save(idealSelf, "idealself")
        hasCompletedOnboarding = true
        store.setFlag("onboarded", true)
    }

    func setAppLock(_ enabled: Bool) {
        appLockEnabled = enabled
        store.setFlag("appLockEnabled", enabled)
        store.setFlag("appLockEnabled_set", true)
    }

    func setModelID(_ id: String) {
        modelID = id
        store.setString("modelID", id)
        engine = ReasoningEngine(provider: LocalLLMProvider(modelID: id))
    }

    // MARK: - Mutations

    func saveDecision(_ record: DecisionRecord) {
        decisions.insert(record, at: 0)
        store.save(decisions, "decisions")
    }

    func addGoal(_ goal: Goal) {
        goals.append(goal)
        store.save(goals, "goals")
    }

    func addBragEntry(_ entry: BragEntry) {
        bragEntries.insert(entry, at: 0)
        store.save(bragEntries, "brag")
    }

    func addCheckin(_ checkin: HourlyCheckin) {
        checkins.insert(checkin, at: 0)
        store.save(checkins, "checkins")
    }

    func saveIdealSelf(_ model: IdealSelfModel) {
        idealSelf = model
        store.save(model, "idealself")
    }

    // MARK: - Seed data (first launch)

    static let seedGoals: [Goal] = [
        Goal(title: "Become a confident public speaker", timeline: "by Dec 2026",
             baseline: "Avoid speaking in large meetings", progress: 0.46),
        Goal(title: "Get promoted to Senior", timeline: "by Q2 2027",
             baseline: "Mid-level, low visibility", progress: 0.28)
    ]

    static let seedBrag: [BragEntry] = [
        BragEntry(win: "Cut onboarding flow load time 40%",
                  metric: "4.1 s → 2.4 s p95",
                  stakeholders: "Platform team, Growth PM",
                  outcome: "+6% activation, cited in the Q2 review")
    ]
}
