import SwiftUI

struct HomeView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var moviesVM = RatingViewModel(contentType: .movies)
    @StateObject private var seriesVM = RatingViewModel(contentType: .series)

    private var currentVM: RatingViewModel {
        coordinator.selectedContentType == .movies ? moviesVM : seriesVM
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 8)
                    contentForPhase(currentVM.phase)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentVM.phase)
        .animation(.easeInOut(duration: 0.2), value: coordinator.selectedContentType)
    }

    @ViewBuilder
    private func contentForPhase(_ phase: RatingViewModel.Phase) -> some View {
        switch phase {
        case .welcome:
            WelcomeView { currentVM.startOnboarding() }

        case .loading:
            LoadingView()

        case .rating:
            RatingPhaseView(vm: currentVM)

        case .matching:
            MatchingView()

        case .recommendations:
            RecommendationsView(vm: currentVM)
        }
    }
}

// MARK: - Welcome
struct WelcomeView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text("🍿")
                    .font(.system(size: 64))

                Text("FlickMatch")
                    .font(AppTheme.english(32, weight: .bold))
                    .foregroundStyle(AppTheme.goldGradient)

                Text("قيّم أفضل 10 أفلام ومسلسلات\nونلاقي لك ناس نفس ذوقك\nونقترح عليك اللي بيعجبك")
                    .font(AppTheme.arabic(15))
                    .foregroundColor(AppTheme.textDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .padding(.top, 60)
            .padding(.bottom, 40)

            Button(action: onStart) {
                Text("يلا نبدأ 🎬")
                    .font(AppTheme.arabic(16, weight: .bold))
                    .foregroundColor(AppTheme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.goldGradient)
                    .cornerRadius(AppTheme.radius)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Loading
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(AppTheme.gold)
                .scaleEffect(1.5)
            Text("جاري التحميل...")
                .font(AppTheme.arabic(14))
                .foregroundColor(AppTheme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Matching Animation
struct MatchingView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 20) {
            Text("🔍")
                .font(.system(size: 56))
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                        scale = 1.08
                    }
                }

            Text("ندور على توأم ذوقك...")
                .font(AppTheme.arabic(20, weight: .bold))
                .foregroundColor(AppTheme.gold)

            Text("نقارن تقييماتك مع آلاف المستخدمين")
                .font(AppTheme.arabic(14))
                .foregroundColor(AppTheme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}
