import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        Group {
            if !appModel.isSignedIn { LoginView() }
            else if appModel.needsOnboarding { OnboardingView() }
            else { MainTabView() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { appModel.evaluateRisks() }
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var step = 0
    var body: some View {
        NavigationStack {
            ZStack {
                StudydayBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Label("CampusMate", systemImage: "sparkles").font(.headline).foregroundStyle(StudydayTheme.accent)
                        Text(["Hey, let’s get to know you.", "What are you working toward?", "Make this buddy yours."][step])
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                        Text("\(step + 1) of 3 · Everything is optional")
                            .font(.caption).foregroundStyle(StudydayTheme.muted)
                        Group {
                            if step == 0 {
                                TextField("What should I call you?", text: $appModel.profile.name)
                                TextField("Major", text: $appModel.profile.major)
                                Picker("Academic year", selection: $appModel.profile.year) {
                                    Text("Prefer not to say").tag("")
                                    ForEach(["First year", "Sophomore", "Junior", "Senior", "Graduate", "Other"], id: \.self) { Text($0) }
                                }
                            } else if step == 1 {
                                TextField("Academic goals (e.g. an A in Calculus II)", text: $appModel.profile.goal, axis: .vertical)
                                TextField("Interests (e.g. AI, football, music)", text: $appModel.profile.interests, axis: .vertical)
                            } else {
                                Toggle("Let Buddy send in-app exam and progress reminders", isOn: $appModel.profile.reminders)
                                Text("You’re in control. Reminders stay in your chat and respect quiet hours. Change this anytime in Me. This prototype doesn’t send push notifications.")
                                    .font(.subheadline).foregroundStyle(StudydayTheme.muted)
                            }
                        }.textFieldStyle(.roundedBorder)
                        Button(step == 2 ? "Meet your buddy" : "Continue") { advance() }
                            .buttonStyle(.borderedProminent).tint(StudydayTheme.accent)
                        Button("Skip for now") { advance() }.foregroundStyle(StudydayTheme.muted)
                        if step > 0 { Button("Back") { step -= 1 } }
                    }.padding(26)
                }
            }
            .foregroundStyle(StudydayTheme.ink)
            .toolbar { Button(appModel.isDemo ? "Exit demo" : "Sign out") { appModel.signOut() } }
        }
    }
    private func advance() {
        if step < 2 { step += 1 } else { appModel.completeOnboarding() }
    }
}
