import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appModel: AppModel
    var body: some View {
        TabView(selection: $appModel.selectedTab) {
            ChatView().tabItem { Label("Buddy", systemImage: "bubble.left.and.bubble.right.fill") }.tag(AppTab.chat)
            HomeView().tabItem { Label("Academics", systemImage: "book.closed.fill") }.tag(AppTab.home)
            DiscoverView().tabItem { Label("Discover", systemImage: "sparkles") }.tag(AppTab.discover)
            ProfileView().tabItem { Label("Me", systemImage: "person.crop.circle") }.tag(AppTab.profile)
        }
        .tint(StudydayTheme.accent)
        .safeAreaInset(edge: .top, spacing: 0) {
            if let error = appModel.storageError {
                Text(error).font(.caption).padding(8).frame(maxWidth: .infinity).background(StudydayTheme.paperElevated)
            }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var memory = ""
    @State private var confirmReset = false
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label(appModel.profile.name.isEmpty ? "Your CampusMate" : appModel.profile.name, systemImage: "person.crop.circle.fill")
                        .font(.title2.bold())
                    Text(appModel.isDemo ? "Demo · saved on this device" : "Account session")
                        .font(.caption).foregroundStyle(StudydayTheme.muted)
                }
                Section("About you") {
                    TextField("Name", text: $appModel.profile.name)
                    TextField("Major", text: $appModel.profile.major)
                    TextField("Academic year", text: $appModel.profile.year)
                    TextField("Academic goals", text: $appModel.profile.goal, axis: .vertical)
                    TextField("Interests and hobbies", text: $appModel.profile.interests, axis: .vertical)
                }
                Section("How we talk") {
                    Picker("Style", selection: $appModel.profile.communication) {
                        ForEach(["Friendly and occasional", "Brief and direct", "Encouraging and detailed"], id: \.self) { Text($0) }
                    }
                    Toggle("Proactive in-app reminders", isOn: $appModel.profile.reminders)
                    Toggle("Quiet hours", isOn: $appModel.profile.quietHoursEnabled)
                    if appModel.profile.quietHoursEnabled {
                        Picker("From", selection: $appModel.profile.quietStart) {
                            ForEach(0..<24, id: \.self) { Text(String(format: "%02d:00", $0)).tag($0) }
                        }
                        Picker("Until", selection: $appModel.profile.quietEnd) {
                            ForEach(0..<24, id: \.self) { Text(String(format: "%02d:00", $0)).tag($0) }
                        }
                        Text("Uses your device’s local time. Matching start and end means quiet all day.")
                            .font(.caption).foregroundStyle(StudydayTheme.muted)
                    }
                }
                Section("What Buddy remembers") {
                    Text("Only what you choose to save. Edit a memory below or swipe left to delete it.")
                        .font(.caption).foregroundStyle(StudydayTheme.muted)
                    ForEach($appModel.profile.memories) { $item in
                        TextField("Memory", text: $item.text, axis: .vertical)
                    }.onDelete { appModel.profile.memories.remove(atOffsets: $0) }
                    HStack {
                        TextField("A little thing to remember", text: $memory)
                        Button("Save") {
                            appModel.profile.memories.append(StudentMemory(text: memory.trimmingCharacters(in: .whitespacesAndNewlines)))
                            memory = ""
                        }.disabled(memory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                Section {
                    if appModel.isDemo {
                        Button("Delete all local demo data", role: .destructive) { confirmReset = true }
                    }
                    Button("Sign out", role: .destructive) { appModel.signOut() }
                } footer: {
                    Text("Demo chat, courses, and preferences are stored on this device. No Canvas sync or live AI is connected.")
                }
            }
            .scrollContentBackground(.hidden).background(StudydayBackground())
            .navigationTitle("Me")
            .onChange(of: appModel.profile) { _, _ in appModel.saveProfile() }
            .confirmationDialog("Delete demo chat, grades, memories, and profile?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Delete demo data", role: .destructive) { appModel.clearDemoData() }
            }
        }
    }
}

struct DiscoverView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var category = "All"
    private var filtered: [CampusEvent] {
        appModel.events.filter { category == "All" || $0.category == category }.sorted {
            if recommended($0) != recommended($1) { return recommended($0) }
            return $0.date < $1.date
        }
    }
    private func recommended(_ event: CampusEvent) -> Bool {
        event.interests.contains { appModel.profile.interests.localizedCaseInsensitiveContains($0) }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("There’s more to your semester.").font(.system(size: 28, weight: .semibold, design: .rounded))
                    Text("Fictional demo events · Dates and places are samples, not real listings.")
                        .font(.caption).foregroundStyle(StudydayTheme.muted)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(["All", "Sports", "Clubs", "Social", "Career", "Hackathons"], id: \.self) { tag in
                                Button(tag) { category = tag }.buttonStyle(.bordered)
                                    .tint(category == tag ? StudydayTheme.accent : StudydayTheme.muted)
                            }
                        }
                    }
                    ForEach(filtered) { event in
                        NavigationLink {
                            EventDetailView(event: event)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                if recommended(event) { Label("Picked for your interests", systemImage: "sparkles").font(.caption).foregroundStyle(StudydayTheme.accent) }
                                EventSummaryView(event: event)
                            }.campusCard()
                        }.buttonStyle(.plain)
                    }
                    if filtered.isEmpty { ContentUnavailableView("No events here yet", systemImage: "sparkles") }
                }.padding(16)
            }.background(StudydayBackground()).navigationTitle("Discover")
        }
    }
}

struct EventSummaryView: View {
    let event: CampusEvent
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(event.category.uppercased()) · DEMO EVENT").font(.caption.weight(.semibold)).foregroundStyle(StudydayTheme.accent)
            Text(event.title).font(.system(.title3, design: .rounded).weight(.semibold)).foregroundStyle(StudydayTheme.ink)
            Label(event.date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
            Label(event.location, systemImage: "mappin.and.ellipse")
            Text(event.description)
        }.font(.subheadline).foregroundStyle(StudydayTheme.muted).frame(maxWidth: .infinity, alignment: .leading)
    }
}
struct EventDetailView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    let event: CampusEvent
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                EventSummaryView(event: event).campusCard()
                Text("This is a fictional prototype event. No registration or real attendance is available.").font(.footnote).foregroundStyle(StudydayTheme.muted)
                Button("Ask Buddy about this") { dismiss(); appModel.askAbout(event) }
                    .buttonStyle(.borderedProminent).disabled(appModel.isChatBusy)
            }.padding(16)
        }.background(StudydayBackground()).navigationTitle("A little campus life").navigationBarTitleDisplayMode(.inline)
    }
}
