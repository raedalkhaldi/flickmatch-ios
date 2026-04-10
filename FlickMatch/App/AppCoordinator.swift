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

    /// When true, present the Sign in with Apple sheet over the current tab.
    /// Any feature that needs an authenticated user can set this to true
    /// (e.g. following users, cloud-sync, account-only screens).
    @Published var showAuthSheet: Bool = false

    /// Optional context shown to the user on the auth sheet explaining *why*
    /// sign-in is being requested ("سجّل لمتابعة المستخدمين", etc).
    @Published var authSheetContext: String? = nil

    func requestSignIn(context: String? = nil) {
        authSheetContext = context
        showAuthSheet = true
    }
}
