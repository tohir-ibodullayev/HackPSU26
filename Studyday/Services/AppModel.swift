import Foundation
import SwiftUI
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published var session: UserSession?
    @Published var courses: [CourseItem] = []
    @Published var messages: [ChatMessage] = []
    @Published var isAuthenticating = false
    @Published var isChatBusy = false
    @Published var authError: String?
    @Published var chatError: String?
    @Published var selectedTab: AppTab = .chat
    @Published var pendingSyllabusName: String?

    private let auth: AuthServiceProtocol
    private let extractor: SyllabusExtractorProtocol
    private let chat: ChatServiceProtocol

    /// Last extraction kept so chat can reference it; replace with API later.
    private(set) var lastExtraction: ExtractedSyllabus?

    init(
        auth: AuthServiceProtocol = MockAuthService(),
        extractor: SyllabusExtractorProtocol = MockSyllabusExtractor(),
        chat: ChatServiceProtocol = MockChatService()
    ) {
        self.auth = auth
        self.extractor = extractor
        self.chat = chat
        seedWelcome()
    }

    var isSignedIn: Bool { session != nil }

    func signIn(provider: AuthProvider) {
        Task {
            isAuthenticating = true
            authError = nil
            defer { isAuthenticating = false }
            do {
                session = try await auth.signIn(provider: provider)
                selectedTab = .chat
            } catch {
                authError = error.localizedDescription
            }
        }
    }

    func signOut() {
        Task {
            await auth.signOut()
            session = nil
            courses = []
            messages = []
            lastExtraction = nil
            pendingSyllabusName = nil
            seedWelcome()
        }
    }

    func attachSyllabus(fileName: String) {
        pendingSyllabusName = fileName
        appendMessage(
            role: .user,
            text: "Attached syllabus: \(fileName)",
            fileName: fileName
        )
        Task { await processAttachedSyllabus(fileName: fileName) }
    }

    func sendUserText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        appendMessage(role: .user, text: trimmed)
        Task { await requestLLMReply(userText: trimmed) }
    }

    func updateCourse(_ course: CourseItem) {
        if let idx = courses.firstIndex(where: { $0.id == course.id }) {
            courses[idx] = course
        }
    }

    func deleteCourse(_ course: CourseItem) {
        courses.removeAll { $0.id == course.id }
    }

    // MARK: - Private

    private func seedWelcome() {
        messages = [
            ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                text: "Your semester, a little lighter. Attach a syllabus with **+ Add syllabus** — I’ll pull exams, quizzes, and assignments into a clearer course on Home.",
                timestamp: Date()
            )
        ]
    }

    private func appendMessage(role: ChatMessage.Role, text: String, fileName: String? = nil) {
        messages.append(
            ChatMessage(
                id: UUID().uuidString,
                role: role,
                text: text,
                timestamp: Date(),
                attachedFileName: fileName
            )
        )
    }

    private func processAttachedSyllabus(fileName: String) async {
        isChatBusy = true
        chatError = nil
        defer {
            isChatBusy = false
            pendingSyllabusName = nil
        }

        appendMessage(
            role: .system,
            text: "Apple Intelligence (mock) is reading \(fileName)…"
        )

        do {
            let extracted = try await extractor.extract(from: fileName, fileDataHint: nil)
            lastExtraction = extracted
            let course = CourseItem.fromExtraction(extracted)
            courses.insert(course, at: 0)

            let reply = try await chat.reply(
                to: "I uploaded \(fileName). Please extract and add the course.",
                syllabus: extracted
            )
            appendMessage(role: .assistant, text: reply)
        } catch {
            chatError = error.localizedDescription
            appendMessage(
                role: .assistant,
                text: "I couldn’t finish extracting that syllabus. You can still add or edit a course manually from Home."
            )
        }
    }

    private func requestLLMReply(userText: String) async {
        isChatBusy = true
        chatError = nil
        defer { isChatBusy = false }
        do {
            let reply = try await chat.reply(to: userText, syllabus: lastExtraction)
            appendMessage(role: .assistant, text: reply)
        } catch {
            chatError = error.localizedDescription
            appendMessage(role: .assistant, text: "Something went wrong talking to the (mock) model. Try again.")
        }
    }
}

enum AppTab: Hashable {
    case chat
    case home
    case profile
}
