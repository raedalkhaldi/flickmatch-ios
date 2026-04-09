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

    private init() {
        #if canImport(FirebaseAuth)
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                self?.userId = user?.uid
                self?.displayName = user?.displayName
            }
        }
        #endif
    }

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true; errorMessage = nil
        #if canImport(FirebaseAuth)
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let req = result.user.createProfileChangeRequest()
            req.displayName = displayName
            try await req.commitChanges()
            await FirestoreService.shared.createUserProfile(uid: result.user.uid, displayName: displayName, email: email)
        } catch {
            let nsError = error as NSError
            if nsError.domain == "FIRAuthErrorDomain" {
                switch nsError.code {
                case 17999: errorMessage = "خطأ في الإعدادات — تأكد من تفعيل تسجيل الدخول بالبريد"
                case 17007: errorMessage = "البريد مستخدم بحساب آخر"
                case 17008: errorMessage = "البريد الإلكتروني غير صحيح"
                case 17026: errorMessage = "كلمة المرور لازم تكون ٦ أحرف أو أكثر"
                default: errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
        #else
        isAuthenticated = true; userId = UUID().uuidString; self.displayName = displayName
        #endif
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true; errorMessage = nil
        #if canImport(FirebaseAuth)
        do { try await Auth.auth().signIn(withEmail: email, password: password) }
        catch {
            let nsError = error as NSError
            if nsError.domain == "FIRAuthErrorDomain" {
                switch nsError.code {
                case 17999: errorMessage = "خطأ في الإعدادات — تأكد من تفعيل تسجيل الدخول بالبريد"
                case 17008: errorMessage = "البريد الإلكتروني غير صحيح"
                case 17009: errorMessage = "كلمة المرور غير صحيحة"
                case 17011: errorMessage = "لا يوجد حساب بهذا البريد"
                case 17010: errorMessage = "تم تعطيل الحساب"
                default: errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
        #else
        isAuthenticated = true; userId = "offline"; self.displayName = email.components(separatedBy: "@").first
        #endif
        isLoading = false
    }

    func signOut() {
        #if canImport(FirebaseAuth)
        try? Auth.auth().signOut()
        #else
        isAuthenticated = false; userId = nil; displayName = nil
        #endif
    }

    func handleAppleSignIn(authorization: ASAuthorization, nonce: String) async {
        isLoading = true; errorMessage = nil
        #if canImport(FirebaseAuth)
        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
              let idToken = cred.identityToken,
              let tokenStr = String(data: idToken, encoding: .utf8)
        else { errorMessage = "فشل Apple"; isLoading = false; return }
        let fbCred = OAuthProvider.appleCredential(withIDToken: tokenStr, rawNonce: nonce, fullName: cred.fullName)
        do {
            let result = try await Auth.auth().signIn(with: fbCred)
            let dn = [cred.fullName?.givenName, cred.fullName?.familyName].compactMap{$0}.joined(separator: " ")
            if !dn.isEmpty { let r = result.user.createProfileChangeRequest(); r.displayName = dn; try? await r.commitChanges() }
            await FirestoreService.shared.createUserProfileIfNeeded(uid: result.user.uid, displayName: dn.isEmpty ? "مستخدم" : dn, email: result.user.email ?? "")
        } catch { errorMessage = error.localizedDescription }
        #else
        isAuthenticated = true; userId = "apple"; displayName = "Apple User"
        #endif
        isLoading = false
    }
}
