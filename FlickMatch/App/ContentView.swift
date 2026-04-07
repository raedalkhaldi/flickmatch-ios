import SwiftUI

struct ContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            // Top bar + content
            VStack(spacing: 0) {
                if coordinator.selectedTab == .home {
                    TopBar()
                }
                tabContent
            }

            // Bottom navigation
            BottomNav()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch coordinator.selectedTab {
        case .home:     HomeView()
        case .discover: DiscoverView()
        case .profile:  ProfileView()
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
                    Button {
                        // TODO: Search
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.textDim)
                            .font(.system(size: 19))
                    }
                    Button {
                        // TODO: Notifications
                    } label: {
                        Image(systemName: "bell")
                            .foregroundColor(AppTheme.textDim)
                            .font(.system(size: 19))
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
        .background(
            AppTheme.background.opacity(0.92)
                .background(.ultraThinMaterial)
        )
    }
}

// MARK: - Bottom Navigation
struct BottomNav: View {
    @EnvironmentObject var coordinator: AppCoordinator

    private let items: [(tab: AppTab, icon: String, label: String)] = [
        (.home,     "house.fill",          "الرئيسية"),
        (.discover, "person.2.fill",       "اكتشف"),
        (.profile,  "person.crop.circle",  "حسابي"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tab.hashValue) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        coordinator.selectedTab = item.tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.icon)
                            .font(.system(size: 21))
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
                    Rectangle()
                        .fill(Color(hex: "#1a1a24"))
                        .frame(height: 1)
                }
        )
    }
}

extension AppTab: Hashable {}
