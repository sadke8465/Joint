import SwiftUI

enum MemberStyle: String, CaseIterable, Identifiable {
    case me
    case partner
    case together

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .me:
            Color(red: 0.255, green: 0.520, blue: 0.500)
        case .partner:
            Color(red: 0.790, green: 0.390, blue: 0.315)
        case .together:
            AppColors.accent
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
}
