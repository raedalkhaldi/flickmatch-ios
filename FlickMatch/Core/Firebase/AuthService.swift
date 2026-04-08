import Foundation
import AuthenticationServices

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userId: String?
    @Published var displayName: String?

    #if canImport(FirebaseAuth)
    var currentUser: FirebaseAuth.User? { Auth.auth().currentUser }
    private var authListener: AuthStateDidChangeListenerHandle?
    #else
    var currentUser: AnyObject? { nil }
    #endif

    private init() {
        #if canImport(FirebaseAuth)
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                self?.userId = user?.uid
                self?.displayName = user?.displayName
            }
        }
        #endif
    }

    // MARK: - Email / Password
    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        #if canImport(FirebaseAuth)
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
        #else
        // Offline mode: auto-authenticate
        self.isAuthenticated = true
        self.userId = UUID().uuidString
        self.displayName = displayName
        #endif
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        #if canImport(FirebaseAuth)
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = mapAuthError(error)
        }
        #else
        self.isAuthenticated = true
        self.userId = "offline-user"
        self.displayName = email.components(separatedBy: "@").first ?? "User"
        #endif
        isLoading = false
    }

    func signOut() {
        #if canImport(FirebaseAuth)
        try? Auth.auth().signOut()
        #else
        isAuthenticated = false
        userId = nil
        displayName = nil
        #endif
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        #if canImport(FirebaseAuth)
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = mapAuthError(error)
        }
        #endif
        isLoading = false
    }

    // MARK: - Sign in with Apple
    func handleAppleSignIn(authorization: ASAuthorization, nonce: String) async {
        isLoading = true
        errorMessage = nil
        #if canImport(FirebaseAuth)
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
        #else
        self.isAuthenticated = true
        self.userId = "apple-user"
        self.displayName = "Apple User"
        #endif
        isLoading = false
    }

    #if canImport(FirebaseAuth)
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
    #endif
}
