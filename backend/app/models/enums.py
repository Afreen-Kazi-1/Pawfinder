import enum


class ReportTypeEnum(str, enum.Enum):
    LOST = "LOST"
    FOUND = "FOUND"


class ReportStatusEnum(str, enum.Enum):
    OPEN = "Open"
    UNDER_REVIEW = "Under Review"
    REUNITED_RESOLVED = "Reunited / Resolved"
    CLOSED = "Closed"


class AnimalTypeEnum(str, enum.Enum):
    DOG = "Dog"
    CAT = "Cat"
    BIRD = "Bird"
    OTHER = "Other"


class GenderEnum(str, enum.Enum):
    MALE = "Male"
    FEMALE = "Female"
    UNKNOWN = "Unknown"


class MatchCategoryEnum(str, enum.Enum):
    HIGH = "High potential match"
    POSSIBLE = "Possible match"


class MatchStatusEnum(str, enum.Enum):
    SUGGESTED = "Suggested"
    RELEVANT = "Relevant"
    DISMISSED = "Dismissed"
    RESOLVED = "Resolved"


class ContactRequestStatusEnum(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"


class NotificationTypeEnum(str, enum.Enum):
    MATCH = "match"
    CONTACT_REQUEST = "contact_request"
    CONTACT_RESPONSE = "contact_response"
    STATUS_UPDATE = "status_update"
    RESOLVED = "resolved"


class AbuseStatusEnum(str, enum.Enum):
    PENDING = "pending"
    REVIEWED = "reviewed"
    DISMISSED = "dismissed"
    ACTION_TAKEN = "action_taken"


class UserRoleEnum(str, enum.Enum):
    USER = "user"
    ADMIN = "admin"

