import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

// MARK: - Firestore Data Models
struct FirestoreRating {
    let userId: String
    let contentId: Int
    let contentType: String
    let score: Int
    let title: String
    let posterPath: String
    let year: String
}

struct FirestoreUser {
    let uid: String
    let displayName: String
    let handle: String
    let tasteBadge: String
    let moviesRatedCount: Int
    let seriesRatedCount: Int
    let followersCount: Int
    let followingCount: Int
}

@MainActor
final class FirestoreService: ObservableObject {
    static let shared = FirestoreService()
    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    #endif
    private init() {}

    // MARK: - User Profile
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

    func fetchUserProfile(uid: String) async -> FirestoreUser? {
        #if canImport(FirebaseFirestore)
        guard let doc = try? await db.collection("users").document(uid).getDocument(),
              let data = doc.data() else { return nil }
        return FirestoreUser(
            uid: uid,
            displayName: data["displayName"] as? String ?? "",
            handle: data["handle"] as? String ?? "",
            tasteBadge: data["tasteBadge"] as? String ?? "",
            moviesRatedCount: data["moviesRatedCount"] as? Int ?? 0,
            seriesRatedCount: data["seriesRatedCount"] as? Int ?? 0,
            followersCount: data["followersCount"] as? Int ?? 0,
            followingCount: data["followingCount"] as? Int ?? 0
        )
        #else
        return nil
        #endif
    }

    func updateTasteBadge(userId: String, badge: String) async {
        #if canImport(FirebaseFirestore)
        try? await db.collection("users").document(userId).updateData(["tasteBadge": badge])
        #endif
    }

    /// Check if a handle is already taken by another user.
    func isHandleTaken(_ handle: String, excludingUid uid: String) async -> Bool {
        #if canImport(FirebaseFirestore)
        do {
            let snap = try await db.collection("users")
                .whereField("handle", isEqualTo: handle)
                .limit(to: 1)
                .getDocuments()
            return snap.documents.contains { $0.documentID != uid }
        } catch { return false }
        #else
        return false
        #endif
    }

    /// Update the user's handle (username).
    func updateHandle(userId: String, handle: String) async {
        #if canImport(FirebaseFirestore)
        try? await db.collection("users").document(userId).updateData(["handle": handle])
        #endif
    }

    // MARK: - Ratings
    func saveRating(userId: String, contentId: Int, contentType: String, score: Int, title: String, posterPath: String, year: String) async {
        #if canImport(FirebaseFirestore)
        let data: [String: Any] = ["userId": userId, "contentId": contentId, "contentType": contentType, "score": score, "title": title, "posterPath": posterPath, "year": year, "updatedAt": FieldValue.serverTimestamp()]
        try? await db.collection("ratings").document("\(userId)_\(contentType)_\(contentId)").setData(data, merge: true)
        // Update rated count
        let countField = contentType == "movie" ? "moviesRatedCount" : "seriesRatedCount"
        try? await db.collection("users").document(userId).updateData([countField: FieldValue.increment(Int64(1))])
        #endif
    }

    func fetchUserRatings(userId: String, contentType: String? = nil) async -> [FirestoreRating] {
        #if canImport(FirebaseFirestore)
        do {
            var query: Query = db.collection("ratings").whereField("userId", isEqualTo: userId)
            if let ct = contentType {
                query = query.whereField("contentType", isEqualTo: ct)
            }
            let snap = try await query.getDocuments()
            return snap.documents.compactMap { doc -> FirestoreRating? in
                let d = doc.data()
                guard let cId = d["contentId"] as? Int,
                      let ct = d["contentType"] as? String,
                      let sc = d["score"] as? Int else { return nil }
                return FirestoreRating(
                    userId: d["userId"] as? String ?? "",
                    contentId: cId, contentType: ct, score: sc,
                    title: d["title"] as? String ?? "",
                    posterPath: d["posterPath"] as? String ?? "",
                    year: d["year"] as? String ?? ""
                )
            }
        } catch { return [] }
        #else
        return []
        #endif
    }

