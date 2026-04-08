import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var auth: AuthService
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Logo
                    VStack(spacing: 12) {
                        Text("🎬")
                            .font(.system(size: 56))
                        Text("FlickMatch")
                            .font(AppTheme.english(36, weight: .bold))
                            .foregroundStyle(AppTheme.goldGradient)
                        Text("لاقي توأم ذوقك")
                            .font(AppTheme.arabic(15))
                            .foregroundColor(AppTheme.textDim)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)

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

                    // Divider
                    HStack {
                        Rectangle().fill(Color(hex: "#252530")).frame(height: 1)
                        Text("أو")
                            .font(AppTheme.arabic(13))
                            .foregroundColor(AppTheme.textDim)
                            .padding(.horizontal, 12)
                        Rectangle().fill(Color(hex: "#252530")).frame(height: 1)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 24)

                    // Email form
                    VStack(spacing: 14) {
                        if isSignUp {
                            AuthTextField(
                                icon: "person",
                                placeholder: "الاسم",
                                text: $displayName
                            )
                        }

                        AuthTextField(
                            icon: "envelope",
                            placeholder: "البريد الإلكتروني",
                            text: $email,
                            keyboardType: .emailAddress
                        )

                        AuthTextField(
                            icon: "lock",
                            placeholder: "كلمة المرور",
                            text: $password,
                            isSecure: true
                        )
                    }
                    .padding(.horizontal, 30)

                    // Error
                    if let error = auth.errorMessage {
                        Text(error)
                            .font(AppTheme.arabic(13))
                            .foregroundColor(AppTheme.accent)
                            .padding(.top, 10)
                            .padding(.horizontal, 30)
                    }

                    // Submit button
                    Button {
                        Task {
                            if isSignUp {
                                await auth.signUp(email: email, password: password, displayName: displayName)
                            } else {
                                await auth.signIn(email: email, password: password)
                            }
                        }
                    } label: {
                        Group {
                            if auth.isLoading {
                                ProgressView().tint(AppTheme.background)
                            } else {
                                Text(isSignUp ? "إنشاء حساب" : "تسجيل الدخول")
                            }
                        }
                        .font(AppTheme.arabic(16, weight: .bold))
                        .foregroundColor(AppTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.goldGradient)
                        .cornerRadius(AppTheme.radius)
                    }
                    .disabled(auth.isLoading || email.isEmpty || password.isEmpty)
                    .padding(.horizontal, 30)
                    .padding(.top, 20)

                    // Toggle sign up / sign in
                    Button {
                        withAnimation { isSignUp.toggle() }
                        auth.errorMessage = nil
                    } label: {
                        Text(isSignUp ? "عندك حساب؟ سجّل دخول" : "ما عندك حساب؟ سجّل الحين")
                            .font(AppTheme.arabic(14))
                            .foregroundColor(AppTheme.gold)
                    }
                    .padding(.top, 16)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Auth Text Field
struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.textDim)
                .font(.system(size: 15))
                .frame(width: 20)

            if isSecure {
                SecureField("", text: $text, prompt:
                    Text(placeholder)
                        .foregroundColor(AppTheme.textDim)
                        .font(AppTheme.arabic(14))
                )
                .font(AppTheme.arabic(14))
                .foregroundColor(AppTheme.textPrimary)
            } else {
                TextField("", text: $text, prompt:
                    Text(placeholder)
                        .foregroundColor(AppTheme.textDim)
                        .font(AppTheme.arabic(14))
                )
                .font(AppTheme.arabic(14))
                .foregroundColor(AppTheme.textPrimary)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.surface)
        .cornerRadius(12)
    }
}
