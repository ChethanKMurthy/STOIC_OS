import SwiftUI
import Observation
import StoicKit

/// The navigable sections of the app.
enum AppSection: String, CaseIterable, Identifiable {
    case dashboard, decisions, goals, timetable, timeAudit, vitals, bragDoc, constitution, discipline, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:    return "Dashboard"
        case .decisions:    return "Decisions"
        case .goals:        return "Goals"
        case .timetable:    return "Timetable"
        case .timeAudit:    return "Time Audit"
        case .vitals:       return "Vitals"
        case .bragDoc:      return "Navigator"
        case .constitution: return "Constitution"
        case .discipline:   return "Discipline"
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
        case .vitals:       return "waveform.path.ecg"
        case .bragDoc:      return "trophy"
        case .constitution: return "building.columns"
        case .discipline:   return "shield.lefthalf.filled"
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
        case .vitals:       return Theme.danger
        case .bragDoc:      return Theme.gold
        case .constitution: return Theme.gold
        case .discipline:   return Color(red: 0.72, green: 0.52, blue: 1.0)
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
    var trajectory: [TrajectoryPoint]
    var goals: [Goal]
    var milestones: [Milestone]
    var microTasks: [MicroTask]
    var timeBlocks: [TimeBlock]
    var bragEntries: [BragEntry]
    var contacts: [Contact]
    var commitments: [Commitment]
    var checkins: [HourlyCheckin]
    var decisions: [DecisionRecord]

    var modelID: String

    let store: FileStore
    private(set) var engine: ReasoningEngine
    let whoop: WhoopService

    init() {
        let store = FileStore()
        let modelID = store.string("modelID") ?? AppConfig.defaultModelID
        self.store = store
        self.modelID = modelID
        self.hasCompletedOnboarding = store.flag("onboarded")
        self.appLockEnabled = store.flag("appLockEnabled_set") ? store.flag("appLockEnabled") : true
        self.constitution = store.load(ConstitutionModel.self, "constitution") ?? ConstitutionModel()
        self.trajectory = store.load([TrajectoryPoint].self, "trajectory") ?? []
        self.goals = store.load([Goal].self, "goals") ?? AppState.seedGoals
        self.milestones = store.load([Milestone].self, "milestones") ?? []
        self.microTasks = store.load([MicroTask].self, "microtasks") ?? []
        self.timeBlocks = store.load([TimeBlock].self, "timeblocks") ?? AppState.seedBlocks
        self.bragEntries = store.load([BragEntry].self, "brag") ?? AppState.seedBrag
        self.contacts = store.load([Contact].self, "contacts") ?? []
        self.commitments = store.load([Commitment].self, "commitments") ?? []
        self.checkins = store.load([HourlyCheckin].self, "checkins") ?? []
        self.decisions = store.load([DecisionRecord].self, "decisions") ?? []
        self.engine = ReasoningEngine(provider: LocalLLMProvider(modelID: modelID))
        self.whoop = WhoopService(store: store)
        processOverdueCommitments()
    }

    // MARK: - Lifecycle

    func completeOnboarding(constitution: ConstitutionModel) {
        self.constitution = constitution
        store.save(constitution, "constitution")
        recordTrajectory()
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

    func recordDecisionOutcome(_ decision: DecisionRecord, outcome: String) {
        guard let index = decisions.firstIndex(where: { $0.id == decision.id }) else { return }
        decisions[index].outcome = outcome
        store.save(decisions, "decisions")
    }

    // MARK: - Goals

    func addGoal(_ goal: Goal) {
        goals.append(goal)
        store.save(goals, "goals")
    }

    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        milestones.removeAll { $0.goalId == goal.id }
        microTasks.removeAll { $0.goalId == goal.id }
        store.save(goals, "goals")
        store.save(milestones, "milestones")
        store.save(microTasks, "microtasks")
    }

    func milestonesFor(_ goal: Goal) -> [Milestone] {
        milestones.filter { $0.goalId == goal.id }
    }

    func tasksFor(_ goal: Goal) -> [MicroTask] {
        microTasks.filter { $0.goalId == goal.id }
    }

