import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
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
    }
}
