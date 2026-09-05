import Foundation

struct LocalIdentity: Equatable, Sendable {
    let coupleID: UUID
    let currentUserID: UUID
    let partnerUserID: UUID
}

enum PrototypeIdentity {
    static let shared = LocalIdentity(
        coupleID: UUID(uuidString: "B2AA9440-1F4A-47BB-A885-1C13E66A9A70")!,
        currentUserID: UUID(uuidString: "7A59A42C-534E-456E-9294-B86D85005D93")!,
        partnerUserID: UUID(uuidString: "FC65BD10-2F89-4C7B-9048-7F463CF11D98")!
    )
}
