import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class FirestoreService: ObservableObject {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - User Profiles
    func createUserProfile(uid: String, displayName: String, email: String) async {
        let handle = "@\(displayName.lowercased().replacingOccurrences(of: " ", with: ""))\(Int.random(in: 100...999))"
        let data: [String: Any] = [
            "displayName": displayName,
            "handle": handle,
            "email": email,
            "avatarURL": "",
            "tasteBadge": "",
            "followersCount": 0,
            "followingCount": 0,
            "moviesRatedCount": 0,
            "seriesRatedCount": 0,
            "createdAt": FieldValue.serverTimestamp()
        ]
        try? await db.collection("users").document(uid).setData(data)
    }

    func createUserProfileIfNeeded(uid: String, displayName: String, email: String) async {
        let doc = try? await db.collection("users").document(uid).getDocument()
        if doc?.exists != true {
            await createUserProfile(uid: uid, displayName: displayName, email: email)
        }
    }

    func fetchUserProfile(uid: String) async -> [String: Any]? {
        try? await db.collection("users").document(uid).getDocument().data()
    }

    func updateUserProfile(uid: String, fields: [String: Any]) async {
        try? await db.collection("users").document(uid).updateData(fields)
    }

    // MARK: - Ratings
    func saveRating(userId: String, contentId: Int, contentType: String,
                    score: Int, title: String, posterPath: String, year: String) async {
        let docId = "\(userId)_\(contentType)_\(contentId)"
        let data: [String: Any] = [
            "userId": userId,
            "contentId": contentId,
            "contentType": contentType,
            "score": score,
            "title": title,
            "posterPath": posterPath,
            "year": year,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try? await db.collection("ratings").document(docId).setData(data, merge: true)
    }

    func fetchUserRatings(userId: String, contentType: String) async -> [[String: Any]] {
        let snapshot = try? await db.collection("ratings")
            .whereField("userId", isEqualTo: userId)
            .whereField("contentType", isEqualTo: contentType)
            .order(by: "score", descending: true)
            .getDocuments()
        return snapshot?.documents.map { $0.data() } ?? []
    }

    func fetchAllRatings(contentType: String) async -> [[String: Any]] {
        let snapshot = try? await db.collection("ratings")
            .whereField("contentType", isEqualTo: contentType)
            .whereField("score", isGreaterThan: 0)
            .getDocuments()
        return snapshot?.documents.map { $0.data() } ?? []
    }

    // MARK: - Follows
    func follow(followerId: String, followingId: String) async {
        let docId = "\(followerId)_\(followingId)"
        let data: [String: Any] = [
            "followerId": followerId,
            "followingId": followingId,
            "createdAt": FieldValue.serverTimestamp()
        ]
        try? await db.collection("follows").document(docId).setData(data)
        // Update counts
        try? await db.collection("users").document(followerId).updateData([
            "followingCount": FieldValue.increment(Int64(1))
        ])
        try? await db.collection("users").document(followingId).updateData([
            "followersCount": FieldValue.increment(Int64(1))
        ])
    }

    func unfollow(followerId: String, followingId: String) async {
        let docId = "\(followerId)_\(followingId)"
        try? await db.collection("follows").document(docId).delete()
        try? await db.collection("users").document(followerId).updateData([
            "followingCount": FieldValue.increment(Int64(-1))
        ])
        try? await db.collection("users").document(followingId).updateData([
            "followersCount": FieldValue.increment(Int64(-1))
        ])
    }

    func isFollowing(followerId: String, followingId: String) async -> Bool {
        let docId = "\(followerId)_\(followingId)"
        let doc = try? await db.collection("follows").document(docId).getDocument()
        return doc?.exists == true
    }

    func fetchFollowing(userId: String) async -> [String] {
        let snapshot = try? await db.collection("follows")
            .whereField("followerId", isEqualTo: userId)
            .getDocuments()
        return snapshot?.documents.compactMap { $0.data()["followingId"] as? String } ?? []
    }
}
