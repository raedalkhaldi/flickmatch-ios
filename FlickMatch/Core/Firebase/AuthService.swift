import Foundation
import AuthenticationServices

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userId: String?
    @Published var displayName: String?
    @Published var handle: String?

    private let userIdKey = "flickmatch_apple_user_id"
    private let displayNameKey = "flickmatch_apple_display_name"
    private let handleKey = "flickmatch_user_handle"

    private init() {
        // Restore session from Keychain/UserDefaults
        if let savedId = UserDefaults.standard.string(forKey: userIdKey) {
            userId = savedId
            displayName = UserDefaults.standard.string(forKey: displayNameKey)
            handle = UserDefaults.standard.string(forKey: handleKey)
            isAuthenticated = true
        }
    }

    func handleAppleSignIn(authorization: ASAuthorization) async {
        isLoading = true; errorMessage = nil

        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "فشل تسجيل الدخول"
            isLoading = false
            return
        }

        let uid = cred.user
        let name = [cred.fullName?.givenName, cred.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        let dn = name.isEmpty ? (displayName ?? "مستخدم") : name

        // Save locally
        UserDefaults.standard.set(uid, forKey: userIdKey)
        UserDefaults.standard.set(dn, forKey: displayNameKey)

        userId = uid
        displayName = dn
        isAuthenticated = true

        // Create Firestore profile
        await FirestoreService.shared.createUserProfileIfNeeded(
            uid: uid,
            displayName: dn,
            email: cred.email ?? ""
        )

        // Load handle from Firestore
        if let profile = await FirestoreService.shared.fetchUserProfile(uid: uid) {
            handle = profile.handle
            UserDefaults.standard.set(profile.handle, forKey: handleKey)
        }

        isLoading = false
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: displayNameKey)
        UserDefaults.standard.removeObject(forKey: handleKey)
        userId = nil
        displayName = nil
        handle = nil
        isAuthenticated = false
    }

    /// Permanently delete the account: wipe Firestore data, local ratings/watchlist,
    /// then sign out. Required by App Store Review Guideline 5.1.1(v).
    func deleteAccount() async {
        isLoading = true
        defer { isLoading = false }

        if let uid = userId {
            await FirestoreService.shared.deleteAllUserData(uid: uid)
        }

        // Local caches
        RatingStore.shared.deleteAll()
        WatchlistStore.shared.deleteAll()

        // Sign out last so UI transitions back to AuthView
        signOut()
    }

    /// Update the user's @handle.
    func updateHandle(_ newHandle: String) async {
        guard let uid = userId else { return }
        let formatted = newHandle.hasPrefix("@") ? newHandle : "@\(newHandle)"
        await FirestoreService.shared.updateHandle(userId: uid, handle: formatted)
        handle = formatted
        UserDefaults.standard.set(formatted, forKey: handleKey)
    }

    /// Check if Apple ID credential is still valid
    func validateSession() {
        guard let uid = userId else { return }
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: uid) { state, _ in
            Task { @MainActor in
                if state == .revoked || state == .notFound {
                    self.signOut()
                }
            }
        }
    }
}