    // Fetch ratings from ALL users for a given content type (for recommendation engine)
    func fetchAllRatings(contentType: String) async -> [FirestoreRating] {
        #if canImport(FirebaseFirestore)
        do {
            let snap = try await db.collection("ratings")
                .whereField("contentType", isEqualTo: contentType)
                .whereField("score", isGreaterThan: 0)
                .getDocuments()
            return snap.documents.compactMap { doc -> FirestoreRating? in
                let d = doc.data()
                guard let cId = d["contentId"] as? Int,
                      let ct = d["contentType"] as? String,
                      let sc = d["score"] as? Int else { return nil }
                return FirestoreRating(
                    userId: d["userId"] as? String ?? "",
                    contentId: cId, contentType: ct, score: sc,
                    title: d["title"] as? String ?? "",
                    posterPath: d["posterPath"] as? String ?? "",
                    year: d["year"] as? String ?? ""
                )
            }
        } catch { return [] }
        #else
        return []
        #endif
    }

    // MARK: - Discover (users list)
    func fetchDiscoverUsers(excludeUserId: String) async -> [(user: FirestoreUser, ratings: [FirestoreRating])] {
        #if canImport(FirebaseFirestore)
        do {
            let snap = try await db.collection("users").limit(to: 20).getDocuments()
            var results: [(user: FirestoreUser, ratings: [FirestoreRating])] = []
            for doc in snap.documents {
                let uid = doc.documentID
                if uid == excludeUserId { continue }
                let data = doc.data()
                let user = FirestoreUser(
                    uid: uid,
                    displayName: data["displayName"] as? String ?? "مستخدم",
                    handle: data["handle"] as? String ?? "",
                    tasteBadge: data["tasteBadge"] as? String ?? "",
                    moviesRatedCount: data["moviesRatedCount"] as? Int ?? 0,
                    seriesRatedCount: data["seriesRatedCount"] as? Int ?? 0,
                    followersCount: data["followersCount"] as? Int ?? 0,
                    followingCount: data["followingCount"] as? Int ?? 0
                )
                let ratings = await fetchUserRatings(userId: uid)
                results.append((user: user, ratings: ratings))
            }
            return results
        } catch { return [] }
        #else
        return []
        #endif
    }

    // MARK: - Follow
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

    func isFollowing(followerId: String, followingId: String) async -> Bool {
        #if canImport(FirebaseFirestore)
        let doc = try? await db.collection("follows").document("\(followerId)_\(followingId)").getDocument()
        return doc?.exists == true
        #else
        return false
        #endif
    }

    func fetchFollowedIds(userId: String) async -> Set<String> {
        #if canImport(FirebaseFirestore)
        do {
            let snap = try await db.collection("follows")
                .whereField("followerId", isEqualTo: userId)
                .getDocuments()
            return Set(snap.documents.compactMap { $0.data()["followingId"] as? String })
        } catch { return [] }
        #else
        return []
        #endif
    }

    // MARK: - Account Deletion (Apple requirement)
    /// Permanently deletes every document associated with a user:
    /// profile, ratings, follows (in both directions). Safe to call even
    /// if some queries fail — best-effort deletion.
    func deleteAllUserData(uid: String) async {
        #if canImport(FirebaseFirestore)
        // 1. Ratings (id pattern: "\(uid)_\(type)_\(contentId)")
        if let snap = try? await db.collection("ratings")
            .whereField("userId", isEqualTo: uid)
            .getDocuments() {
            for doc in snap.documents {
                try? await doc.reference.delete()
            }
        }

        // 2. Follows where the user is the follower
        if let snap = try? await db.collection("follows")
            .whereField("followerId", isEqualTo: uid)
            .getDocuments() {
            for doc in snap.documents {
                try? await doc.reference.delete()
            }
        }

        // 3. Follows where the user is being followed
        if let snap = try? await db.collection("follows")
            .whereField("followingId", isEqualTo: uid)
            .getDocuments() {
            for doc in snap.documents {
                try? await doc.reference.delete()
            }
        }

        // 4. User profile document
        try? await db.collection("users").document(uid).delete()
        #endif
    }
}
