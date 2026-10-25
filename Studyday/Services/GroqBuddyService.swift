import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// The only wire representation: coded fictional controls, never CourseItem/profile/documents.
struct DemoCloudRequest: Encodable {
    struct Summary: Encodable {
        let target: Double, completed_weight: Double, earned: Double, remaining_weight: Double
        let valid: Bool
        let recorded_average: Double?, maximum_possible: Double?, required_remaining: Double?
        let at_risk: Bool
        enum CodingKeys: String, CodingKey { case target, completed_weight, earned, remaining_weight, valid, recorded_average, maximum_possible, required_remaining, at_risk }
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(target, forKey: .target); try c.encode(completed_weight, forKey: .completed_weight)
            try c.encode(earned, forKey: .earned); try c.encode(remaining_weight, forKey: .remaining_weight); try c.encode(valid, forKey: .valid)
            try c.encode(recorded_average, forKey: .recorded_average); try c.encode(maximum_possible, forKey: .maximum_possible)
            try c.encode(required_remaining, forKey: .required_remaining); try c.encode(at_risk, forKey: .at_risk)
        }
    }
    struct Course: Encodable {
        let id: String, target: String
        let midterm: Double?, final: Double?, coursework: Double?
        let summary: Summary
        enum CodingKeys: String, CodingKey { case id, target, midterm, final, coursework, summary }
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(id, forKey: .id); try c.encode(target, forKey: .target)
            try c.encode(midterm, forKey: .midterm); try c.encode(final, forKey: .final); try c.encode(coursework, forKey: .coursework)
            try c.encode(summary, forKey: .summary)
        }
    }
    struct Proactive: Encodable { let kind: String; let course_id: String }
    struct Context: Encodable {
        let scope = "synthetic_ui_v2"
        let fixture_day: String
        let courses: [Course]
        let interests: [String]
        let proactive: Proactive?
    }
    let conversation_id: UUID
    let request_id: UUID
    let message: String
    let context: Context
}

