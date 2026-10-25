import Foundation

/// Implement with a real auth provider; never persist passwords in app state.
protocol AuthServiceProtocol {
    func signIn(email: String, password: String) async throws -> UserSession
    func signUp(name: String, email: String, password: String) async throws -> UserSession
    func resetPassword(email: String) async throws
    func signOut() async
}

/// Stand-in for Apple Intelligence / on-device syllabus parsing.
protocol SyllabusExtractorProtocol {
    func extract(from fileName: String, fileDataHint: Data?) async throws -> ExtractedSyllabus
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
