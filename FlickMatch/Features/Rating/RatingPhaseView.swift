import SwiftUI

struct RatingPhaseView: View {
    @ObservedObject var vm: RatingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            HStack(spacing: 10) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppTheme.surface).frame(height: 3)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [AppTheme.gold, Color(hex: "#f0d48a")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * vm.progressValue, height: 3)
                    }
                }
                .frame(height: 3)

                Text("\(vm.ratedCount)/10")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.gold)
                    .monospacedDigit()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // Round title
            HStack {
                Text(vm.roundTitle)
                    .font(AppTheme.arabic(16, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // Media cards
            LazyVStack(spacing: 14) {
                ForEach(Array(vm.mediaItems.enumerated()), id: \.element.id) { idx, media in
                    let rating = Binding<Int?>(
                        get: { vm.pendingRatings[media.id]?.score },
                        set: { vm.setRating(contentId: media.id, score: $0) }
                    )
                    let notSeen = Binding<Bool>(
                        get: { vm.pendingRatings[media.id] != nil && vm.pendingRatings[media.id]?.score == nil },
                        set: { vm.setNotSeen(contentId: media.id, notSeen: $0) }
                    )

                    MediaCard(
                        media: media,
                        rank: idx + 1,
                        genres: vm.genres,
                        rating: rating,
                        hasNotSeen: notSeen
                    )
                    .padding(.horizontal, 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(idx) * 0.05), value: vm.phase)
                }
            }

            // Submit button
            Button(action: vm.submitRatings) {
                Text("اعرض التوصيات ✨")
                    .font(AppTheme.arabic(16, weight: .bold))
                    .foregroundColor(AppTheme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(vm.canSubmit ? AppTheme.goldGradient : LinearGradient(colors: [AppTheme.textDim.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(AppTheme.radius)
            }
            .disabled(!vm.canSubmit)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 100) // Space for bottom nav bar
        }
    }
}
