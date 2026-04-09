import SwiftUI

@main
struct FlickMatchApp: App {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var ratingStore = RatingStore.shared
    @StateObject private var watchlistStore = WatchlistStore.shared
    @StateObject private var authService = AuthService.shared
    @StateObject private var notificationService = NotificationService.shared

    init() {
        FirebaseConfig.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(coordinator)
                .environmentObject(ratingStore)
                .environmentObject(watchlistStore)
                .environmentObject(authService)
                .environmentObject(notificationService)
                .preferredColorScheme(.dark)
                .task {
                    await notificationService.requestPermission()
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        ContentView()
    }
}
