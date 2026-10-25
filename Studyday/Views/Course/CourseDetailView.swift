import SwiftUI

struct CourseDetailView: View {
    @EnvironmentObject private var appModel: AppModel
    let courseID: String
    @State private var showEdit = false
    @State private var grading: Assessment?
    @State private var scenario = 85.0
    @State private var confirmDelete = false
    @Environment(\.dismiss) private var dismiss
    private var course: CourseItem? { appModel.courses.first { $0.id == courseID } }
    var body: some View {
        Group {
            if let course {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(course.title).font(.system(size: 28, weight: .semibold, design: .rounded))
                            Text(course.isDemo ? "Demo course · example weights and deadlines" : course.term)
                                .font(.caption).foregroundStyle(StudydayTheme.muted)
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Target grade", selection: Binding(get: { course.target }, set: { appModel.setTarget($0, courseID: courseID) })) {
                                ForEach(TargetGrade.allCases) { target in
                                    Text("\(target.rawValue) · \(target.threshold, specifier: "%.0f")%").tag(target)
                                }
                            }
                            Text("Prototype letter thresholds. Confirm your instructor’s grading scale.").font(.caption).foregroundStyle(StudydayTheme.muted)
                        }.campusCard()
                        GradeResultView(code: course.code, result: appModel.summary(course))
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Assessment weights & grades").font(.headline)
                            Text("Each row is a share of the final course grade. Enter category totals only when that entire category is graded.").font(.caption).foregroundStyle(StudydayTheme.muted)
                            ForEach(course.assessments) { item in
                                Button { grading = item } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title).font(.subheadline.bold())
                                            Text("\(item.weight, specifier: "%.0f")% of final grade").font(.caption).foregroundStyle(StudydayTheme.muted)
                                        }
                                        Spacer()
                                        if let score = item.score { Text("\(score, specifier: "%.1f")%") }
                                        else { Text("Add grade").foregroundStyle(StudydayTheme.accent) }
                                    }.padding(.vertical, 6)
                                }.buttonStyle(.plain)
                            }
                            if course.assessments.isEmpty { Text("No assessment weights yet. Use Edit to enter the full weighting from your syllabus.").font(.subheadline) }
                            Button("Add Grade") { grading = course.assessments.first }
                                .buttonStyle(.bordered).disabled(course.assessments.isEmpty)
                        }.campusCard()
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What if…").font(.headline)
                            Text("I average \(scenario, specifier: "%.0f")% on all remaining work.").font(.subheadline)
                            Slider(value: $scenario, in: 0...100, step: 1).accessibilityLabel("Remaining work score")
                            if let result = appModel.summary(course).projectedFinal(remainingScore: scenario) {
                                Text("Projected final: \(result, specifier: "%.1f")%")
                                    .font(.title3.bold())
                                Text("A scenario, not an entered grade or prediction.").font(.caption).foregroundStyle(StudydayTheme.muted)
                            } else { Text("Enter a grade and valid assessment weights to try a scenario.").font(.caption) }
                        }.campusCard()
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Important syllabus policies").font(.headline)
                            Text(course.policies).font(.subheadline).foregroundStyle(StudydayTheme.muted)
                        }.campusCard()
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Deadlines").font(.headline)
                            ForEach(course.exams + course.quizzes + course.assignments) { task in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(task.title)
                                        if !task.notes.isEmpty { Text(task.notes).font(.caption).foregroundStyle(StudydayTheme.muted) }
                                    }
                                    Spacer()
                                    if let due = task.dueDate { Text(due, style: .date).font(.caption) }
                                }
                            }
                        }.campusCard()
                        Button("Ask Buddy about my grades") {
                            appModel.selectedTab = .chat
                            appModel.sendUserText("How am I doing in \(course.code)? Show my grades.")
                        }.buttonStyle(.borderedProminent).disabled(appModel.isChatBusy)
                        Button("Remove course", role: .destructive) { confirmDelete = true }
                    }.padding(16)
                }.background(StudydayBackground())
                .navigationTitle(course.code).navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Edit") { showEdit = true } }
                .sheet(isPresented: $showEdit) {
                    CourseEditView(course: course) { appModel.updateCourse($0) }
                }
                .sheet(item: $grading) { item in
                    GradeEntryView(courseID: courseID, assessment: item)
                }
                .confirmationDialog("Remove this course and its grades?", isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button("Remove course", role: .destructive) { appModel.deleteCourse(course); dismiss() }
                }
            } else { ContentUnavailableView("Course unavailable", systemImage: "book.closed") }
        }
    }
}

struct GradeEntryView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    let courseID: String
    let assessment: Assessment
    @State private var score: String
    @State private var error: String?
    init(courseID: String, assessment: Assessment) {
        self.courseID = courseID; self.assessment = assessment
        _score = State(initialValue: assessment.score.map { String($0) } ?? "")
    }
    var body: some View {
        NavigationStack {
            Form {
                Section(assessment.title) {
                    Text("Fictional demo scores only. Never enter actual student grades for cloud use.").font(.caption).foregroundStyle(.secondary)
                    TextField("Score as a percentage (0–100)", text: $score).keyboardType(.decimalPad)
                    Text("Enter percentage, not raw points. For 42 out of 50, enter 84.").font(.caption)
                    Text("Weight: \(assessment.weight, specifier: "%.0f")% of final grade")
                    if let error { Text(error).foregroundStyle(StudydayTheme.danger) }
                }
                if assessment.score != nil {
                    Button("Remove entered grade", role: .destructive) {
                        if appModel.setScore(nil, assessmentID: assessment.id, courseID: courseID) { dismiss() }
                    }
                }
            }
            .navigationTitle("Add Grade").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cleaned = score.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
                        guard let value = Double(cleaned), value.isFinite, (0...100).contains(value) else { error = "Enter a percentage between 0 and 100."; return }
                        if appModel.setScore(value, assessmentID: assessment.id, courseID: courseID) { dismiss() }
                        else { error = "This assessment is no longer available." }
                    }
                }
            }
        }.presentationDetents([.medium, .large])
    }
}

struct GradeResultView: View {
    let code: String
    let result: GradeSummary
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(code, systemImage: "chart.bar.xaxis").font(.headline)
                Spacer()
                Text("Target \(result.target, specifier: "%.0f")%").font(.caption.bold())
            }
            Text(result.status).font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(result.atRisk ? StudydayTheme.danger : StudydayTheme.ink)
            if !result.valid {
                Text("Assessment weights must be positive and total 100%. No reliable grade estimate is available yet.")
            } else if let average = result.recordedAverage {
                Text("\(average, specifier: "%.1f")% on entered work")
                Text("Based on \(result.completedWeight, specifier: "%.0f")% of the course. This is not your final average.")
                    .font(.caption).foregroundStyle(StudydayTheme.muted)
                if let maximum = result.maximumPossible {
                    Text("Maximum possible final: \(maximum, specifier: "%.1f")%")
                }
                if let required = result.requiredRemaining {
                    Text(required > 100 ? "The goal requires more than 100% on remaining work." : String(format: "Need %.1f%% on remaining work to reach the target.", required))
                        .font(.caption)
                }
            } else {
                Text("No scores entered. Your current grade is unknown.")
            }
            Text("Assumes fixed weights, no curves, drops, rounding, or extra credit.").font(.caption2).foregroundStyle(StudydayTheme.muted)
        }.font(.subheadline).campusCard()
    }
}
