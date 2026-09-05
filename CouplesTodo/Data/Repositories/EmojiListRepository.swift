import Foundation
import SwiftData

enum EmojiListRepositoryError: LocalizedError {
    case invalidEmoji
    case invalidTitle
    case listNotFound

    var errorDescription: String? {
        switch self {
        case .invalidEmoji:
            "Choose a single emoji."
        case .invalidTitle:
            "Give the list a name."
        case .listNotFound:
            "The list could not be found."
        }
    }
}

@MainActor
protocol EmojiListRepository {
    func fetchAll(coupleID: UUID) throws -> [EmojiList]
    func create(emoji: String, title: String, coupleID: UUID, now: Date) throws -> EmojiList
    func remove(id: UUID) throws
}

@MainActor
final class SwiftDataEmojiListRepository: EmojiListRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(coupleID: UUID) throws -> [EmojiList] {
        let descriptor = FetchDescriptor<StoredEmojiList>(
            predicate: #Predicate { $0.coupleID == coupleID }
        )
        return try context.fetch(descriptor)
            .map(\.domainValue)
            .sorted { $0.createdAt < $1.createdAt }
    }

    func create(
        emoji: String,
        title: String,
        coupleID: UUID,
        now: Date = .now
    ) throws -> EmojiList {
        let emoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard EmojiList.isValidEmoji(emoji) else { throw EmojiListRepositoryError.invalidEmoji }
        guard !title.isEmpty else { throw EmojiListRepositoryError.invalidTitle }

        let list = EmojiList(
            id: UUID(),
            coupleID: coupleID,
            emoji: emoji,
            title: title,
            createdAt: now
        )
        context.insert(
            StoredEmojiList(
                id: list.id,
                coupleID: list.coupleID,
                emoji: list.emoji,
                title: list.title,
                createdAt: list.createdAt
            )
        )
        try saveChanges()
        return list
    }

    func remove(id: UUID) throws {
        var listDescriptor = FetchDescriptor<StoredEmojiList>(
            predicate: #Predicate { $0.id == id }
        )
        listDescriptor.fetchLimit = 1
        guard let list = try context.fetch(listDescriptor).first else {
            throw EmojiListRepositoryError.listNotFound
        }

        let taskDescriptor = FetchDescriptor<StoredTask>(
            predicate: #Predicate { $0.listID == id }
        )
        try context.fetch(taskDescriptor).forEach { $0.listID = nil }
        context.delete(list)
        try saveChanges()
    }

    private func saveChanges() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
