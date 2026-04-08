import SwiftUI

#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct FlickMatchApp: App {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var ratingStore = RatingStore.shared
    @StateObject private var authService = AuthService.shared

    init() {
        FirebaseConfig.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(coordinator)
                .environmentObject(ratingStore)
                .environmentObject(authService)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        if auth.isAuthenticated {
            ContentView()
        } else {
            AuthView()
        }
    }
}
