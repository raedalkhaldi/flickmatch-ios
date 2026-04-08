import SwiftUI

struct ContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if coordinator.selectedTab == .home {
                    TopBar()
                }
                tabContent
            }

            BottomNav()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch coordinator.selectedTab {
        case .home:          HomeView()
        case .discover:      DiscoverView()
        case .search:        SearchView()
        case .notifications: NotificationsView()
        case .profile:       ProfileView()
        }
    }
}

// MARK: - Top Bar
struct TopBar: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("FlickMatch")
                    .font(AppTheme.english(24, weight: .bold))
                    .foregroundStyle(AppTheme.goldGradient)

                Spacer()

                HStack(spacing: 16) {
                    Button { coordinator.selectedTab = .search } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.textDim)
                            .font(.system(size: 19))
                    }
                    Button { coordinator.selectedTab = .notifications } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .foregroundColor(AppTheme.textDim)
                                .font(.system(size: 19))
                            if coordinator.unreadNotifications > 0 {
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -2)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)

            // Content tabs
            HStack(spacing: 0) {
                ForEach(ContentType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            coordinator.selectedContentType = type
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text("\(type.icon) \(type.displayName)")
                                .font(AppTheme.arabic(14, weight: .bold))
                                .foregroundColor(
                                    coordinator.selectedContentType == type
                                        ? AppTheme.gold : AppTheme.textDim
                                )
                            Rectangle()
                                .fill(coordinator.selectedContentType == type ? AppTheme.gold : Color.clear)
                                .frame(height: 2)
                                .cornerRadius(1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
        }
        .background(AppTheme.background.opacity(0.92).background(.ultraThinMaterial))
    }
}

// MARK: - Bottom Navigation
struct BottomNav: View {
    @EnvironmentObject var coordinator: AppCoordinator

    private struct NavItem {
        let tab: AppTab
        let icon: String
        let activeIcon: String
        let label: String
    }

    private let items: [NavItem] = [
        NavItem(tab: .home,          icon: "house",               activeIcon: "house.fill",              label: "الرئيسية"),
        NavItem(tab: .discover,      icon: "person.2",            activeIcon: "person.2.fill",           label: "اكتشف"),
        NavItem(tab: .search,        icon: "magnifyingglass",     activeIcon: "magnifyingglass",         label: "بحث"),
        NavItem(tab: .notifications, icon: "bell",                activeIcon: "bell.fill",               label: "إشعارات"),
        NavItem(tab: .profile,       icon: "person.crop.circle",  activeIcon: "person.crop.circle.fill", label: "حسابي"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.label) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        coordinator.selectedTab = item.tab
                        if item.tab == .notifications {
                            coordinator.unreadNotifications = 0
                        }
                    }
                } label: {
                    VStack(spacing: 3) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: coordinator.selectedTab == item.tab ? item.activeIcon : item.icon)
                                .font(.system(size: 20))
                            if item.tab == .notifications && coordinator.unreadNotifications > 0 {
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 7, height: 7)
                                    .offset(x: 4, y: -2)
                            }
                        }
                        Text(item.label)
                            .font(AppTheme.arabic(9))
                    }
                    .foregroundColor(coordinator.selectedTab == item.tab ? AppTheme.gold : AppTheme.textDim)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(
            AppTheme.background.opacity(0.95)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    Rectangle().fill(Color(hex: "#1a1a24")).frame(height: 1)
                }
        )
    }
}

extension AppTab: Hashable {}
