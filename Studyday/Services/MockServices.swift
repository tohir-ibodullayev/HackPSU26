import Foundation

/// Local stub auth — no network. Friend can swap for real OAuth later.
final class MockAuthService: AuthServiceProtocol {
    func signIn(provider: AuthProvider) async throws -> UserSession {
        try await Task.sleep(nanoseconds: 700_000_000)
        let name: String
        let email: String
        switch provider {
        case .gmail:
            name = "Tohirjon"
            email = "tohirjon@gmail.com"
        case .pennState:
            name = "Tohirjon Ibodullayev"
            email = "tzi5073@psu.edu"
        case .apple:
            name = "Tohirjon"
            email = "tohirjon@icloud.com"
        }
        return UserSession(
            id: UUID().uuidString,
            displayName: name,
            email: email,
            provider: provider
        )
    }

    func signOut() async {
        try? await Task.sleep(nanoseconds: 150_000_000)
    }
}

/// Mock “Apple Intelligence” syllabus extraction — deterministic sample fields.
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

final class MockChatService: ChatServiceProtocol {
    func reply(to userMessage: String, syllabus: ExtractedSyllabus?) async throws -> String {
        try await Task.sleep(nanoseconds: 650_000_000)

        if let syllabus {
            let examCount = syllabus.exams.count
            let quizCount = syllabus.quizzes.count
            let assignmentCount = syllabus.assignments.count
            return """
            Got it — I pulled key details from your syllabus for **\(syllabus.code): \(syllabus.title)**.

            • Instructor: \(syllabus.instructor)
            • Term: \(syllabus.term)
            • Meets: \(syllabus.meetingTimes) · \(syllabus.location)
            • Found \(examCount) exam(s), \(quizCount) quiz(zes), and \(assignmentCount) assignment(s)

            I added this course to Home. You can open it to review exams, quizzes, and assignments, or tap Edit if anything looks off.
            """
        }

        let trimmed = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "I'm here when you're ready. Attach a syllabus with **+ Add syllabus**, or ask me anything about your courses."
        }

        if trimmed.lowercased().contains("hello") || trimmed.lowercased().contains("hi") {
            return "Hey! Drop a syllabus with **+ Add syllabus** and I’ll extract the schedule, then add the course to Home."
        }

        return """
        (Mock LLM) Thanks — once your friend’s API is wired up, answers will use your real course context.

        For now, try attaching a syllabus PDF/DOC so I can extract exams, quizzes, and assignments.
        """
    }
}
