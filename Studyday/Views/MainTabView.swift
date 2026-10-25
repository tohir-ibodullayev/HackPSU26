import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        TabView(selection: $appModel.selectedTab) {
            ChatView()
                .tabItem {
                    Label("AI Chat", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(AppTab.chat)

            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)

            ProfileView()
                .tabItem {
                    Label("You", systemImage: "person.crop.circle")
                }
                .tag(AppTab.profile)
        }
        .tint(StudydayTheme.accent)
    }
}

struct ProfileView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        NavigationStack {
            ZStack {
                StudydayBackground()
                List {
                    if let session = appModel.session {
                        Section {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(StudydayTheme.mist)
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Text(String(session.displayName.prefix(1)))
                                            .font(.title2.weight(.bold))
                                            .foregroundStyle(StudydayTheme.iconBlue)
                                    )
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.displayName)
                                        .font(.system(.headline, design: .rounded))
                                        .foregroundStyle(StudydayTheme.ink)
                                    Text(session.email)
                                        .font(.subheadline)
                                        .foregroundStyle(StudydayTheme.muted)
                                    Text(session.provider.title)
                                        .font(.caption)
                                        .foregroundStyle(StudydayTheme.accent)
                                }
                            }
                            .listRowBackground(StudydayTheme.paperElevated)
                        }

                        Section("Demo") {
                            LabeledContent("Courses", value: "\(appModel.courses.count)")
                            Text("Auth, syllabus extraction, and chat replies are local mocks. Swap Mock* services for your friend’s API.")
                                .font(.footnote)
                                .foregroundStyle(StudydayTheme.muted)
                        }

                        Section {
                            Button(role: .destructive) {
                                appModel.signOut()
                            } label: {
                                Text("Sign out")
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("You")
        }
    }
}
