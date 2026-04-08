import Foundation
import AuthenticationServices
import FirebaseAuth

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userId: String?
    @Published var displayName: String?

    var currentUser: FirebaseAuth.User? { Auth.auth().currentUser }
    private var authListener: AuthStateDidChangeListenerHandle?

    private init() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                self?.userId = user?.uid
                self?.displayName = user?.displayName
            }
        }
    }

    // MARK: - Email / Password
    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            await FirestoreService.shared.createUserProfile(
                uid: result.user.uid, displayName: displayName, email: email
            )
        } catch {
            errorMessage = mapAuthError(error)
        }
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = mapAuthError(error)
        }
        isLoading = false
    }

    func signOut() {
        try? Auth.auth().signOut()
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = mapAuthError(error)
        }
        isLoading = false
    }

    // MARK: - Sign in with Apple
    func handleAppleSignIn(authorization: ASAuthorization, nonce: String) async {
        isLoading = true
        errorMessage = nil
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let idToken = appleIDCredential.identityToken,
              let tokenString = String(data: idToken, encoding: .utf8)
        else {
            errorMessage = "فشل في استلام بيانات Apple"
            isLoading = false
            return
        }
        let credential = OAuthProvider.appleCredential(
            withIDToken: tokenString, rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        do {
            let result = try await Auth.auth().signIn(with: credential)
            let name = appleIDCredential.fullName
            let dn = [name?.givenName, name?.familyName].compactMap { $0 }.joined(separator: " ")
            if !dn.isEmpty {
                let req = result.user.createProfileChangeRequest()
                req.displayName = dn
                try? await req.commitChanges()
            }
            await FirestoreService.shared.createUserProfileIfNeeded(
                uid: result.user.uid,
                displayName: dn.isEmpty ? "مستخدم جديد" : dn,
                email: result.user.email ?? ""
            )
        } catch {
            errorMessage = mapAuthError(error)
        }
        isLoading = false
    }

    private func mapAuthError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:     return "البريد مستخدم بالفعل"
        case AuthErrorCode.weakPassword.rawValue:          return "كلمة المرور ضعيفة (6 أحرف على الأقل)"
        case AuthErrorCode.invalidEmail.rawValue:          return "بريد إلكتروني غير صالح"
        case AuthErrorCode.wrongPassword.rawValue,
             AuthErrorCode.userNotFound.rawValue:          return "البريد أو كلمة المرور غير صحيحة"
        default:                                           return error.localizedDescription
        }
    }
}
