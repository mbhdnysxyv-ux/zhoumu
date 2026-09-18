import SwiftUI

@main
struct ZhouMuWatchApp: App {
    @StateObject private var settings = WatchSettings()

    var body: some Scene {
        WindowGroup {
            WeekView()
                .environmentObject(settings)
        }
    }
}
