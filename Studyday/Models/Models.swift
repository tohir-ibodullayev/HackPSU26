import Foundation

enum AuthProvider: String, CaseIterable, Identifiable {
    case gmail
    case pennState
    case apple

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gmail: return "Continue with Gmail"
        case .pennState: return "Continue with Penn State"
        case .apple: return "Continue with Apple"
        }
    }

    var systemImage: String {
        switch self {
        case .gmail: return "envelope.fill"
        case .pennState: return "building.columns.fill"
        case .apple: return "apple.logo"
        }
    }
}

struct UserSession: Equatable {
    let id: String
    let displayName: String
    let email: String
    let provider: AuthProvider
}

struct CourseItem: Identifiable, Equatable, Hashable {
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
}

struct CourseTask: Identifiable, Equatable, Hashable {
    var id: String
    var title: String
    var dueDate: Date?
    var notes: String
}

struct ChatMessage: Identifiable, Equatable {
    enum Role: String {
        case user
        case assistant
        case system
    }

    let id: String
    let role: Role
    let text: String
    let timestamp: Date
    var attachedFileName: String?
}

struct ExtractedSyllabus: Equatable {
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
