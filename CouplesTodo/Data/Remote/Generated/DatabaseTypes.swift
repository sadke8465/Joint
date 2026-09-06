import Foundation
import Supabase

internal enum PublicSchema {
  internal struct CoupleInvitesSelect: Codable, Hashable, Sendable {
    internal let acceptedAt: String?
    internal let acceptedBy: UUID?
    internal let coupleId: UUID
    internal let createdAt: String
    internal let createdBy: UUID
    internal let expiresAt: String
    internal let id: UUID
    internal let revokedAt: String?
    internal let shortCodeHash: String
    internal let tokenHash: String
    internal enum CodingKeys: String, CodingKey {
      case acceptedAt = "accepted_at"
      case acceptedBy = "accepted_by"
      case coupleId = "couple_id"
      case createdAt = "created_at"
      case createdBy = "created_by"
      case expiresAt = "expires_at"
      case id = "id"
      case revokedAt = "revoked_at"
      case shortCodeHash = "short_code_hash"
      case tokenHash = "token_hash"
    }
  }
  internal struct CoupleInvitesInsert: Codable, Hashable, Sendable {
    internal let acceptedAt: String?
    internal let acceptedBy: UUID?
    internal let coupleId: UUID
    internal let createdAt: String?
    internal let createdBy: UUID
    internal let expiresAt: String
    internal let id: UUID?
    internal let revokedAt: String?
    internal let shortCodeHash: String
    internal let tokenHash: String
    internal enum CodingKeys: String, CodingKey {
      case acceptedAt = "accepted_at"
      case acceptedBy = "accepted_by"
      case coupleId = "couple_id"
      case createdAt = "created_at"
      case createdBy = "created_by"
      case expiresAt = "expires_at"
      case id = "id"
      case revokedAt = "revoked_at"
      case shortCodeHash = "short_code_hash"
      case tokenHash = "token_hash"
    }
  }
  internal struct CoupleInvitesUpdate: Codable, Hashable, Sendable {
    internal let acceptedAt: String?
    internal let acceptedBy: UUID?
    internal let coupleId: UUID?
    internal let createdAt: String?
    internal let createdBy: UUID?
    internal let expiresAt: String?
    internal let id: UUID?
    internal let revokedAt: String?
    internal let shortCodeHash: String?
    internal let tokenHash: String?
    internal enum CodingKeys: String, CodingKey {
      case acceptedAt = "accepted_at"
      case acceptedBy = "accepted_by"
      case coupleId = "couple_id"
      case createdAt = "created_at"
      case createdBy = "created_by"
      case expiresAt = "expires_at"
      case id = "id"
      case revokedAt = "revoked_at"
      case shortCodeHash = "short_code_hash"
      case tokenHash = "token_hash"
    }
  }
  internal struct CoupleMembersSelect: Codable, Hashable, Sendable {
    internal let coupleId: UUID
    internal let joinedAt: String
    internal let memberPosition: Int16
    internal let userId: UUID
    internal enum CodingKeys: String, CodingKey {
      case coupleId = "couple_id"
      case joinedAt = "joined_at"
      case memberPosition = "member_position"
      case userId = "user_id"
    }
  }
  internal struct CoupleMembersInsert: Codable, Hashable, Sendable {
    internal let coupleId: UUID
    internal let joinedAt: String?
    internal let memberPosition: Int16
    internal let userId: UUID
    internal enum CodingKeys: String, CodingKey {
      case coupleId = "couple_id"
      case joinedAt = "joined_at"
      case memberPosition = "member_position"
      case userId = "user_id"
    }
  }
  internal struct CoupleMembersUpdate: Codable, Hashable, Sendable {
    internal let coupleId: UUID?
    internal let joinedAt: String?
    internal let memberPosition: Int16?
    internal let userId: UUID?
    internal enum CodingKeys: String, CodingKey {
      case coupleId = "couple_id"
      case joinedAt = "joined_at"
      case memberPosition = "member_position"
      case userId = "user_id"
    }
  }
  internal struct CouplesSelect: Codable, Hashable, Sendable {
    internal let createdAt: String
    internal let createdBy: UUID
    internal let dissolvedAt: String?
    internal let id: UUID
    internal let updatedAt: String
    internal enum CodingKeys: String, CodingKey {
      case createdAt = "created_at"
      case createdBy = "created_by"
      case dissolvedAt = "dissolved_at"
      case id = "id"
      case updatedAt = "updated_at"
    }
  }
  internal struct CouplesInsert: Codable, Hashable, Sendable {
    internal let createdAt: String?
    internal let createdBy: UUID
    internal let dissolvedAt: String?
    internal let id: UUID?
    internal let updatedAt: String?
    internal enum CodingKeys: String, CodingKey {
      case createdAt = "created_at"
      case createdBy = "created_by"
      case dissolvedAt = "dissolved_at"
      case id = "id"
      case updatedAt = "updated_at"
    }
  }
  internal struct CouplesUpdate: Codable, Hashable, Sendable {
    internal let createdAt: String?
    internal let createdBy: UUID?
    internal let dissolvedAt: String?
    internal let id: UUID?
    internal let updatedAt: String?
    internal enum CodingKeys: String, CodingKey {
      case createdAt = "created_at"
      case createdBy = "created_by"
      case dissolvedAt = "dissolved_at"
      case id = "id"
      case updatedAt = "updated_at"
    }
  }
  internal struct DeviceTokensSelect: Codable, Hashable, Sendable {
    internal let appVersion: String?
    internal let createdAt: String
    internal let environment: String
    internal let id: UUID
    internal let lastSeenAt: String
    internal let platform: String
    internal let token: String
    internal let updatedAt: String
    internal let userId: UUID
    internal enum CodingKeys: String, CodingKey {
      case appVersion = "app_version"
      case createdAt = "created_at"
      case environment = "environment"
      case id = "id"
      case lastSeenAt = "last_seen_at"
      case platform = "platform"
      case token = "token"
      case updatedAt = "updated_at"
      case userId = "user_id"
    }
  }
  internal struct DeviceTokensInsert: Codable, Hashable, Sendable {
    internal let appVersion: String?
    internal let createdAt: String?
    internal let environment: String
    internal let id: UUID?
    internal let lastSeenAt: String?
    internal let platform: String?
    internal let token: String
    internal let updatedAt: String?
    internal let userId: UUID
    internal enum CodingKeys: String, CodingKey {
      case appVersion = "app_version"
      case createdAt = "created_at"
      case environment = "environment"
      case id = "id"
      case lastSeenAt = "last_seen_at"
      case platform = "platform"
      case token = "token"
      case updatedAt = "updated_at"
      case userId = "user_id"
    }
  }
  internal struct DeviceTokensUpdate: Codable, Hashable, Sendable {
    internal let appVersion: String?
    internal let createdAt: String?
    internal let environment: String?
    internal let id: UUID?
    internal let lastSeenAt: String?
    internal let platform: String?
    internal let token: String?
    internal let updatedAt: String?
    internal let userId: UUID?
    internal enum CodingKeys: String, CodingKey {
      case appVersion = "app_version"
      case createdAt = "created_at"
      case environment = "environment"
      case id = "id"
      case lastSeenAt = "last_seen_at"
      case platform = "platform"
      case token = "token"
      case updatedAt = "updated_at"
      case userId = "user_id"
    }
  }
  internal struct ListsSelect: Codable, Hashable, Sendable {
    internal let coupleId: UUID
    internal let createdAt: String
    internal let createdBy: UUID
    internal let deletedAt: String?
    internal let emoji: String
    internal let id: UUID
    internal let internalName: String?
    internal let sortOrder: Int32
    internal let updatedAt: String
    internal enum CodingKeys: String, CodingKey {
      case coupleId = "couple_id"
      case createdAt = "created_at"
      case createdBy = "created_by"
      case deletedAt = "deleted_at"
      case emoji = "emoji"
      case id = "id"
      case internalName = "internal_name"
      case sortOrder = "sort_order"
      case updatedAt = "updated_at"
    }
  }
  internal struct ListsInsert: Codable, Hashable, Sendable {
    internal let coupleId: UUID
    internal let createdAt: String?
    internal let createdBy: UUID
    internal let deletedAt: String?
    internal let emoji: String
    internal let id: UUID?
    internal let internalName: String?
    internal let sortOrder: Int32?
    internal let updatedAt: String?
    internal enum CodingKeys: String, CodingKey {
      case coupleId = "couple_id"
      case createdAt = "created_at"
      case createdBy = "created_by"
      case deletedAt = "deleted_at"
      case emoji = "emoji"
      case id = "id"
      case internalName = "internal_name"
      case sortOrder = "sort_order"
      case updatedAt = "updated_at"
    }
  }
  internal struct ListsUpdate: Codable, Hashable, Sendable {
    internal let coupleId: UUID?
    internal let createdAt: String?
    internal let createdBy: UUID?
    internal let deletedAt: String?
    internal let emoji: String?
    internal let id: UUID?
    internal let internalName: String?
    internal let sortOrder: Int32?
    internal let updatedAt: String?
    internal enum CodingKeys: String, CodingKey {
      case coupleId = "couple_id"
      case createdAt = "created_at"
      case createdBy = "created_by"
      case deletedAt = "deleted_at"
      case emoji = "emoji"
      case id = "id"
      case internalName = "internal_name"
      case sortOrder = "sort_order"
      case updatedAt = "updated_at"
    }
  }
  internal struct NotificationDeliveriesSelect: Codable, Hashable, Sendable {
    internal let coupleId: UUID
    internal let dedupeKey: String
    internal let id: UUID
    internal let kind: String
    internal let localDate: String
    internal let sentAt: String
    internal let slot: String
    internal let userId: UUID
    internal enum CodingKeys: String, CodingKey {
      case coupleId = "couple_id"
      case dedupeKey = "dedupe_key"
      case id = "id"
      case kind = "kind"
      case localDate = "local_date"
      case sentAt = "sent_at"
      case slot = "slot"
      case userId = "user_id"
    }
  }
  internal struct NotificationDeliveriesInsert: Codable, Hashable, Sendable {
    internal let coupleId: UUID
    internal let dedupeKey: String
    internal let id: UUID?
    internal let kind: String
    internal let localDate: String
    internal let sentAt: String?
    internal let slot: String
    internal let userId: UUID
    internal enum CodingKeys: String, CodingKey {
      case coupleId = "couple_id"
      case dedupeKey = "dedupe_key"
      case id = "id"
      case kind = "kind"
      case localDate = "local_date"
      case sentAt = "sent_at"
      case slot = "slot"
      case userId = "user_id"
    }
  }
  internal struct NotificationDeliveriesUpdate: Codable, Hashable, Sendable {
    internal let coupleId: UUID?
    internal let dedupeKey: String?
    internal let id: UUID?
    internal let kind: String?
    internal let localDate: String?
    internal let sentAt: String?
    internal let slot: String?
    internal let userId: UUID?
    internal enum CodingKeys: String, CodingKey {
      case coupleId = "couple_id"
      case dedupeKey = "dedupe_key"
      case id = "id"
      case kind = "kind"
      case localDate = "local_date"
      case sentAt = "sent_at"
      case slot = "slot"
      case userId = "user_id"
    }
  }
  internal struct NotificationPreferencesSelect: Codable, Hashable, Sendable {
    internal let badgeEnabled: Bool
    internal let eveningBeforeEnabled: Bool
    internal let eveningBeforeTime: String
    internal let eveningOfEnabled: Bool
    internal let eveningOfTime: String
    internal let morningOfEnabled: Bool
    internal let morningOfTime: String
    internal let notifyTaskAssigned: Bool
    internal let notifyTaskCompleted: Bool
    internal let notifyTaskDateChanged: Bool
    internal let notifyTaskReassigned: Bool
    internal let notifyTaskUncompleted: Bool
    internal let timezone: String
    internal let updatedAt: String
    internal let userId: UUID
    internal enum CodingKeys: String, CodingKey {
      case badgeEnabled = "badge_enabled"
      case eveningBeforeEnabled = "evening_before_enabled"
      case eveningBeforeTime = "evening_before_time"
      case eveningOfEnabled = "evening_of_enabled"
      case eveningOfTime = "evening_of_time"
      case morningOfEnabled = "morning_of_enabled"
      case morningOfTime = "morning_of_time"
      case notifyTaskAssigned = "notify_task_assigned"
      case notifyTaskCompleted = "notify_task_completed"
      case notifyTaskDateChanged = "notify_task_date_changed"
      case notifyTaskReassigned = "notify_task_reassigned"
      case notifyTaskUncompleted = "notify_task_uncompleted"
      case timezone = "timezone"
      case updatedAt = "updated_at"
      case userId = "user_id"
    }
  }
  internal struct NotificationPreferencesInsert: Codable, Hashable, Sendable {
    internal let badgeEnabled: Bool?
    internal let eveningBeforeEnabled: Bool?
    internal let eveningBeforeTime: String?
    internal let eveningOfEnabled: Bool?
    internal let eveningOfTime: String?
    internal let morningOfEnabled: Bool?
    internal let morningOfTime: String?
    internal let notifyTaskAssigned: Bool?
    internal let notifyTaskCompleted: Bool?
    internal let notifyTaskDateChanged: Bool?
    internal let notifyTaskReassigned: Bool?
    internal let notifyTaskUncompleted: Bool?
    internal let timezone: String?
    internal let updatedAt: String?
    internal let userId: UUID
    internal enum CodingKeys: String, CodingKey {
      case badgeEnabled = "badge_enabled"
      case eveningBeforeEnabled = "evening_before_enabled"
      case eveningBeforeTime = "evening_before_time"
      case eveningOfEnabled = "evening_of_enabled"
      case eveningOfTime = "evening_of_time"
      case morningOfEnabled = "morning_of_enabled"
      case morningOfTime = "morning_of_time"
      case notifyTaskAssigned = "notify_task_assigned"
      case notifyTaskCompleted = "notify_task_completed"
      case notifyTaskDateChanged = "notify_task_date_changed"
      case notifyTaskReassigned = "notify_task_reassigned"
      case notifyTaskUncompleted = "notify_task_uncompleted"
      case timezone = "timezone"
      case updatedAt = "updated_at"
      case userId = "user_id"
    }
  }
  internal struct NotificationPreferencesUpdate: Codable, Hashable, Sendable {
    internal let badgeEnabled: Bool?
    internal let eveningBeforeEnabled: Bool?
    internal let eveningBeforeTime: String?
    internal let eveningOfEnabled: Bool?
    internal let eveningOfTime: String?
    internal let morningOfEnabled: Bool?
    internal let morningOfTime: String?
    internal let notifyTaskAssigned: Bool?
    internal let notifyTaskCompleted: Bool?
    internal let notifyTaskDateChanged: Bool?
    internal let notifyTaskReassigned: Bool?
    internal let notifyTaskUncompleted: Bool?
    internal let timezone: String?
    internal let updatedAt: String?
    internal let userId: UUID?
    internal enum CodingKeys: String, CodingKey {
      case badgeEnabled = "badge_enabled"
      case eveningBeforeEnabled = "evening_before_enabled"
      case eveningBeforeTime = "evening_before_time"
      case eveningOfEnabled = "evening_of_enabled"
      case eveningOfTime = "evening_of_time"
      case morningOfEnabled = "morning_of_enabled"
      case morningOfTime = "morning_of_time"
      case notifyTaskAssigned = "notify_task_assigned"
      case notifyTaskCompleted = "notify_task_completed"
      case notifyTaskDateChanged = "notify_task_date_changed"
      case notifyTaskReassigned = "notify_task_reassigned"
      case notifyTaskUncompleted = "notify_task_uncompleted"
      case timezone = "timezone"
      case updatedAt = "updated_at"
      case userId = "user_id"
    }
  }
  internal struct ProfilesSelect: Codable, Hashable, Sendable {
    internal let accentColor: String
    internal let appLanguage: String
    internal let avatarPath: String?
    internal let createdAt: String
    internal let displayName: String
    internal let hebrewAddressStyle: String?
    internal let id: UUID
    internal let updatedAt: String
    internal enum CodingKeys: String, CodingKey {
      case accentColor = "accent_color"
      case appLanguage = "app_language"
      case avatarPath = "avatar_path"
      case createdAt = "created_at"
      case displayName = "display_name"
      case hebrewAddressStyle = "hebrew_address_style"
      case id = "id"
      case updatedAt = "updated_at"
    }
  }
  internal struct ProfilesInsert: Codable, Hashable, Sendable {
    internal let accentColor: String
    internal let appLanguage: String
    internal let avatarPath: String?
    internal let createdAt: String?
    internal let displayName: String
    internal let hebrewAddressStyle: String?
    internal let id: UUID
    internal let updatedAt: String?
    internal enum CodingKeys: String, CodingKey {
      case accentColor = "accent_color"
      case appLanguage = "app_language"
      case avatarPath = "avatar_path"
      case createdAt = "created_at"
      case displayName = "display_name"
      case hebrewAddressStyle = "hebrew_address_style"
      case id = "id"
      case updatedAt = "updated_at"
    }
  }
  internal struct ProfilesUpdate: Codable, Hashable, Sendable {
    internal let accentColor: String?
    internal let appLanguage: String?
    internal let avatarPath: String?
    internal let createdAt: String?
    internal let displayName: String?
    internal let hebrewAddressStyle: String?
    internal let id: UUID?
    internal let updatedAt: String?
    internal enum CodingKeys: String, CodingKey {
      case accentColor = "accent_color"
      case appLanguage = "app_language"
      case avatarPath = "avatar_path"
      case createdAt = "created_at"
      case displayName = "display_name"
      case hebrewAddressStyle = "hebrew_address_style"
      case id = "id"
      case updatedAt = "updated_at"
    }
  }
  internal struct TasksSelect: Codable, Hashable, Sendable {
    internal let assigneeKind: String
    internal let assigneeUserId: UUID?
    internal let completedAt: String?
    internal let completedBy: UUID?
    internal let coupleId: UUID
    internal let createdAt: String
    internal let createdBy: UUID
    internal let deletedAt: String?
    internal let dueDate: String?
    internal let dueTime: String?
    internal let id: UUID
    internal let listId: UUID?
    internal let notes: String?
    internal let status: String
    internal let title: String
    internal let updatedAt: String
    internal enum CodingKeys: String, CodingKey {
      case assigneeKind = "assignee_kind"
      case assigneeUserId = "assignee_user_id"
      case completedAt = "completed_at"
      case completedBy = "completed_by"
      case coupleId = "couple_id"
      case createdAt = "created_at"
      case createdBy = "created_by"
      case deletedAt = "deleted_at"
      case dueDate = "due_date"
      case dueTime = "due_time"
      case id = "id"
      case listId = "list_id"
      case notes = "notes"
      case status = "status"
      case title = "title"
      case updatedAt = "updated_at"
    }
  }
  internal struct TasksInsert: Codable, Hashable, Sendable {
    internal let assigneeKind: String
    internal let assigneeUserId: UUID?
    internal let completedAt: String?
    internal let completedBy: UUID?
    internal let coupleId: UUID
    internal let createdAt: String?
    internal let createdBy: UUID
    internal let deletedAt: String?
    internal let dueDate: String?
    internal let dueTime: String?
    internal let id: UUID?
    internal let listId: UUID?
    internal let notes: String?
    internal let status: String?
    internal let title: String
    internal let updatedAt: String?
    internal enum CodingKeys: String, CodingKey {
      case assigneeKind = "assignee_kind"
      case assigneeUserId = "assignee_user_id"
      case completedAt = "completed_at"
      case completedBy = "completed_by"
      case coupleId = "couple_id"
      case createdAt = "created_at"
      case createdBy = "created_by"
      case deletedAt = "deleted_at"
      case dueDate = "due_date"
      case dueTime = "due_time"
      case id = "id"
      case listId = "list_id"
      case notes = "notes"
      case status = "status"
      case title = "title"
      case updatedAt = "updated_at"
    }
  }
  internal struct TasksUpdate: Codable, Hashable, Sendable {
    internal let assigneeKind: String?
    internal let assigneeUserId: UUID?
    internal let completedAt: String?
    internal let completedBy: UUID?
    internal let coupleId: UUID?
    internal let createdAt: String?
    internal let createdBy: UUID?
    internal let deletedAt: String?
    internal let dueDate: String?
    internal let dueTime: String?
    internal let id: UUID?
    internal let listId: UUID?
    internal let notes: String?
    internal let status: String?
    internal let title: String?
    internal let updatedAt: String?
    internal enum CodingKeys: String, CodingKey {
      case assigneeKind = "assignee_kind"
      case assigneeUserId = "assignee_user_id"
      case completedAt = "completed_at"
      case completedBy = "completed_by"
      case coupleId = "couple_id"
      case createdAt = "created_at"
      case createdBy = "created_by"
      case deletedAt = "deleted_at"
      case dueDate = "due_date"
      case dueTime = "due_time"
      case id = "id"
      case listId = "list_id"
      case notes = "notes"
      case status = "status"
      case title = "title"
      case updatedAt = "updated_at"
    }
  }
}
