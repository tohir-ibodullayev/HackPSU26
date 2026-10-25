import Foundation

private final class MemoryStore: StudentStateStoring {
    var value: StudentState?
    func load() throws -> StudentState? { value }
    func save(_ state: StudentState) throws { value = state }
    func clear() { value = nil }
}
private struct DelayedBuddy: BuddyServiceProtocol {
    func reply(to text: String, context: BuddyContext) async throws -> BuddyReply {
        try await Task.sleep(nanoseconds: 20_000_000)
        return BuddyReply(text: "Late reply")
    }
}

@main
struct CampusMateChecks {
    @MainActor static func main() async throws {
        var checks = 0
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            guard condition() else { fatalError("FAIL: \(message)") }
            checks += 1
        }
        func close(_ value: Double?, _ expected: Double) -> Bool {
            value.map { abs($0 - expected) < 0.00001 } ?? false
        }
        let store = MemoryStore()
        let app = AppModel(buddy: DelayedBuddy(), store: store)
        app.beginDemo()
        check(app.needsOnboarding, "demo begins with onboarding")
        check(app.courses.count == 2, "two labeled demo courses")
        check(app.courses.allSatisfy { $0.isDemo && $0.assessments.allSatisfy { $0.score == nil } }, "no invented grades")
        var course = app.courses[0]
        let calculator = LocalGradeCalculator()
        check(calculator.summarize(course).recordedAverage == nil, "unknown grades do not show zero")
        check(calculator.summarize(course).maximumPossible == nil, "unknown scores do not claim feasibility")
        course.assessments[0].score = 60
        var summary = calculator.summarize(course)
        check(close(summary.recordedAverage, 60), "recorded average")
        check(close(summary.maximumPossible, 88), "weighted maximum: 18 + 70 = 88")
        check(summary.atRisk, "93% target is impossible at 88% maximum")
        check(close(summary.projectedFinal(remainingScore: 80), 74), "what-if: 18 + 56 = 74")
        course.target = .b
        summary = calculator.summarize(course)
        check(!summary.atRisk, "83% target remains possible")
        check(close(summary.requiredRemaining, 92.857142857), "remaining requirement uses ungraded weight")
        course.assessments[0].score = 0
        check(close(calculator.summarize(course).recordedAverage, 0), "zero is an entered score")
        course.assessments[0].score = nil
        check(calculator.summarize(course).recordedAverage == nil, "removed score becomes unknown")
        course.assessments[0].weight = 20
        check(!calculator.summarize(course).valid, "reject incomplete weights")
        check(calculator.summarize(course).maximumPossible == nil, "no estimates with invalid weights")
        course.assessments[0].weight = -10
        check(!calculator.summarize(course).valid, "reject negative weight")
        course = app.courses[0]
        course.assessments[0].score = .nan
        check(!calculator.summarize(course).valid, "reject nonfinite score")
        course.assessments[0].score = 101
        check(!calculator.summarize(course).valid, "reject score over 100")
        course.assessments = course.assessments.map { var a = $0; a.score = 95; return a }
        summary = calculator.summarize(course)
        check(close(summary.recordedAverage, 95) && close(summary.maximumPossible, 95), "fully graded result")
        check(summary.requiredRemaining == nil && !summary.atRisk, "completed goal needs no remaining calculation")

        app.profile.name = "Alex"
        app.profile.goal = "Get an A in Calculus II"
        app.profile.interests = "AI, football"
        app.completeOnboarding()
        check(!app.needsOnboarding, "onboarding completes")
        let courseID = app.courses[0].id
        let assessmentID = app.courses[0].assessments[0].id
        check(!app.setScore(-1, assessmentID: assessmentID, courseID: courseID), "UI-independent invalid score protection")
        check(!app.setScore(.infinity, assessmentID: assessmentID, courseID: courseID), "reject infinity at state boundary")
        app.setTarget(.a, courseID: courseID)
        app.setScore(60, assessmentID: assessmentID, courseID: courseID)
        check(!app.messages.contains { $0.proactive }, "no unsolicited reminder without opt-in")
        app.profile.reminders = true
        app.profile.quietHoursEnabled = true
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let night = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!
        app.evaluateRisks(now: night)
        check(!app.messages.contains { $0.proactive }, "quiet hours suppress reminders")
        app.evaluateRisks(now: noon)
        let riskMessages = app.messages.filter { $0.proactive && !$0.cards.isEmpty }
        check(riskMessages.count == 1, "one grade-risk message")
        check(riskMessages.first?.cards.count == 1, "proactive reminder includes a grade card")
        let count = app.messages.count
        app.evaluateRisks(now: noon)
        check(app.messages.count == count, "no duplicate reminders")
        app.profile.quietStart = 9; app.profile.quietEnd = 17
        check(app.profile.isQuiet(at: noon) && !app.profile.isQuiet(at: night), "daytime quiet window")
        app.profile.quietStart = 9; app.profile.quietEnd = 9
        check(app.profile.isQuiet(at: noon), "equal hours means quiet all day")
        check(app.events.count == 5 && Set(app.events.map { $0.category }).count == 5, "five demo event categories")
        app.askAbout(app.events[0])
        check(app.selectedTab == .chat, "event action opens Buddy")
        check(app.messages.last?.role == .user && app.isChatBusy, "event action sends user prompt")
        app.signOut()
        try await Task.sleep(nanoseconds: 60_000_000)
        check(app.messages.isEmpty && !app.isSignedIn, "late chat replies cannot leak after sign-out")
        app.beginDemo()
        check(app.profile.name == "Alex" && app.courses[0].assessments[0].score == 60, "demo state restores")
        let data = try JSONEncoder().encode(try store.load()!)
        let decoded = try JSONDecoder().decode(StudentState.self, from: data)
        check(decoded.messages == app.messages, "typed cards roundtrip through persistence")
        app.clearDemoData()
        check(store.value == nil && app.profile.memories.isEmpty && app.courses.isEmpty, "delete all clears demo storage")
        await app.authenticate(name: "Alex", email: "alex@example.com", password: "not-a-real-password", creating: true)
        check(app.authError != nil, "unconfigured sign-up reports failure, never fake success")
        print("PASS: \(checks) CampusMate model checks")
    }
}
