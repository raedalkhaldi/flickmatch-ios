import SwiftUI

@main
struct FlickMatchApp: App {
    @StateObject private var coordinator  = AppCoordinator()
    @StateObject private var ratingStore  = RatingStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
                .environmentObject(ratingStore)
                .preferredColorScheme(.dark)
        }
    }
}
