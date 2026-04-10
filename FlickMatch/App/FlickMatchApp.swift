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
        AuthService.shared.validateSession()
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
    // App Store Review Guideline 5.1.1(v): features that are not
    // account-based must be accessible without registration.
    // We always show the main ContentView. Sign in is requested only
    // when the user attempts an account-based action (follow, sync, etc).
    var body: some View {
        ContentView()
    }
}
