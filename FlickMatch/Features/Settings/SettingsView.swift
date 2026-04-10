import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false
    @State private var showSignOutConfirm = false
    @State private var isDeleting = false

    private static let privacyURL = URL(string: "https://raedalkhaldi.github.io/flickmatch-ios/privacy.html")!
    private static let termsURL   = URL(string: "https://raedalkhaldi.github.io/flickmatch-ios/terms.html")!
    private static let supportURL = URL(string: "https://raedalkhaldi.github.io/flickmatch-ios/support.html")!
    private static let tmdbURL    = URL(string: "https://www.themoviedb.org/")!

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Account section — differs for guest vs signed-in
                        section(title: "الحساب") {
                            if auth.isAuthenticated {
                                accountCard
                            } else {
                                guestSignInCard
                            }
                        }

                        // Legal
                        section(title: "قانوني") {
                            VStack(spacing: 0) {
                                linkRow(icon: "lock.shield", label: "سياسة الخصوصية", url: Self.privacyURL)
                                divider
                                linkRow(icon: "doc.text", label: "شروط الاستخدام", url: Self.termsURL)
                                divider
                                linkRow(icon: "questionmark.circle", label: "الدعم / التواصل", url: Self.supportURL)
                            }
                            .cardStyle()
                        }

                        // Data source attribution (TMDb requirement)
                        section(title: "البيانات") {
                            VStack(alignment: .trailing, spacing: 10) {
                                Text("يستخدم FlickMatch واجهة TMDB لجلب معلومات الأفلام والمسلسلات، لكنه غير معتمد أو مصدّق من TMDB.")
                                    .font(AppTheme.arabic(12))
                                    .foregroundColor(AppTheme.textDim)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textDim.opacity(0.7))
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                Button {
                                    UIApplication.shared.open(Self.tmdbURL)
                                } label: {
                                    HStack(spacing: 6) {
                                        Text("themoviedb.org")
                                            .font(.system(size: 12, weight: .semibold))
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.system(size: 11))
                                    }
                                    .foregroundColor(AppTheme.gold)
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)

                                Text("معلومات توفر البث مقدمة من JustWatch")
                                    .font(AppTheme.arabic(11))
                                    .foregroundColor(AppTheme.textDim.opacity(0.7))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.top, 4)
                            }
                            .padding(14)
                            .cardStyle()
                        }

                        // Danger zone — only shown for signed-in users.
                        // Guests have no cloud account to sign out of or delete.
                        if auth.isAuthenticated {
                            section(title: "منطقة الحذر") {
                                VStack(spacing: 12) {
                                    Button { showSignOutConfirm = true } label: {
                                        actionRowLabel(icon: "rectangle.portrait.and.arrow.right",
                                                       label: "تسجيل خروج",
                                                       tint: AppTheme.textPrimary)
                                    }
                                    .cardStyle()

                                    Button { showDeleteConfirm = true } label: {
                                        actionRowLabel(icon: "trash",
                                                       label: "حذف الحساب نهائياً",
                                                       tint: AppTheme.accent)
                                    }
                                    .cardStyle()
                                }
                            }
                        }

                        // Version
                        VStack(spacing: 4) {
                            Text("FlickMatch")
                                .font(AppTheme.english(14, weight: .bold))
                                .foregroundStyle(AppTheme.goldGradient)
                            Text("الإصدار \(appVersion)")
                                .font(AppTheme.arabic(11))
                                .foregroundColor(AppTheme.textDim.opacity(0.7))
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إغلاق") { dismiss() }
                        .foregroundColor(AppTheme.gold)
                }
            }
            .overlay {
                if isDeleting {
                    ZStack {
                        Color.black.opacity(0.6).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView().tint(AppTheme.gold)
                            Text("جارٍ حذف الحساب…")
                                .font(AppTheme.arabic(13))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .padding(24)
                        .background(AppTheme.card)
                        .cornerRadius(AppTheme.radius)
                    }
                }
            }
            .confirmationDialog(
                "تسجيل الخروج؟",
                isPresented: $showSignOutConfirm,
                titleVisibility: .visible
            ) {
                Button("تسجيل الخروج", role: .destructive) {
                    auth.signOut()
                    dismiss()
                }
                Button("إلغاء", role: .cancel) {}
            }
            .alert("حذف الحساب نهائياً؟", isPresented: $showDeleteConfirm) {
                Button("إلغاء", role: .cancel) {}
                Button("حذف", role: .destructive) {
                    Task {
                        isDeleting = true
                        await auth.deleteAccount()
                        isDeleting = false
                        dismiss()
                    }
                }
            } message: {
                Text("سيتم حذف حسابك، تقييماتك، قائمة المتابعة، وقائمة \"أشوفه لاحقاً\" نهائياً. لا يمكن التراجع عن هذا الإجراء.")
            }
        }
    }

    // MARK: - Guest sign-in card
    private var guestSignInCard: some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.surface)
                        .frame(width: 48, height: 48)
                        .overlay(Circle().stroke(AppTheme.gold.opacity(0.4), lineWidth: 1))
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.gold)
                }
                VStack(alignment: .trailing, spacing: 2) {
                    Text("زائر")
                        .font(AppTheme.arabic(15, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("غير مسجّل دخول")
                        .font(AppTheme.arabic(11))
                        .foregroundColor(AppTheme.textDim)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Text("سجّل دخولك بـ Apple عشان تحفظ تقييماتك وقائمتك عبر الأجهزة وتتابع الأصدقاء.")
                .font(AppTheme.arabic(12))
                .foregroundColor(AppTheme.textDim)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Button {
                dismiss()
                // Defer slightly so the settings sheet is gone before the auth sheet appears.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    coordinator.requestSignIn(
                        context: "سجّل دخولك عشان تحفظ تقييماتك ومتابعاتك"
                    )
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 14, weight: .semibold))
                    Text("تسجيل الدخول بـ Apple")
                        .font(AppTheme.arabic(13, weight: .semibold))
                }
                .foregroundColor(AppTheme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(AppTheme.gold)
                .cornerRadius(AppTheme.radius)
            }
        }
        .padding(14)
        .cardStyle()
    }

    // MARK: - Account card
    private var accountCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [AppTheme.gold, AppTheme.goldDim],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                Text("👤").font(.system(size: 22))
            }
            VStack(alignment: .trailing, spacing: 2) {
                Text(auth.displayName ?? "مستخدم")
                    .font(AppTheme.arabic(15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                if let uid = auth.userId {
                    Text("@\(String(uid.prefix(8)))")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textDim)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(14)
        .cardStyle()
    }

    // MARK: - Helpers
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(title)
                .font(AppTheme.arabic(12, weight: .semibold))
                .foregroundColor(AppTheme.gold)
                .frame(maxWidth: .infinity, alignment: .trailing)
            content()
        }
    }

    private func linkRow(icon: String, label: String, url: URL) -> some View {
        Button {
            UIApplication.shared.open(url)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textDim)
                Spacer()
                Text(label)
                    .font(AppTheme.arabic(14))
                    .foregroundColor(AppTheme.textPrimary)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.gold)
                    .frame(width: 24)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.surface)
            .frame(height: 1)
            .padding(.horizontal, 14)
    }

    private func actionRowLabel(icon: String, label: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Spacer()
            Text(label)
                .font(AppTheme.arabic(14, weight: .semibold))
                .foregroundColor(tint)
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(tint)
                .frame(width: 24)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }
}

// MARK: - Card modifier
private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.card)
            .cornerRadius(AppTheme.radius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radius)
                    .stroke(AppTheme.surface, lineWidth: 1)
            )
    }
}

private extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
