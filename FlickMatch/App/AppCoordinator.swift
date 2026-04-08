import SwiftUI

enum AppTab {
    case home, discover, search, notifications, profile
}

enum ContentType: String, CaseIterable {
    case movies = "movies"
    case series = "series"

    var displayName: String {
        switch self {
        case .movies: return "أفلام"
        case .series: return "مسلسلات"
        }
    }

    var icon: String {
        switch self {
        case .movies: return "🎬"
        case .series: return "📺"
        }
    }
}

final class AppCoordinator: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var selectedContentType: ContentType = .movies
    @Published var unreadNotifications: Int = 2
}
