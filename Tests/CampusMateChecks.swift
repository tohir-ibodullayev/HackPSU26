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
        checks += try await cloudChecks()
        print("PASS: \(checks) Avelo model/integration checks")
    }
}

private final class BuddyHTTPFixture: URLProtocol {
    static var status = 200
    static var data = Data()
    static var requests = 0
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requests += 1
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type":"application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.data); client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

extension CampusMateChecks {
    @MainActor static func cloudChecks() async throws -> Int {
        var checks = 0
        func check(_ condition: @autoclosure () -> Bool, _ name: String) {
            guard condition() else { fatalError("FAIL: \(name)") }; checks += 1
        }
        func blocked(_ operation: () throws -> Void, _ name: String) {
            do { try operation(); fatalError("FAIL: \(name)") } catch { checks += 1 }
        }
        let model = AppModel(buddy: MockBuddyService(), store: MemoryStore()); model.beginDemo()
        let id = model.courses[0].id
        _ = model.setScore(60, assessmentID: model.courses[0].assessments[0].id, courseID: id)
        model.profile.name = "PRIVATE-NAME"; model.profile.major = "PRIVATE-MAJOR"
        model.profile.goal = "PRIVATE-FREEFORM-GOAL"; model.profile.memories = [.init(text: "PRIVATE-MEMORY")]
        model.profile.interests = "AI, football, PRIVATE-INTEREST"
        var context = BuddyContext(profile: model.profile, courses: model.courses, events: model.events,
            syntheticDemo: true, cloudEnabled: true, summaries: Dictionary(uniqueKeysWithValues: model.courses.map { ($0.id, model.summary($0)) }))
        let budget = try DemoCloudPolicy.prepare("I have 2 hours for studying", context: context)
        check(budget.message.contains("2 hours"), "ordinary study durations are permitted, not treated as grades")
        let request = try DemoCloudPolicy.prepare("What's my goal in Calculus II?", context: context)
        let data = try JSONEncoder().encode(request)
        let text = String(decoding: data, as: UTF8.self)
        check(!text.contains("PRIVATE"), "private profile, free-form memories and arbitrary interests never encoded")
        check(!text.contains("policies") && !text.contains("instructor") && !text.contains("location"), "no syllabus/course object serialized")
        check(request.context.interests == ["AI", "football"], "only allowlisted independent interest tags")
        check(request.context.courses[0].summary.maximum_possible == 88, "wire value comes from existing Swift calculator")
        check(request.context.courses[0].summary.recorded_average == 60, "recorded-work average stays distinct")
        check(text.contains("\"final\":null"), "missing score stays explicitly unknown in JSON")
        var real = context; real.syntheticDemo = false
        blocked({ _ = try DemoCloudPolicy.prepare("Help me study", context: real) }, "real account context denied")
        real = context; real.courses[0].isDemo = false
        blocked({ _ = try DemoCloudPolicy.prepare("Help me study", context: real) }, "real course denied even in demo session")
        real = context; real.courses[0].policies = "PRIVATE-SYLLABUS-QUOTE"
        blocked({ _ = try DemoCloudPolicy.prepare("Help me study", context: real) }, "edited policy revokes cloud fixture eligibility")
        real = context; real.courses[0].assessments[0].weight = 25
        blocked({ _ = try DemoCloudPolicy.prepare("Help me study", context: real) }, "edited weights not silently reclassified synthetic")
        blocked({ _ = try DemoCloudPolicy.prepare("My actual score is 60%", context: context) }, "raw grade text stays local")
        blocked({ _ = try DemoCloudPolicy.prepare("Read my syllabus", context: context) }, "document question stays local")
        let config = URLSessionConfiguration.ephemeral; config.protocolClasses = [BuddyHTTPFixture.self]
        let service = GroqBuddyService(session: URLSession(configuration: config))
        BuddyHTTPFixture.status = 200
        BuddyHTTPFixture.data = Data(#"{"ok":true,"data":{"reply":"Your fictional maximum is 88%.","mode":"groq","cards":[{"kind":"grade","course_id":"calculus"}]},"error":null}"#.utf8)
        let reply = try await service.reply(to: "Can I still get an A?", context: context)
        check(reply.source.contains("Groq"), "actual provider response explicitly identified")
        check(reply.cards.count == 1, "typed response maps to existing BuddyCard")
        if case .grade(let courseID, _, let result) = reply.cards[0] {
            check(courseID == id && result.maximumPossible == 88, "grade card retains local result and course identity")
        } else { fatalError("FAIL: expected grade card") }
        let configured = ConfiguredBuddyService(cloud: service)
        BuddyHTTPFixture.status = 429
        BuddyHTTPFixture.data = Data(#"{"ok":false,"data":null,"error":{"code":"rate_limited","message":"Groq quota reached; retry shortly."}}"#.utf8)
        let fallback = try await configured.reply(to: "Help me study", context: context)
        check(fallback.source.contains("not a Groq response"), "quota fallback is never simulated AI")
        check(fallback.warning?.contains("quota") == true, "useful API failure retained for existing error UI")
        let sent = BuddyHTTPFixture.requests
        context.cloudEnabled = false
        let demo = try await configured.reply(to: "Help me study", context: context)
        check(demo.source.contains("local"), "explicit local mode labeled")
        check(BuddyHTTPFixture.requests == sent, "cloud disabled makes no external request")
        context.cloudEnabled = true
        let memory = try await configured.reply(to: "What do you remember?", context: context)
        check(memory.text.contains("PRIVATE-MEMORY") && memory.source.contains("not shared"), "memory screen works locally")
        check(BuddyHTTPFixture.requests == sent, "private memory query never invokes Groq")
        context.recentProactive = ChatMessage(id: "risk", role: .assistant, text: "PRIVATE-PROACTIVE-TEXT", timestamp: Date(), cards: [.grade(courseID: id, code: "MATH 141", result: model.summary(model.courses[0]))], proactive: true)
        let followup = try DemoCloudPolicy.prepare("Can we look at the numbers?", context: context)
        check(followup.context.proactive?.kind == "grade_risk", "proactive context uses an allowlisted code")
        let followupText = String(decoding: try JSONEncoder().encode(followup), as: UTF8.self)
        check(!followupText.contains("PRIVATE-PROACTIVE"), "proactive message text never enters payload")
        let legacy = StudentState(profile: model.profile, courses: model.courses, messages: model.messages, notifiedCourseIDs: [])
        let decoded = try JSONDecoder().decode(StudentState.self, from: JSONEncoder().encode(legacy))
        check(decoded.cloudEnabled == nil && decoded.courses.count == 2, "old demo persistence still decodes")
        let modeStore = MemoryStore(); let initial = AppModel(store: modeStore); initial.beginDemo()
        initial.useGroq = false; initial.saveBuddyMode()
        let restored = AppModel(store: modeStore); restored.beginDemo()
        check(!restored.useGroq, "explicit demo-only choice persists")
        return checks
    }
}
