import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var showSamples = false
    @State private var importing = false
    @State private var importError: String?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Small steps. Real progress.")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                    Text("Grades are entered by you. Nothing is synced from Canvas. Demo courses and weights are examples; verify your own syllabus.")
                        .font(.subheadline).foregroundStyle(StudydayTheme.muted)
                    if appModel.courses.isEmpty {
                        ContentUnavailableView("Your semester starts here", systemImage: "book.closed", description: Text("Import a syllabus or add a demo course to explore grade goals."))
                    }
                    ForEach(appModel.courses) { course in
                        NavigationLink { CourseDetailView(courseID: course.id) } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(course.code).font(.caption.bold()).foregroundStyle(StudydayTheme.accent)
                                    Spacer()
                                    if course.isDemo { Text("DEMO").font(.caption2.bold()).foregroundStyle(StudydayTheme.muted) }
                                    Image(systemName: "chevron.right").font(.caption)
                                }
                                Text(course.title).font(.system(.title3, design: .rounded).weight(.semibold))
                                Text("Target \(course.target.rawValue) · \(course.target.threshold, specifier: "%.0f")%")
                                if let average = appModel.summary(course).recordedAverage {
                                    Text("\(average, specifier: "%.1f")% on entered work · \(appModel.summary(course).completedWeight, specifier: "%.0f")% of course")
                                        .font(.caption).foregroundStyle(StudydayTheme.muted)
                                } else {
                                    Text("Current grade unknown").font(.caption).foregroundStyle(StudydayTheme.muted)
                                }
                                Text(appModel.summary(course).status).font(.subheadline).foregroundStyle(StudydayTheme.muted)
                            }.campusCard()
                        }.buttonStyle(.plain)
                    }
                    Text("Coming up").font(.title3.bold())
                    let upcoming = appModel.courses.flatMap { c in (c.exams + c.quizzes + c.assignments).map { (c.code, $0) } }
                        .filter { $0.1.dueDate.map { $0 >= Calendar.current.startOfDay(for: Date()) } ?? false }
                        .sorted { ($0.1.dueDate ?? .distantFuture) < ($1.1.dueDate ?? .distantFuture) }
                    if upcoming.isEmpty { Text("No upcoming deadlines entered.").foregroundStyle(StudydayTheme.muted) }
                    ForEach(Array(upcoming.prefix(8).enumerated()), id: \.offset) { _, entry in
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(entry.0) · \(entry.1.title)").font(.headline)
                            if let date = entry.1.dueDate { Text(date, style: .date).font(.caption).foregroundStyle(StudydayTheme.muted) }
                            if !entry.1.notes.isEmpty { Text(entry.1.notes).font(.caption).foregroundStyle(StudydayTheme.muted) }
                        }.campusCard()
                    }
                    Button("Import syllabus (demo extraction)") { importing = true }.buttonStyle(.borderedProminent)
                    Button("Try a sample syllabus") { showSamples = true }.buttonStyle(.bordered)
                    if let error = importError ?? appModel.chatError { Text(error).font(.footnote).foregroundStyle(StudydayTheme.danger) }
                }.padding(16)
            }.background(StudydayBackground())
            .navigationTitle("Academics")
            .confirmationDialog("Add sample course", isPresented: $showSamples, titleVisibility: .visible) {
                Button("MATH 141 sample") { appModel.attachSyllabus(fileName: "MATH141_sample.pdf") }
                Button("CMPSC 221 sample") { appModel.attachSyllabus(fileName: "CMPSC221_sample.pdf") }
            } message: { Text("Sample extraction creates fictional course details. It does not infer any grades.") }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf, .plainText], allowsMultipleSelection: false) { result in
                do {
                    guard let url = try result.get().first else { return }
                    // Filename-only mock: do not read or upload a student's actual document.
                    appModel.attachSyllabus(fileName: url.lastPathComponent)
                    importError = nil
                } catch { importError = "The file couldn’t be selected. Please try again." }
            }
        }
    }
}