enum DemoCloudPolicy {
    static let interests = ["AI", "hackathons", "football", "sports", "clubs", "art", "career", "technology", "music", "social"]
    static func key(for course: CourseItem) -> String? {
        guard course.isDemo, course.instructor == "Demo instructor", course.term == "Demo semester",
              course.policies == "Demo weights: Midterm 30%, Final 40%, Coursework 30%. No drop, curve, rounding, or extra credit assumed. Verify with your instructor before using for a real course.",
              course.assessments.count == 3,
              course.assessments.map(\.title) == ["Midterm", "Final exam", "Coursework total"],
              course.assessments.map(\.weight) == [30, 40, 30] else { return nil }
        switch (course.code, course.title) {
        case ("MATH 141", "Calculus II"): return "calculus"
        case ("CMPSC 221", "Object-Oriented Programming"): return "programming"
        default: return nil
        }
    }
    static func prepare(_ text: String, context: BuddyContext) throws -> DemoCloudRequest {
        guard context.syntheticDemo else { throw ServiceError.unavailable("Cloud chat is limited to the explicitly fictional demo. Your real records stay local.") }
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= 1500 else { throw ServiceError.unavailable("Use a question of up to 1,500 characters.") }
        // Never serialize a document excerpt, arbitrary grade statement, contact, or credential.
        let lower = text.lowercased()
        let forbidden = #"https?://|\S+@\S+|\b(syllabus|source quote|raw text|penn state|psu|canvas|private record|diagnos\w*|medical record|social security|student id|no calculators|make[ -]?up|extra credit|dropped|collected|password|api key|gsk_)\b"#
        let withoutCodes = text.replacingOccurrences(of: #"\b(?:MATH\s*141|CMPSC\s*221)\b"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b\d{1,3}[ -]*(?:hours?|minutes?|mins?|hrs?)\b"#, with: "", options: [.regularExpression, .caseInsensitive])
        guard !text.contains("\n"), !["\"", "`", "{", "}", "\t", "“", "”"].contains(where: text.contains),
              lower.range(of: forbidden, options: .regularExpression) == nil,
              withoutCodes.range(of: #"\d|%"#, options: .regularExpression) == nil else {
            throw ServiceError.unavailable("That input stays local. Enter fictional scores through Academics; never paste real records into cloud chat.")
        }
        let courses = try context.courses.map { course -> DemoCloudRequest.Course in
            guard let id = key(for: course), let summary = context.summaries[course.id], summary.valid else {
                throw ServiceError.unavailable("Edited, imported or unverified course records are blocked from Groq. The original coded demo fixtures are required.")
            }
            return .init(id: id, target: course.target.rawValue, midterm: course.assessments[0].score,
                final: course.assessments[1].score, coursework: course.assessments[2].score,
                summary: .init(target: summary.target, completed_weight: summary.completedWeight, earned: summary.earned, remaining_weight: summary.remainingWeight,
                    valid: summary.valid, recorded_average: summary.recordedAverage, maximum_possible: summary.maximumPossible,
                    required_remaining: summary.requiredRemaining, at_risk: summary.atRisk))
        }
        guard !courses.isEmpty, courses.count <= 2, Set(courses.map(\.id)).count == courses.count else {
            throw ServiceError.unavailable("Only the two original fictional demo courses can be used in cloud mode.")
        }
        let tags = context.profile.interests.split(whereSeparator: { $0 == "," || $0 == ";" || $0 == "\n" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let selected = interests.filter { allowed in tags.contains { $0.caseInsensitiveCompare(allowed) == .orderedSame } }
        let first = context.events.first(where: { $0.id == "ai" && $0.title == "Build with AI" })
        let anchor = first.flatMap { Calendar.current.date(byAdding: .day, value: -1, to: $0.date) } ?? Date()
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        var proactive: DemoCloudRequest.Proactive?
        if let message = context.recentProactive,
           let grade = message.cards.compactMap({ card -> String? in if case .grade(let id, _, _) = card { return id }; return nil }).first,
           let course = context.courses.first(where: { $0.id == grade }), let key = key(for: course) {
            proactive = .init(kind: "grade_risk", course_id: key)
        }
        return .init(conversation_id: context.conversationID, request_id: UUID(), message: text,
            context: .init(fixture_day: formatter.string(from: anchor), courses: courses, interests: selected, proactive: proactive))
    }
}

private struct CloudResponse: Decodable {
    struct Card: Decodable { let kind: String; let course_id: String?; let event_id: String? }
    let reply: String
    let mode: String
    let cards: [Card]
}
private struct CloudEnvelope: Decodable {
    struct Failure: Decodable { let code: String; let message: String }
    let ok: Bool
    let data: CloudResponse?
    let error: Failure?
}

final class GroqBuddyService: BuddyServiceProtocol {
    private let baseURL: URL
    private let session: URLSession
    init(baseURL: URL? = nil, session: URLSession? = nil) {
        self.baseURL = baseURL ?? URL(string: ProcessInfo.processInfo.environment["AVELO_BACKEND_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "AveloBackendURL") as? String ?? "http://127.0.0.1:8001")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil; configuration.httpCookieStorage = nil
        self.session = session ?? URLSession(configuration: configuration)
    }
    func reply(to text: String, context: BuddyContext) async throws -> BuddyReply {
        guard baseURL.scheme == "http", ["127.0.0.1", "localhost", "::1"].contains(baseURL.host ?? "") else {
            throw ServiceError.unavailable("This demo permits only the local backend. Use the iPhone Simulator on the same Mac.")
        }
        let payload = try DemoCloudPolicy.prepare(text, context: context)
        var request = URLRequest(url: baseURL.appendingPathComponent("v2/chat"))
        request.httpMethod = "POST"; request.timeoutInterval = 65
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.httpBody = try JSONEncoder().encode(payload)
        let data: Data; let response: URLResponse
        do { (data, response) = try await session.data(for: request, delegate: RejectBuddyRedirects()) }
        catch let error as URLError where error.code == .cancelled { throw CancellationError() }
        catch let error as URLError where error.code == .timedOut {
            throw ServiceError.unavailable("Groq timed out. Retry or switch to Demo replies.")
        } catch {
            throw ServiceError.unavailable("Cannot reach the local Avelo backend at \(baseURL.absoluteString). Start it on this Mac; use iPhone Simulator, not a physical phone.")
        }
        guard let http = response as? HTTPURLResponse,
              let envelope = try? JSONDecoder().decode(CloudEnvelope.self, from: data) else {
            throw ServiceError.unavailable("The backend returned an invalid response. Check the server and retry.")
        }
        if let error = envelope.error { throw ServiceError.unavailable(error.message) }
        guard http.statusCode == 200, envelope.ok, let answer = envelope.data, ["groq", "guard"].contains(answer.mode) else {
            throw ServiceError.unavailable("No verified Groq response was returned. Try Demo replies.")
        }
        var cards: [BuddyCard] = []
        for card in answer.cards {
            if let key = card.course_id, let course = context.courses.first(where: { DemoCloudPolicy.key(for: $0) == key }) {
                if card.kind == "grade", let result = context.summaries[course.id] {
                    cards.append(.grade(courseID: course.id, code: course.code, result: result))
                } else if card.kind == "goal" {
                    cards.append(.goal("\(course.code): \(course.target.rawValue) (\(course.target.threshold.formatted())%) · fictional target"))
                }
            } else if card.kind == "event", let id = card.event_id, let event = context.events.first(where: { $0.id == id }) {
                cards.append(.event(event))
            }
        }
        return .init(text: answer.reply, cards: cards, source: answer.mode == "groq" ? "Groq · fictional demo" : "Avelo · domain guard")
    }
}

private final class RejectBuddyRedirects: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) { completionHandler(nil) }
}

/// Failures remain explicitly labeled; a template is never presented as real AI inference.
struct ConfiguredBuddyService: BuddyServiceProtocol {
    let cloud: BuddyServiceProtocol
    let demo: BuddyServiceProtocol
    init(cloud: BuddyServiceProtocol = GroqBuddyService(), demo: BuddyServiceProtocol = MockBuddyService()) { self.cloud = cloud; self.demo = demo }
    func reply(to text: String, context: BuddyContext) async throws -> BuddyReply {
        let escape = #"\b(world cup|celebrity gossip|unrelated movie|stock price)\b|ignore.{0,40}(instructions|rules)|(?:reveal|show|print).{0,30}(secret|api.?key)|become chatgpt"#
        if text.range(of: escape, options: [.regularExpression, .caseInsensitive]) != nil {
            return .init(text: "I’m here mainly for your college journey 😄 Want to talk about classes, goals, or campus life?", source: "Avelo · domain guard")
        }
        guard context.cloudEnabled else {
            var result = try await demo.reply(to: text, context: context); result.source = "Demo reply · local, not Groq"; return result
        }
        if text.lowercased().range(of: #"\b(remember|memory|memories|profile)\b"#, options: .regularExpression) != nil {
            var result = try await demo.reply(to: text, context: context); result.source = "Local memory · not shared with Groq"; return result
        }
        do { return try await cloud.reply(to: text, context: context) }
        catch is CancellationError { throw CancellationError() }
        catch {
            var result = try await demo.reply(to: text, context: context)
            result.source = "Demo fallback · not a Groq response"
            result.warning = error.localizedDescription
            return result
        }
    }
}
