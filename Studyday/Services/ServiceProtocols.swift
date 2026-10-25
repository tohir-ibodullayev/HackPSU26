import Foundation

/// Plug real OAuth / campus SSO behind this protocol later.
protocol AuthServiceProtocol {
    func signIn(provider: AuthProvider) async throws -> UserSession
    func signOut() async
}

/// Stand-in for Apple Intelligence / on-device syllabus parsing.
protocol SyllabusExtractorProtocol {
    func extract(from fileName: String, fileDataHint: Data?) async throws -> ExtractedSyllabus
}

/// Stand-in for the friend's LLM / chat backend.
protocol ChatServiceProtocol {
    func reply(to userMessage: String, syllabus: ExtractedSyllabus?) async throws -> String
}

enum ServiceError: LocalizedError {
    case cancelled
    case unavailable(String)
    case extractionFailed

    var errorDescription: String? {
        switch self {
        case .cancelled: return "Cancelled."
        case .unavailable(let message): return message
        case .extractionFailed: return "Could not read that syllabus. You can edit the course manually."
        }
    }
}
