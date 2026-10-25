import SwiftUI

@main
struct StudydayApp: App {
    @StateObject private var appModel = AppModel(buddy: ConfiguredBuddyService())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
        }
    }
}
