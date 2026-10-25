import Foundation

enum AuthProvider: String, CaseIterable, Identifiable, Codable {
    case email
    case demo
    case gmail
    case pennState
    case apple

    var id: String { rawValue }

    var title: String {
        switch self {
        case .email: return "Email"
        case .demo: return "Demo session"
        case .gmail: return "Continue with Gmail"
        case .pennState: return "Continue with Penn State"
        case .apple: return "Continue with Apple"
        }
    }

    var systemImage: String {
        switch self {
        case .email, .demo: return "person.crop.circle"
        case .gmail: return "envelope.fill"
        case .pennState: return "building.columns.fill"
        case .apple: return "apple.logo"
        }
    }
}

struct UserSession: Equatable, Codable {
    let id: String
    let displayName: String
    let email: String
    let provider: AuthProvider
}

struct CourseItem: Identifiable, Equatable, Hashable, Codable {
    var id: String
    var code: String
    var title: String
    var instructor: String
    var term: String
    var meetingTimes: String
    var location: String
    var exams: [CourseTask]
    var quizzes: [CourseTask]
    var assignments: [CourseTask]
    var createdAt: Date
    var target: TargetGrade = .a
    var assessments: [Assessment] = []
    var policies: String = "No verified syllabus policies yet. Confirm weights, grading scale, rounding, and late-work rules with your instructor."
    var isDemo: Bool = false
}

struct CourseTask: Identifiable, Equatable, Hashable, Codable {
    var id: String
    var title: String
    var dueDate: Date?
    var notes: String
}

struct ChatMessage: Identifiable, Equatable, Codable {
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    let id: String
    let role: Role
    let text: String
    let timestamp: Date
    var attachedFileName: String?
    var cards: [BuddyCard] = []
    var proactive: Bool = false
}

struct ExtractedSyllabus: Equatable, Codable {
    var code: String
    var title: String
    var instructor: String
    var term: String
    var meetingTimes: String
    var location: String
    var exams: [CourseTask]
    var quizzes: [CourseTask]
    var assignments: [CourseTask]
}

extension CourseItem {
    static func fromExtraction(_ extracted: ExtractedSyllabus) -> CourseItem {
        CourseItem(
            id: UUID().uuidString,
            code: extracted.code,
            title: extracted.title,
            instructor: extracted.instructor,
            term: extracted.term,
            meetingTimes: extracted.meetingTimes,
            location: extracted.location,
            exams: extracted.exams,
            quizzes: extracted.quizzes,
            assignments: extracted.assignments,
            createdAt: Date()
        )
    }
}

// Percent thresholds are editable prototype assumptions, not university-wide policy.
enum TargetGrade: String, CaseIterable, Codable, Identifiable {
    case a = "A", aMinus = "A−", bPlus = "B+", b = "B", c = "C"
    var id: String { rawValue }
    var threshold: Double {
        switch self { case .a: return 93; case .aMinus: return 90; case .bPlus: return 87; case .b: return 83; case .c: return 73 }
    }
}

/// Each assessment is an individual piece of the final grade, not a category average.
struct Assessment: Identifiable, Hashable, Codable {
    var id = UUID().uuidString
    var title: String
    var weight: Double
    var score: Double?
}

struct GradeSummary: Equatable, Codable {
    let target: Double
    let completedWeight: Double
    let earned: Double
    let valid: Bool
    var remainingWeight: Double { max(0, 100 - completedWeight) }
    var recordedAverage: Double? { completedWeight > 0 && valid ? earned / completedWeight * 100 : nil }
    var maximumPossible: Double? { valid && completedWeight > 0 ? earned + remainingWeight : nil }
    var requiredRemaining: Double? {
        guard valid, completedWeight > 0, remainingWeight > 0 else { return nil }
        return max(0, (target - earned) / remainingWeight * 100)
    }
    var atRisk: Bool { maximumPossible.map { $0 + 0.000001 < target } ?? false }
    var status: String {
        if !valid { return "Check assessment weights" }
        if completedWeight == 0 { return "No grades entered" }
        if atRisk { return "Goal at risk" }
        if remainingWeight < 0.000001 { return earned >= target ? "Goal reached" : "Goal at risk" }
        return "Goal still possible"
    }
    func projectedFinal(remainingScore: Double) -> Double? {
        guard valid, completedWeight > 0, remainingScore.isFinite, (0...100).contains(remainingScore) else { return nil }
        return earned + remainingWeight * remainingScore / 100
    }
}

protocol GradeCalculating {
    func summarize(_ course: CourseItem) -> GradeSummary
}
struct LocalGradeCalculator: GradeCalculating {
    func summarize(_ course: CourseItem) -> GradeSummary {
        let items = course.assessments
        let valid = !items.isEmpty && items.allSatisfy {
            $0.weight.isFinite && $0.weight > 0 && $0.weight <= 100 &&
            ($0.score.map { $0.isFinite && (0...100).contains($0) } ?? true)
        } && abs(items.reduce(0) { $0 + $1.weight } - 100) < 0.000001
        let graded = items.filter { $0.score != nil }
        return GradeSummary(target: course.target.threshold,
                            completedWeight: graded.reduce(0) { $0 + $1.weight },
                            earned: graded.reduce(0) { $0 + ($1.score ?? 0) * $1.weight / 100 }, valid: valid)
    }
}

/// Codable card payloads are a UI contract; an API adapter can map backend payloads to these cases.
enum BuddyCard: Equatable, Codable {
    case grade(courseID: String, code: String, result: GradeSummary)
    case event(CampusEvent)
    case goal(String)
}

struct CampusEvent: Identifiable, Equatable, Codable {
    var id: String
    var title: String
    var date: Date
    var location: String
    var category: String
    var description: String
    var interests: [String]
}

struct StudentMemory: Identifiable, Equatable, Codable {
    var id = UUID().uuidString
    var text: String
}
struct StudentProfile: Equatable, Codable {
    var name = ""
    var major = ""
    var year = ""
    var goal = ""
    var interests = ""
    var communication = "Friendly and occasional"
    var reminders = false
    var quietHoursEnabled = true
    var quietStart = 22
    var quietEnd = 8
    var memories: [StudentMemory] = []
    var onboardingComplete = false
    func isQuiet(at date: Date) -> Bool {
        guard quietHoursEnabled else { return false }
        let hour = Calendar.current.component(.hour, from: date)
        if quietStart == quietEnd { return true }
        return quietStart < quietEnd ? (quietStart..<quietEnd).contains(hour) : hour >= quietStart || hour < quietEnd
    }
}

struct BuddyContext {
    var profile: StudentProfile
    var courses: [CourseItem]
    var events: [CampusEvent]
}
struct BuddyReply {
    var text: String
    var cards: [BuddyCard] = []
}
protocol BuddyServiceProtocol {
    func reply(to text: String, context: BuddyContext) async throws -> BuddyReply
}

protocol StudentStateStoring {
    func load() throws -> StudentState?
    func save(_ state: StudentState) throws
    func clear()
}
struct StudentState: Codable {
    var profile: StudentProfile
    var courses: [CourseItem]
    var messages: [ChatMessage]
    var notifiedCourseIDs: Set<String>
}
struct LocalStudentStore: StudentStateStoring {
    // Demo storage is intentionally separate from future authenticated accounts.
    private let key = "campusmate.demo.v1"
    func load() throws -> StudentState? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(StudentState.self, from: data)
    }
    func save(_ state: StudentState) throws {
        UserDefaults.standard.set(try JSONEncoder().encode(state), forKey: key)
    }
    func clear() { UserDefaults.standard.removeObject(forKey: key) }
}
