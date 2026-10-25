import Foundation
import SwiftUI
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published var session: UserSession?
    @Published var profile = StudentProfile()
    @Published var courses: [CourseItem] = []
    @Published var messages: [ChatMessage] = []
    @Published var isAuthenticating = false
    @Published var isChatBusy = false
    @Published var authError: String?
    @Published var chatError: String?
    @Published var storageError: String?
    @Published var selectedTab: AppTab = .chat
    @Published var pendingSyllabusName: String?
    @Published var events: [CampusEvent] = []
    private let auth: AuthServiceProtocol
    private let extractor: SyllabusExtractorProtocol
    private let buddy: BuddyServiceProtocol
    private let calculator: GradeCalculating
    private let store: StudentStateStoring
    private var notifiedCourseIDs: Set<String> = []
    private var generation = UUID()

    init(auth: AuthServiceProtocol = UnconfiguredAuthService(),
         extractor: SyllabusExtractorProtocol = MockSyllabusExtractor(),
         buddy: BuddyServiceProtocol = MockBuddyService(),
         calculator: GradeCalculating = LocalGradeCalculator(),
         store: StudentStateStoring = LocalStudentStore()) {
        self.auth = auth; self.extractor = extractor; self.buddy = buddy
        self.calculator = calculator; self.store = store
    }
    var isSignedIn: Bool { session != nil }
    var needsOnboarding: Bool { isSignedIn && !profile.onboardingComplete }
    var isDemo: Bool { session?.provider == .demo }

    func beginDemo() {
        generation = UUID()
        profile = StudentProfile(); courses = []; messages = []; notifiedCourseIDs = []
        do {
            if let saved = try store.load() {
                profile = saved.profile; courses = saved.courses; messages = saved.messages
                notifiedCourseIDs = saved.notifiedCourseIDs
            } else { seedDemo() }
        } catch {
            storageError = "Saved demo data couldn’t be read. This session starts fresh; your saved data has not been overwritten."
            seedDemo()
        }
        session = UserSession(id: "local-demo", displayName: "Student", email: "", provider: .demo)
        selectedTab = .chat
        seedEvents()
        evaluateRisks()
    }

    func authenticate(name: String, email: String, password: String, creating: Bool) async {
        guard !isAuthenticating else { return }
        isAuthenticating = true; authError = nil
        let token = generation
        defer { isAuthenticating = false }
        do {
            let result: UserSession
            if creating { result = try await auth.signUp(name: name, email: email, password: password) }
            else { result = try await auth.signIn(email: email, password: password) }
            guard token == generation else { return }
            // Real accounts never inherit demo data. Backend persistence belongs in the injected service.
            profile = StudentProfile(); profile.name = result.displayName
            courses = []; messages = []; events = []; notifiedCourseIDs = []
            generation = UUID(); session = result; selectedTab = .chat
            welcome()
        } catch { if token == generation { authError = error.localizedDescription } }
    }
    func resetPassword(email: String) async -> String {
        do { try await auth.resetPassword(email: email); return "If an account exists, check your email for recovery instructions." }
        catch { return error.localizedDescription }
    }
    func signOut() {
        persist()
        generation = UUID(); session = nil; profile = StudentProfile()
        courses = []; messages = []; events = []; isChatBusy = false; pendingSyllabusName = nil; chatError = nil; authError = nil
        Task { await auth.signOut() }
    }
    func completeOnboarding() {
        profile.name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.onboardingComplete = true
        persist()
        append(role: .assistant, text: "Hey\(profile.name.isEmpty ? "" : ", " + profile.name)! I’m your CampusMate. Let’s make this semester feel a little lighter. What’s on your mind?", cards: profile.goal.isEmpty ? [] : [.goal(profile.goal)])
        evaluateRisks()
    }
    func saveProfile() { persist(); evaluateRisks() }
    func summary(_ course: CourseItem) -> GradeSummary { calculator.summarize(course) }
    func updateCourse(_ course: CourseItem) {
        guard let idx = courses.firstIndex(where: { $0.id == course.id }) else { return }
        courses[idx] = course; persist(); evaluateRisks()
    }
    func deleteCourse(_ course: CourseItem) {
        courses.removeAll { $0.id == course.id }; persist()
    }
    func setTarget(_ target: TargetGrade, courseID: String) {
        guard let idx = courses.firstIndex(where: { $0.id == courseID }) else { return }
        courses[idx].target = target; persist(); evaluateRisks()
    }
    @discardableResult
    func setScore(_ score: Double?, assessmentID: String, courseID: String) -> Bool {
        guard score.map({ $0.isFinite && (0...100).contains($0) }) ?? true,
              let idx = courses.firstIndex(where: { $0.id == courseID }),
              let item = courses[idx].assessments.firstIndex(where: { $0.id == assessmentID }) else { return false }
        courses[idx].assessments[item].score = score
        let course = courses[idx]
        append(role: .assistant, text: "Updated your entered grades for \(course.code). Here’s the calculation with the available assessment weights.", cards: [.grade(courseID: course.id, code: course.code, result: summary(course))])
        persist(); evaluateRisks(); return true
    }
    func evaluateRisks(now: Date = Date()) {
        for course in courses where !summary(course).atRisk { notifiedCourseIDs.remove(course.id) }
        guard isSignedIn, profile.onboardingComplete, profile.reminders, !profile.isQuiet(at: now) else { return }
        for course in courses where summary(course).atRisk && !notifiedCourseIDs.contains(course.id) {
            notifiedCourseIDs.insert(course.id)
            append(role: .assistant, text: "A little heads-up: your \(course.code) goal is at risk under the current weights. Want to explore a realistic target or plan your next study session?", cards: [.grade(courseID: course.id, code: course.code, result: summary(course))], proactive: true)
        }
        for course in courses {
            for exam in course.exams {
                guard let due = exam.dueDate else { continue }
                let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: due).day ?? -1
                let key = "exam-" + exam.id + "-" + String(due.timeIntervalSince1970)
                if (0...7).contains(days) && !notifiedCourseIDs.contains(key) {
                    notifiedCourseIDs.insert(key)
                    append(role: .assistant, text: "Hey! Your \(course.code) \(exam.title) is coming up on \(due.formatted(date: .abbreviated, time: .omitted))\(course.isDemo ? " (demo deadline)" : ""). Want to make a small study plan?", proactive: true)
                }
            }
        }
        persist()
    }
    func sendUserText(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isSignedIn, !text.isEmpty, !isChatBusy else { return }
        append(role: .user, text: text); isChatBusy = true; chatError = nil
        let token = generation
        let context = BuddyContext(profile: profile, courses: courses, events: events)
        Task {
            do {
                let reply = try await buddy.reply(to: text, context: context)
                guard token == generation else { return }
                append(role: .assistant, text: reply.text, cards: reply.cards)
            } catch {
                guard token == generation else { return }
                chatError = error.localizedDescription
                append(role: .assistant, text: "I couldn’t finish that reply. Please try again.")
            }
            if token == generation { isChatBusy = false }
        }
    }
    func askAbout(_ event: CampusEvent) {
        guard !isChatBusy else { return }
        selectedTab = .chat; sendUserText("Tell me about \(event.title).")
    }
    func attachSyllabus(fileName: String, data: Data? = nil) {
        guard !isChatBusy else { return }
        isChatBusy = true; pendingSyllabusName = fileName
        append(role: .user, text: "Import syllabus: \(fileName)")
        let token = generation
        Task {
            do {
                let extracted = try await extractor.extract(from: fileName, fileDataHint: data)
                guard token == generation else { return }
                var course = CourseItem.fromExtraction(extracted)
                course.isDemo = true
                if courses.contains(where: { $0.code == course.code }) {
                    append(role: .assistant, text: "You already have \(course.code). I kept its grades and details unchanged. You can edit the existing course in Academics.")
                } else {
                    courses.append(course)
                    append(role: .assistant, text: "Added demo course \(course.code). The prototype uses filename-based sample extraction; it hasn’t read or verified the file’s content. Review the details in Academics. No grades or assessment weights were inferred.")
                }
                persist()
            } catch {
                guard token == generation else { return }
                chatError = error.localizedDescription
            }
            if token == generation { isChatBusy = false; pendingSyllabusName = nil }
        }
    }
    func clearDemoData() {
        guard isDemo else { return }
        store.clear(); storageError = nil; generation = UUID(); isChatBusy = false
        profile = StudentProfile(); courses = []; messages = []; notifiedCourseIDs = []
        welcome()
    }
    private func append(role: ChatMessage.Role, text: String, cards: [BuddyCard] = [], proactive: Bool = false) {
        messages.append(ChatMessage(id: UUID().uuidString, role: role, text: text, timestamp: Date(), cards: cards, proactive: proactive)); persist()
    }
    private func persist() {
        guard isDemo, storageError == nil else { return }
        do { try store.save(StudentState(profile: profile, courses: courses, messages: messages, notifiedCourseIDs: notifiedCourseIDs)) }
        catch { storageError = "Your latest changes couldn’t be saved on this device." }
    }
    private func welcome() {
        messages = [ChatMessage(id: UUID().uuidString, role: .assistant, text: "Hey! I’m your CampusMate. We can check your grades, plan a study session, or find something fun on campus.", timestamp: Date())]
    }
    private func seedDemo() {
        welcome()
        for (code, title) in [("MATH 141", "Calculus II"), ("CMPSC 221", "Object-Oriented Programming")] {
            let tasks = [CourseTask(id: UUID().uuidString, title: "Midterm", dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()), notes: "Fictional demo deadline")]
            courses.append(CourseItem(id: UUID().uuidString, code: code, title: title, instructor: "Demo instructor", term: "Demo semester", meetingTimes: "Check your syllabus", location: "Not provided", exams: tasks, quizzes: [], assignments: [], createdAt: Date(), assessments: [Assessment(title: "Midterm", weight: 30), Assessment(title: "Final exam", weight: 40), Assessment(title: "Coursework total", weight: 30)], policies: "Demo weights: Midterm 30%, Final 40%, Coursework 30%. No drop, curve, rounding, or extra credit assumed. Verify with your instructor before using for a real course.", isDemo: true))
        }
    }
    private func seedEvents() {
        let samples = [
            ("ai", "Build with AI", "Hackathons", "Innovation Hub", "Bring an idea, meet a team, and build a tiny prototype. Beginners welcome.", ["AI", "hackathons"]),
            ("football", "Saturday fan meetup", "Sports", "Campus lawn", "A relaxed student fan gathering with lawn games before the game.", ["football", "sports"]),
            ("clubs", "Find your people", "Clubs", "Student center", "Meet fictional campus clubs and try a new hobby with a friend.", ["clubs", "art"]),
            ("career", "Coffee & careers", "Career", "Library commons", "Practice introductions and swap internship tips over coffee.", ["career", "technology"]),
            ("social", "Sunset study break", "Social", "Campus gardens", "Unplug for a short walk and a low-key picnic with other students.", ["music", "social"])
        ]
        let evening = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
        events = samples.enumerated().map { i, e in
            CampusEvent(id: e.0, title: e.1, date: Calendar.current.date(byAdding: .day, value: i + 1, to: evening) ?? evening, location: e.3, category: e.2, description: e.4, interests: e.5)
        }
    }
}
enum AppTab: Hashable { case chat, home, discover, profile }
