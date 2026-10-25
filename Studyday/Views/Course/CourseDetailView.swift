import SwiftUI

struct CourseDetailView: View {
    @EnvironmentObject private var appModel: AppModel
    let courseID: String

    @State private var segment: TaskSegment = .exams
    @State private var showEdit = false

    private var course: CourseItem? {
        appModel.courses.first { $0.id == courseID }
    }

    var body: some View {
        Group {
            if let course {
                content(course)
            } else {
                ContentUnavailableView("Course removed", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func content(_ course: CourseItem) -> some View {
        ZStack {
            StudydayBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header(course)

                    Picker("Section", selection: $segment) {
                        ForEach(TaskSegment.allCases) { seg in
                            Text(seg.title).tag(seg)
                        }
                    }
                    .pickerStyle(.segmented)

                    taskList(for: course)
                }
                .padding(16)
            }
        }
        .navigationTitle(course.code)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            CourseEditView(course: course) { updated in
                appModel.updateCourse(updated)
            }
        }
    }

    private func header(_ course: CourseItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(course.title)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(StudydayTheme.ink)
            Label(course.instructor, systemImage: "person.fill")
            Label(course.term, systemImage: "calendar")
            Label(course.meetingTimes, systemImage: "clock")
            Label(course.location, systemImage: "mappin.and.ellipse")
        }
        .font(.subheadline)
        .foregroundStyle(StudydayTheme.muted)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: StudydayTheme.cornerCard, style: .continuous)
                .fill(StudydayTheme.paperElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: StudydayTheme.cornerCard, style: .continuous)
                        .stroke(StudydayTheme.border, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func taskList(for course: CourseItem) -> some View {
        let items = tasks(for: course)
        if items.isEmpty {
            Text("Nothing listed for \(segment.title.lowercased()) yet. Use Edit to add them.")
                .font(.subheadline)
                .foregroundStyle(StudydayTheme.muted)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 10) {
                ForEach(items) { task in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: segment.icon)
                            .foregroundStyle(StudydayTheme.accent)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(StudydayTheme.ink)
                            if let due = task.dueDate {
                                Text(due, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(StudydayTheme.muted)
                            }
                            if !task.notes.isEmpty {
                                Text(task.notes)
                                    .font(.caption)
                                    .foregroundStyle(StudydayTheme.muted)
                            }
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(StudydayTheme.paperElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(StudydayTheme.border, lineWidth: 1)
                            )
                    )
                }
            }
        }
    }

    private func tasks(for course: CourseItem) -> [CourseTask] {
        switch segment {
        case .exams: return course.exams
        case .quizzes: return course.quizzes
        case .assignments: return course.assignments
        }
    }
}

enum TaskSegment: String, CaseIterable, Identifiable {
    case exams
    case quizzes
    case assignments

    var id: String { rawValue }

    var title: String {
        switch self {
        case .exams: return "Exams"
        case .quizzes: return "Quizzes"
        case .assignments: return "Assignments"
        }
    }

    var icon: String {
        switch self {
        case .exams: return "graduationcap.fill"
        case .quizzes: return "questionmark.circle.fill"
        case .assignments: return "checklist"
        }
    }
}
