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

    func createUserProfile(uid: String, displayName: String, email: String) async {
        #if canImport(FirebaseFirestore)
        let data: [String: Any] = [
            "displayName": displayName, "handle": "@\(displayName.lowercased().replacingOccurrences(of: " ", with: ""))\(Int.random(in: 100...999))",
            "email": email, "avatarURL": "", "tasteBadge": "",
            "followersCount": 0, "followingCount": 0, "moviesRatedCount": 0, "seriesRatedCount": 0,
            "createdAt": FieldValue.serverTimestamp()
        ]
        try? await db.collection("users").document(uid).setData(data)
        #endif
    }

    func createUserProfileIfNeeded(uid: String, displayName: String, email: String) async {
        #if canImport(FirebaseFirestore)
        let doc = try? await db.collection("users").document(uid).getDocument()
        if doc?.exists != true { await createUserProfile(uid: uid, displayName: displayName, email: email) }
        #endif
    }

    func saveRating(userId: String, contentId: Int, contentType: String, score: Int, title: String, posterPath: String, year: String) async {
        #if canImport(FirebaseFirestore)
        let data: [String: Any] = ["userId": userId, "contentId": contentId, "contentType": contentType, "score": score, "title": title, "posterPath": posterPath, "year": year, "updatedAt": FieldValue.serverTimestamp()]
        try? await db.collection("ratings").document("\(userId)_\(contentType)_\(contentId)").setData(data, merge: true)
        #endif
    }

    func follow(followerId: String, followingId: String) async {
        #if canImport(FirebaseFirestore)
        try? await db.collection("follows").document("\(followerId)_\(followingId)").setData(["followerId": followerId, "followingId": followingId, "createdAt": FieldValue.serverTimestamp()])
        try? await db.collection("users").document(followerId).updateData(["followingCount": FieldValue.increment(Int64(1))])
        try? await db.collection("users").document(followingId).updateData(["followersCount": FieldValue.increment(Int64(1))])
        #endif
    }

    func unfollow(followerId: String, followingId: String) async {
        #if canImport(FirebaseFirestore)
        try? await db.collection("follows").document("\(followerId)_\(followingId)").delete()
        try? await db.collection("users").document(followerId).updateData(["followingCount": FieldValue.increment(Int64(-1))])
        try? await db.collection("users").document(followingId).updateData(["followersCount": FieldValue.increment(Int64(-1))])
        #endif
    }
}
