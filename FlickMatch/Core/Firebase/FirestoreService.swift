import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

@MainActor
final class FirestoreService: ObservableObject {
    static let shared = FirestoreService()

    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    #endif

    private init() {}

    // MARK: - User Profiles
    func createUserProfile(uid: String, displayName: String, email: String) async {
        #if canImport(FirebaseFirestore)
        let handle = "@\(displayName.lowercased().replacingOccurrences(of: " ", with: ""))\(Int.random(in: 100...999))"
        let data: [String: Any] = [
            "displayName": displayName, "handle": handle, "email": email,
            "avatarURL": "", "tasteBadge": "",
            "followersCount": 0, "followingCount": 0,
            "moviesRatedCount": 0, "seriesRatedCount": 0,
            "createdAt": FieldValue.serverTimestamp()
        ]
        try? await db.collection("users").document(uid).setData(data)
        #endif
    }

    func createUserProfileIfNeeded(uid: String, displayName: String, email: String) async {
        #if canImport(FirebaseFirestore)
        let doc = try? await db.collection("users").document(uid).getDocument()
        if doc?.exists != true {
            await createUserProfile(uid: uid, displayName: displayName, email: email)
        }
        #endif
    }

    func fetchUserProfile(uid: String) async -> [String: Any]? {
        #if canImport(FirebaseFirestore)
        return try? await db.collection("users").document(uid).getDocument().data()
        #else
        return nil
        #endif
    }

    func updateUserProfile(uid: String, fields: [String: Any]) async {
        #if canImport(FirebaseFirestore)
        try? await db.collection("users").document(uid).updateData(fields)
        #endif
    }

    // MARK: - Ratings
    func saveRating(userId: String, contentId: Int, contentType: String,
                    score: Int, title: String, posterPath: String, year: String) async {
        #if canImport(FirebaseFirestore)
        let docId = "\(userId)_\(contentType)_\(contentId)"
        let data: [String: Any] = [
            "userId": userId, "contentId": contentId, "contentType": contentType,
            "score": score, "title": title, "posterPath": posterPath, "year": year,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try? await db.collection("ratings").document(docId).setData(data, merge: true)
        #endif
    }

    func fetchUserRatings(userId: String, contentType: String) async -> [[String: Any]] {
        #if canImport(FirebaseFirestore)
        let snapshot = try? await db.collection("ratings")
            .whereField("userId", isEqualTo: userId)
            .whereField("contentType", isEqualTo: contentType)
            .order(by: "score", descending: true)
            .getDocuments()
        return snapshot?.documents.map { $0.data() } ?? []
        #else
        return []
        #endif
    }

    func fetchAllRatings(contentType: String) async -> [[String: Any]] {
        #if canImport(FirebaseFirestore)
        let snapshot = try? await db.collection("ratings")
            .whereField("contentType", isEqualTo: contentType)
            .whereField("score", isGreaterThan: 0)
            .getDocuments()
        return snapshot?.documents.map { $0.data() } ?? []
        #else
        return []
        #endif
    }

    // MARK: - Follows
    func follow(followerId: String, followingId: String) async {
        #if canImport(FirebaseFirestore)
        let docId = "\(followerId)_\(followingId)"
        let data: [String: Any] = [
            "followerId": followerId, "followingId": followingId,
            "createdAt": FieldValue.serverTimestamp()
        ]
        try? await db.collection("follows").document(docId).setData(data)
        try? await db.collection("users").document(followerId).updateData(["followingCount": FieldValue.increment(Int64(1))])
        try? await db.collection("users").document(followingId).updateData(["followersCount": FieldValue.increment(Int64(1))])
        #endif
    }

    func unfollow(followerId: String, followingId: String) async {
        #if canImport(FirebaseFirestore)
        let docId = "\(followerId)_\(followingId)"
        try? await db.collection("follows").document(docId).delete()
        try? await db.collection("users").document(followerId).updateData(["followingCount": FieldValue.increment(Int64(-1))])
        try? await db.collection("users").document(followingId).updateData(["followersCount": FieldValue.increment(Int64(-1))])
        #endif
    }

    func isFollowing(followerId: String, followingId: String) async -> Bool {
        #if canImport(FirebaseFirestore)
        let doc = try? await db.collection("follows").document("\(followerId)_\(followingId)").getDocument()
        return doc?.exists == true
        #else
        return false
        #endif
    }
}
