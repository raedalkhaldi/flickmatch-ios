import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

enum FirebaseConfig {
    static func configure() {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #else
        print("[FlickMatch] Firebase SDK not linked — running in offline mode")
        #endif
    }
}
