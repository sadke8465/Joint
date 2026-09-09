import SwiftUI

enum MemberStyle: String, CaseIterable, Identifiable, Hashable {
    case me
    case partner
    case together

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .me:
            AppColors.turquoise
        case .partner:
            AppColors.coral
        case .together:
            AppColors.violet
        }
    }

    var labelColor: Color {
        switch self {
        case .me:
            Color(red: 0.000, green: 0.420, blue: 0.380)
        case .partner:
            Color(red: 0.710, green: 0.210, blue: 0.120)
        case .together:
            Color(red: 0.270, green: 0.240, blue: 0.720)
        }
    }

    var selectedForeground: Color {
        switch self {
        case .me, .partner:
            AppColors.primaryText
        case .together:
            .white
        }
    }

    var iconName: String {
        switch self {
        case .me: "person.fill"
        case .partner: "person.fill"
        case .together: "person.2.fill"
        }
    }

    var labelKey: LocalizedStringKey {
        switch self {
        case .me: "assignee.me"
        case .partner: "assignee.partner"
        case .together: "assignee.together"
        }
    }

    var composerLabelKey: LocalizedStringKey {
        switch self {
        case .me: "composer.assignee.me"
        case .partner: "composer.assignee.partner"
        case .together: "composer.assignee.together"
        }
    }

    init(task: TaskItem, identity: LocalIdentity) {
        switch task.assigneeKind {
        case .together:
            self = .together
        case .person where task.assigneeUserID == identity.currentUserID:
            self = .me
        case .person:
            self = .partner
        }
    }

    func assignment(identity: LocalIdentity) -> (kind: AssigneeKind, userID: UUID?) {
        switch self {
        case .me:
            (.person, identity.currentUserID)
        case .partner:
            (.person, identity.partnerUserID)
        case .together:
            (.together, nil)
        }
    }
}
