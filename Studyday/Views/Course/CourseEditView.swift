import SwiftUI

struct CourseEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CourseItem
    let onSave: (CourseItem) -> Void

    init(course: CourseItem, onSave: @escaping (CourseItem) -> Void) {
        _draft = State(initialValue: course)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Course") {
                    TextField("Code", text: $draft.code)
                    TextField("Title", text: $draft.title)
                    TextField("Instructor", text: $draft.instructor)
                    TextField("Term", text: $draft.term)
                    TextField("Meeting times", text: $draft.meetingTimes)
                    TextField("Location", text: $draft.location)
                }

                Section("Exams") {
                    taskEditor(kind: .exams)
                }
                Section("Quizzes") {
                    taskEditor(kind: .quizzes)
                }
                Section("Assignments") {
                    taskEditor(kind: .assignments)
                }
            }
            .navigationTitle("Edit course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private enum Kind { case exams, quizzes, assignments }

    @ViewBuilder
    private func taskEditor(kind: Kind) -> some View {
        let tasks = binding(for: kind)
        ForEach(Array(tasks.wrappedValue.enumerated()), id: \.element.id) { index, _ in
            VStack(alignment: .leading, spacing: 6) {
                TextField(placeholder(for: kind), text: tasks[index].title)
                TextField("Notes", text: tasks[index].notes)
                DatePicker(
                    "Due",
                    selection: Binding(
                        get: { tasks.wrappedValue[index].dueDate ?? Date() },
                        set: { tasks.wrappedValue[index].dueDate = $0 }
                    ),
                    displayedComponents: .date
                )
            }
        }
        .onDelete { offsets in
            tasks.wrappedValue.remove(atOffsets: offsets)
        }

        Button {
            tasks.wrappedValue.append(
                CourseTask(id: UUID().uuidString, title: "", dueDate: Date(), notes: "")
            )
        } label: {
            Label("Add item", systemImage: "plus")
        }
    }

    private func binding(for kind: Kind) -> Binding<[CourseTask]> {
        switch kind {
        case .exams: return $draft.exams
        case .quizzes: return $draft.quizzes
        case .assignments: return $draft.assignments
        }
    }

    private func placeholder(for kind: Kind) -> String {
        switch kind {
        case .exams: return "Exam title"
        case .quizzes: return "Quiz title"
        case .assignments: return "Assignment title"
        }
    }
}
