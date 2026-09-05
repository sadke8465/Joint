import Foundation

struct EmojiList: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let coupleID: UUID
    var emoji: String
    var title: String
    let createdAt: Date

    static func isValidEmoji(_ value: String) -> Bool {
        let candidate = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard candidate.count == 1, let character = candidate.first else { return false }

        return character.unicodeScalars.contains { scalar in
            scalar.properties.isEmojiPresentation
                || (scalar.properties.isEmoji && scalar.value > 0x238C)
        }
    }
}
