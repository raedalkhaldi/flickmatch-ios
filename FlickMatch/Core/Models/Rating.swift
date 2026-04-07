import Foundation

struct Rating: Identifiable, Codable {
    let id: String
    let userId: String
    let contentId: Int
    let contentType: ContentItemType
    var score: Int?          // nil = "Haven't seen it"
    let createdAt: Date
    var updatedAt: Date

    var hasNotSeen: Bool { score == nil }
}

// Local rating state during onboarding (before saving to Firestore)
struct PendingRating: Identifiable {
    let id: Int              // contentId
    let contentType: ContentItemType
    var score: Int?          // nil = Haven't seen
}
