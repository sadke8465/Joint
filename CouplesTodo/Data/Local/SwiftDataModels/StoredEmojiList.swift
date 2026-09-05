import Foundation
import SwiftData

@Model
final class StoredEmojiList {
    @Attribute(.unique) var id: UUID
    var coupleID: UUID
    var emoji: String
    var title: String
    var createdAt: Date

    init(id: UUID, coupleID: UUID, emoji: String, title: String, createdAt: Date) {
        self.id = id
        self.coupleID = coupleID
        self.emoji = emoji
        self.title = title
        self.createdAt = createdAt
    }

    var domainValue: EmojiList {
        EmojiList(
            id: id,
            coupleID: coupleID,
            emoji: emoji,
            title: title,
            createdAt: createdAt
        )
    }
}
