import Foundation

struct TaskSentenceFormatter {
    let locale: Locale

    func sentence(for tasks: [TaskItem], assignee: MemberStyle) -> String {
        guard !tasks.isEmpty else { return "" }

        let listFormatter = ListFormatter()
        listFormatter.locale = locale
        let titles = tasks.map(\.title)
        let joinedTitles = listFormatter.string(from: titles) ?? titles.joined(separator: ", ")

        let format: String = switch assignee {
        case .me:
            String(localized: "week.summary.mine_format", locale: locale)
        case .partner:
            String(localized: "week.summary.partner_format", locale: locale)
        case .together:
            String(localized: "week.summary.together_format", locale: locale)
        }

        let sentence = String.localizedStringWithFormat(format, joinedTitles)
        guard let lastCharacter = sentence.last,
              !Self.terminalPunctuation.contains(lastCharacter) else {
            return sentence
        }
        return sentence + "."
    }

    private static let terminalPunctuation: Set<Character> = [".", "!", "?", "…"]
}
