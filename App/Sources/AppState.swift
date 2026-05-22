import SwiftUI
import Observation
import StoicKit

/// The navigable sections of the app.
enum AppSection: String, CaseIterable, Identifiable {
    case dashboard, decisions, goals, timetable, timeAudit, bragDoc, constitution, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:    return "Dashboard"
        case .decisions:    return "Decisions"
        case .goals:        return "Goals"
        case .timetable:    return "Timetable"
        case .timeAudit:    return "Time Audit"
        case .bragDoc:      return "Brag Doc"
        case .constitution: return "Constitution"
        case .settings:     return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:    return "square.grid.2x2"
        case .decisions:    return "brain.head.profile"
        case .goals:        return "target"
        case .timetable:    return "calendar.day.timeline.left"
        case .timeAudit:    return "clock.badge.checkmark"
        case .bragDoc:      return "trophy"
        case .constitution: return "building.columns"
        case .settings:     return "gearshape"
        }
    }

    var accent: Color {
        switch self {
        case .dashboard:    return Theme.accent2
        case .decisions:    return Theme.cyan
        case .goals:        return Theme.closer
        case .timetable:    return Theme.further
        case .timeAudit:    return Color(red: 0.30, green: 0.80, blue: 0.80)
        case .bragDoc:      return Theme.gold
        case .constitution: return Theme.gold
        case .settings:     return Theme.neutral
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

    var constitution: ConstitutionModel
    var goals: [Goal]
    var timeBlocks: [TimeBlock]
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
        self.constitution = store.load(ConstitutionModel.self, "constitution") ?? ConstitutionModel()
        self.goals = store.load([Goal].self, "goals") ?? AppState.seedGoals
        self.timeBlocks = store.load([TimeBlock].self, "timeblocks") ?? AppState.seedBlocks
        self.bragEntries = store.load([BragEntry].self, "brag") ?? AppState.seedBrag
        self.checkins = store.load([HourlyCheckin].self, "checkins") ?? []
        self.decisions = store.load([DecisionRecord].self, "decisions") ?? []
        self.engine = ReasoningEngine(provider: LocalLLMProvider(modelID: modelID))
    }

    // MARK: - Lifecycle

    func completeOnboarding(constitution: ConstitutionModel) {
        self.constitution = constitution
        store.save(constitution, "constitution")
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

    // MARK: - Decisions

    func saveDecision(_ record: DecisionRecord) {
        decisions.insert(record, at: 0)
        store.save(decisions, "decisions")
    }

    // MARK: - Goals

    func addGoal(_ goal: Goal) {
        goals.append(goal)
        store.save(goals, "goals")
    }

    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        store.save(goals, "goals")
    }

    // MARK: - Timetable

    func addTimeBlock(_ block: TimeBlock) {
        timeBlocks.append(block)
        store.save(timeBlocks, "timeblocks")
    }

    func deleteTimeBlock(_ block: TimeBlock) {
        timeBlocks.removeAll { $0.id == block.id }
        store.save(timeBlocks, "timeblocks")
    }

    func updateTimeBlock(_ block: TimeBlock) {
        if let index = timeBlocks.firstIndex(where: { $0.id == block.id }) {
            timeBlocks[index] = block
            store.save(timeBlocks, "timeblocks")
        }
    }

    // MARK: - Brag document

    func addBragEntry(_ entry: BragEntry) {
        bragEntries.insert(entry, at: 0)
        store.save(bragEntries, "brag")
    }

    func deleteBragEntry(_ entry: BragEntry) {
        bragEntries.removeAll { $0.id == entry.id }
        store.save(bragEntries, "brag")
    }

    // MARK: - Time audit

    func addCheckin(_ checkin: HourlyCheckin) {
        checkins.insert(checkin, at: 0)
        store.save(checkins, "checkins")
    }

    // MARK: - Constitution

    func saveConstitution(_ model: ConstitutionModel) {
        constitution = model
        store.save(model, "constitution")
    }

    // MARK: - Seed data (first launch)

    static let seedGoals: [Goal] = [
        Goal(title: "Become a confident public speaker", timeline: "by Dec 2026",
             baseline: "Avoid speaking in large meetings", progress: 0.46),
        Goal(title: "Get promoted to Senior", timeline: "by Q2 2027",
             baseline: "Mid-level, low visibility", progress: 0.28)
    ]

    static let seedBlocks: [TimeBlock] = [
        TimeBlock(title: "Deep work", startHour: 9, durationHours: 2),
        TimeBlock(title: "Reading", startHour: 11),
        TimeBlock(title: "Exercise", startHour: 16)
    ]

    static let seedBrag: [BragEntry] = [
        BragEntry(win: "Cut onboarding flow load time 40%",
                  metric: "4.1 s -> 2.4 s p95",
                  stakeholders: "Platform team, Growth PM",
                  outcome: "+6% activation, cited in the Q2 review")
    ]
}
