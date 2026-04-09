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
                    let nonce = AppleSignInHelper.shared.generateNonce()
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = AppleSignInHelper.shared.sha256(nonce)
                } onCompletion: { result in
                    switch result {
                    case .success(let auth):
                        Task {
                            await self.auth.handleAppleSignIn(
                                authorization: auth,
                                nonce: AppleSignInHelper.shared.currentNonce ?? ""
                            )
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
                Text("بتسجيلك توافق على شروط الاستخدام وسياسة الخصوصية")
                    .font(AppTheme.arabic(11))
                    .foregroundColor(AppTheme.textDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
            }
        }
    }
}
