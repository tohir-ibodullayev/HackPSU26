import Foundation

/// Filename-based sample extraction. File content is never read or verified.
final class MockSyllabusExtractor: SyllabusExtractorProtocol {
    func extract(from fileName: String, fileDataHint: Data?) async throws -> ExtractedSyllabus {
        try await Task.sleep(nanoseconds: 1_100_000_000)

        let calendar = Calendar.current
        let now = Date()
        func days(_ n: Int) -> Date {
            calendar.date(byAdding: .day, value: n, to: now) ?? now
        }

        // Vary slightly by filename so repeated uploads feel distinct in demos.
        let lower = fileName.lowercased()
        if lower.contains("math") || lower.contains("calc") {
            return ExtractedSyllabus(
                code: "MATH 141",
                title: "Calculus with Analytic Geometry II",
                instructor: "Dr. Elena Park",
                term: "Fall 2026",
                meetingTimes: "MWF 10:10–11:00 AM",
                location: "Willard Building 162",
                exams: [
                    CourseTask(id: UUID().uuidString, title: "Midterm 1", dueDate: days(21), notes: "Ch. 6–8"),
                    CourseTask(id: UUID().uuidString, title: "Final Exam", dueDate: days(70), notes: "Cumulative")
                ],
                quizzes: [
                    CourseTask(id: UUID().uuidString, title: "Quiz 3 — Series", dueDate: days(10), notes: "")
                ],
                assignments: [
                    CourseTask(id: UUID().uuidString, title: "HW 5", dueDate: days(5), notes: "WebAssign"),
                    CourseTask(id: UUID().uuidString, title: "HW 6", dueDate: days(12), notes: "WebAssign")
                ]
            )
        }

        if lower.contains("cs") || lower.contains("cmpsc") || lower.contains("code") {
            return ExtractedSyllabus(
                code: "CMPSC 221",
                title: "Object Oriented Programming with Web-Based Applications",
                instructor: "Prof. Jordan Hale",
                term: "Fall 2026",
                meetingTimes: "TR 1:35–2:50 PM",
                location: "Westgate E201",
                exams: [
                    CourseTask(id: UUID().uuidString, title: "Practical Exam", dueDate: days(35), notes: "Lab machines")
                ],
                quizzes: [
                    CourseTask(id: UUID().uuidString, title: "Quiz — Inheritance", dueDate: days(8), notes: "")
                ],
                assignments: [
                    CourseTask(id: UUID().uuidString, title: "Project 2 — REST client", dueDate: days(18), notes: "GitHub submission"),
                    CourseTask(id: UUID().uuidString, title: "Lab 7", dueDate: days(6), notes: "")
                ]
            )
        }

        // Default demo syllabus
        return ExtractedSyllabus(
            code: "IST 220",
            title: "Networking and Telecommunications",
            instructor: "Dr. Sam Rivera",
            term: "Fall 2026",
            meetingTimes: "TR 9:05–10:20 AM",
            location: "IST Building 110",
            exams: [
                CourseTask(id: UUID().uuidString, title: "Exam 1", dueDate: days(24), notes: "Chapters 1–4"),
                CourseTask(id: UUID().uuidString, title: "Final Exam", dueDate: days(72), notes: "Cumulative")
            ],
            quizzes: [
                CourseTask(id: UUID().uuidString, title: "Quiz — OSI model", dueDate: days(7), notes: "In-class"),
                CourseTask(id: UUID().uuidString, title: "Quiz — Subnetting", dueDate: days(14), notes: "")
            ],
            assignments: [
                CourseTask(id: UUID().uuidString, title: "Lab: Packet capture", dueDate: days(9), notes: "Wireshark"),
                CourseTask(id: UUID().uuidString, title: "Reading response 2", dueDate: days(4), notes: "Canvas")
            ]
        )
    }
}

struct MockBuddyService: BuddyServiceProtocol {
    func reply(to text: String, context: BuddyContext) async throws -> BuddyReply {
        try await Task.sleep(nanoseconds: 300_000_000)
        let lower = text.lowercased()
        if lower.contains("remember") || lower.contains("memory") {
            let memories = context.profile.memories.map { "• " + $0.text }.joined(separator: "\n")
            return BuddyReply(text: memories.isEmpty ? "You haven’t saved any personal memories yet. Add, edit, or delete them in Me — you decide what stays." : "Here’s what you chose to save:\n" + memories + "\nYou can edit or delete any of these in Me.")
        }
        if lower.contains("grade") || lower.contains("doing") || lower.contains("calc") {
            let matching = context.courses.filter { lower.contains($0.code.lowercased()) }
            let courses = matching.isEmpty ? context.courses : matching
            return BuddyReply(text: "Let’s look at what you’ve entered. These are recorded results, not a synced Canvas average. Open a card to update your goal or try a scenario.", cards: courses.map {
                .grade(courseID: $0.id, code: $0.code, result: LocalGradeCalculator().summarize($0))
            })
        }
        if let event = context.events.first(where: { lower.contains($0.title.lowercased()) }) {
            return BuddyReply(text: "This fictional demo event could be a fun break. Check the time and location below. Want to make a study plan around it?", cards: [.event(event)])
        }
        if lower.contains("event") || lower.contains("campus") {
            return BuddyReply(text: "Here’s a fictional campus pick to explore. Discover has more demo events.", cards: context.events.prefix(1).map { .event($0) })
        }
        if lower.contains("goal") {
            return BuddyReply(text: "Small steps count. You can update what matters to you in Me.", cards: [.goal(context.profile.goal.isEmpty ? "Set your academic goal in Me." : context.profile.goal)])
        }
        if lower.contains("study") || lower.contains("exam") {
            let course = context.courses.first
            return BuddyReply(text: "Let’s start small\(context.profile.name.isEmpty ? "" : ", " + context.profile.name). Pick one topic\(course.map { " from " + $0.code } ?? ""), spend 20 minutes on practice questions, then take a five-minute break. Which topic feels hardest?")
        }
        return BuddyReply(text: "I’m here for your college journey. In this prototype I can show your entered grades, help outline a study session, and explore demo campus events. What would help right now?")
    }
}

/// No fake account creation: inject your teammate's provider to enable real email auth.
struct UnconfiguredAuthService: AuthServiceProtocol {
    func signIn(email: String, password: String) async throws -> UserSession {
        throw ServiceError.unavailable("Account sign-in isn’t connected yet. Use Try the demo to explore CampusMate.")
    }
    func signUp(name: String, email: String, password: String) async throws -> UserSession {
        throw ServiceError.unavailable("Account creation isn’t connected yet. No account was created. Try the demo for now.")
    }
    func resetPassword(email: String) async throws {
        throw ServiceError.unavailable("Password recovery isn’t connected yet. No reset email was sent.")
    }
    func signOut() async {}
}