    /// Replace a goal's plan with a freshly decomposed one.
    func applyGoalPlan(_ plan: GoalPlanOutput, to goal: Goal) {
        milestones.removeAll { $0.goalId == goal.id }
        milestones.append(contentsOf: plan.milestones.map {
            Milestone(goalId: goal.id, title: $0.title, targetDate: $0.targetDate)
        })
        microTasks.removeAll { $0.goalId == goal.id }
        microTasks.append(contentsOf: plan.microTasks.map {
            MicroTask(goalId: goal.id, title: $0)
        })
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index].readingSuggestions = plan.readingAndActivities
        }
        store.save(milestones, "milestones")
        store.save(microTasks, "microtasks")
        store.save(goals, "goals")
    }

    func toggleMilestone(_ milestone: Milestone) {
        guard let index = milestones.firstIndex(where: { $0.id == milestone.id }) else { return }
        milestones[index].done.toggle()
        store.save(milestones, "milestones")
    }

    func toggleMicroTask(_ task: MicroTask) {
        guard let index = microTasks.firstIndex(where: { $0.id == task.id }) else { return }
        microTasks[index].status = microTasks[index].status == .done ? .pending : .done
        store.save(microTasks, "microtasks")
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
        // A goal-sourced block completing also completes its micro-task.
        if let taskId = block.sourceTaskId,
           let taskIndex = microTasks.firstIndex(where: { $0.id == taskId }) {
            microTasks[taskIndex].status = block.done ? .done : .pending
            store.save(microTasks, "microtasks")
        }
    }

    /// Auto-fill the day with pending micro-tasks from goals. The number of
    /// tasks scheduled scales down when WHOOP recovery is low. Regenerates the
    /// goal-sourced blocks; manually added blocks are left untouched.
    func planDay() {
        timeBlocks.removeAll { $0.sourceTaskId != nil }
        let occupied = Set(timeBlocks.map { $0.startHour })
        let pending = microTasks.filter { $0.status == .pending }
        var hour = 9
        for task in pending.prefix(plannedTaskCap) {
            while hour < 22 && occupied.contains(hour) { hour += 1 }
            guard hour < 22 else { break }
            timeBlocks.append(TimeBlock(title: task.title,
                                        startHour: hour,
                                        sourceTaskId: task.id))
            hour += 1
        }
        store.save(timeBlocks, "timeblocks")
    }

    /// How many goal tasks to schedule today — fewer when recovery is low.
    private var plannedTaskCap: Int {
        if case .connected = whoop.state, let recovery = whoop.vitals.recoveryPercent {
            switch recovery {
            case 0..<34:  return 3
            case 34..<67: return 6
            default:      return 9
            }
        }
        return 8
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

    func addContact(_ contact: Contact) {
        contacts.append(contact)
        store.save(contacts, "contacts")
    }

    func deleteContact(_ contact: Contact) {
        contacts.removeAll { $0.id == contact.id }
        store.save(contacts, "contacts")
    }

    // MARK: - Commitments

    func addCommitment(_ commitment: Commitment) {
        commitments.append(commitment)
        store.save(commitments, "commitments")
    }

    func keepCommitment(_ commitment: Commitment) {
        guard let index = commitments.firstIndex(where: { $0.id == commitment.id }) else { return }
        commitments[index].status = .kept
        store.save(commitments, "commitments")
        applyConstitutionNudge(3)
    }

    func breakCommitment(_ commitment: Commitment, reason: String) {
        guard let index = commitments.firstIndex(where: { $0.id == commitment.id }) else { return }
        commitments[index].status = .broken
        commitments[index].brokenReason = reason
        store.save(commitments, "commitments")
        applyConstitutionNudge(-5)
    }

    func deleteCommitment(_ commitment: Commitment) {
        commitments.removeAll { $0.id == commitment.id }
        store.save(commitments, "commitments")
    }

    /// A lapsed commitment is broken automatically — and the stake is paid.
    private func processOverdueCommitments() {
        var changed = false
        for index in commitments.indices
        where commitments[index].status == .active && commitments[index].deadline < Date() {
            commitments[index].status = .broken
            commitments[index].brokenReason = "Deadline passed without action."
            changed = true
            applyConstitutionNudge(-5)
        }
        if changed { store.save(commitments, "commitments") }
    }

    // MARK: - Time audit

    func addCheckin(_ checkin: HourlyCheckin) {
        checkins.insert(checkin, at: 0)
        store.save(checkins, "checkins")
        applyConstitutionNudge(checkin.quality == .productive ? 1 : -2)
    }

    // MARK: - Constitution

    func saveConstitution(_ model: ConstitutionModel) {
        constitution = model
        store.save(model, "constitution")
        recordTrajectory()
    }

    /// Record today's Integrity Score on the trajectory (one point per day).
    private func recordTrajectory() {
        let score = constitution.integrityScore
        if let index = trajectory.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
            trajectory[index].integrityScore = score
        } else {
            trajectory.append(TrajectoryPoint(integrityScore: score))
        }
        if trajectory.count > 120 {
            trajectory.removeFirst(trajectory.count - 120)
        }
        store.save(trajectory, "trajectory")
    }

    /// A decision verdict moves the Constitution toward or away from the ideal.
    func applyConstitutionImpact(direction: String) {
        switch direction.lowercased() {
        case "closer":  applyConstitutionNudge(2)
        case "further": applyConstitutionNudge(-3)
        default:        break
        }
    }

    private func applyConstitutionNudge(_ delta: Int) {
        guard delta != 0, !constitution.traits.isEmpty else { return }
        var updated = constitution
        updated.traits = ConstitutionScoring.nudged(updated.traits, by: delta)
        saveConstitution(updated)
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
