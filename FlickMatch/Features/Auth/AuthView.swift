import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    /// When true, the view shows a close button in the top-right and will
    /// auto-dismiss once the user signs in. Use this when presenting AuthView
    /// as a sheet from inside the app (rather than as a root screen).
    var isPresentedAsSheet: Bool = false
    /// Optional context line shown above the logo (e.g. "سجّل لمتابعة المستخدمين").
    var contextMessage: String? = nil

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button (only when presented as a sheet)
                if isPresentedAsSheet {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.textDim)
                                .frame(width: 36, height: 36)
                                .background(AppTheme.surface)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                }

                Spacer()

                // Logo
                VStack(spacing: 12) {
                    Text("🎬")
                        .font(.system(size: 64))
                    Text("FlickMatch")
                        .font(AppTheme.english(36, weight: .bold))
                        .foregroundStyle(AppTheme.goldGradient)
                    Text("لاقي توأم ذوقك")
                        .font(AppTheme.arabic(15))
                        .foregroundColor(AppTheme.textDim)

                    if let ctx = contextMessage, !ctx.isEmpty {
                        Text(ctx)
                            .font(AppTheme.arabic(13))
                            .foregroundColor(AppTheme.gold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .padding(.top, 6)
                    }
                }
                .padding(.bottom, 50)

                // Sign in with Apple
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        Task {
                            await auth.handleAppleSignIn(authorization: authorization)
                        }
                    case .failure:
                        break
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .cornerRadius(AppTheme.radius)
                .padding(.horizontal, 30)

                // Error
                if let error = auth.errorMessage {
                    Text(error)
                        .font(AppTheme.arabic(13))
                        .foregroundColor(AppTheme.accent)
                        .padding(.top, 14)
                        .padding(.horizontal, 30)
                }

                // Loading
                if auth.isLoading {
                    ProgressView()
                        .tint(AppTheme.gold)
                        .padding(.top, 16)
                }

                Spacer()

                // Footer
                VStack(spacing: 8) {
                    Text("بتسجيلك توافق على:")
                        .font(AppTheme.arabic(11))
                        .foregroundColor(AppTheme.textDim)

                    HStack(spacing: 14) {
                        Button {
                            if let url = URL(string: "https://raedalkhaldi.github.io/flickmatch-ios/terms.html") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("شروط الاستخدام")
                                .font(AppTheme.arabic(11, weight: .semibold))
                                .foregroundColor(AppTheme.gold)
                                .underline()
                        }
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textDim)
                        Button {
                            if let url = URL(string: "https://raedalkhaldi.github.io/flickmatch-ios/privacy.html") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("سياسة الخصوصية")
                                .font(AppTheme.arabic(11, weight: .semibold))
                                .foregroundColor(AppTheme.gold)
                                .underline()
                        }
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
        .onChange(of: auth.isAuthenticated) { newValue in
            if isPresentedAsSheet && newValue {
                dismiss()
            }
        }
    }
}
