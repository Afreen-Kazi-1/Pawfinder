# PawFinder – System Architecture & Module Blueprint

## 1. System Overview
PawFinder is a location-aware lost-and-found pet discovery application built on a client-server architecture:
- **Mobile Frontend**: Cross-platform Flutter application (Dart).
- **Backend API**: Python FastAPI application exposing secure RESTful endpoints with OpenAPI/Swagger documentation.
- **Relational Database**: PostgreSQL (hosted on Supabase, with SQLite compatibility for isolated automated test runs) managed via SQLAlchemy 2.0 ORM and Alembic migrations.
- **Image Storage**: Supabase Storage for pet photographs, referenced by metadata in PostgreSQL.
- **Authentication**: JWT (JSON Web Tokens) with bcrypt password hashing.

---

## 2. Directory Structure & Layering

### 2.1 Backend Architecture (`backend/`)
Following a clean, layered feature-and-service-oriented architecture:

```
backend/
├── alembic/                      # Alembic migration environment and version scripts
│   ├── versions/                 # Database migration revision files
│   ├── env.py                    # Alembic runtime configuration
│   └── script.py.mako            # Migration template
├── app/
│   ├── __init__.py
│   ├── main.py                   # FastAPI application initialization & middleware
│   ├── api/                      # API routing and HTTP request handling
│   │   ├── deps.py               # Authentication & session dependencies
│   │   └── v1/
│   │       ├── api.py            # Aggregated v1 API router
│   │       └── endpoints/        # Individual resource route handlers
│   ├── core/                     # Application configurations & security primitives
│   │   ├── config.py             # Pydantic BaseSettings loading from environment
│   │   ├── database.py           # Engine, SessionLocal, cross-platform GUID/JSON types
│   │   └── security.py           # bcrypt password hashing & JWT encode/decode
│   ├── models/                   # SQLAlchemy declarative ORM models
│   │   ├── user.py               # User account model
│   │   ├── pet_report.py         # Lost & found pet reports
│   │   ├── pet_image.py          # Pet image storage references
│   │   ├── match.py              # Automated match results & deduplication
│   │   ├── contact_request.py    # Direct user communication requests
│   │   ├── notification.py       # User notification records
│   │   └── abuse_report.py       # Moderation & content abuse reports
│   ├── schemas/                  # Pydantic validation & serialization models
│   ├── repositories/             # Database access layer isolating SQLAlchemy queries
│   ├── services/                 # Pure business logic (matching algorithm, notifications)
│   ├── db/                       # Database initialization & seed scripts
│   └── utils/                    # Common helper functions (geospatial math, text search)
├── tests/                        # Automated Pytest suite
│   ├── conftest.py               # Test client & in-memory test database fixtures
│   └── test_*.py                 # Unit and integration test cases
├── alembic.ini                   # Alembic configuration file
├── requirements.txt              # Production and test Python dependencies
└── .env.example                  # Environment configuration template
```

### 2.2 Mobile Frontend Architecture (`mobile/`)
Following a clean, modular, feature-first Flutter architecture:

```
mobile/
├── lib/
│   ├── main.dart                 # Application entry point
│   ├── app/                      # Application root widget, themes, and route definitions
│   │   ├── app.dart              # MaterialApp setup and global providers
│   │   ├── routes.dart           # Route generator and path constants
│   │   └── theme.dart            # Custom Material 3 theme (warm-cream, teal/orange accents)
│   ├── core/                     # Reusable utilities, network clients, base widgets
│   │   ├── constants/            # API endpoints, asset paths, typography constants
│   │   ├── network/              # Dio / HTTP client with JWT interceptor & refresh handling
│   │   ├── storage/              # Secure token storage (flutter_secure_storage / shared_preferences)
│   │   ├── utils/                # Date formatting, location utilities, validation helpers
│   │   └── widgets/              # Reusable UI widgets (buttons, input fields, cards, badges)
│   ├── features/                 # Modular domain features
│   │   ├── authentication/       # Login, Register, Forgot Password, Profile Edit
│   │   ├── home/                 # Dashboard with quick actions, summaries & recent activity
│   │   ├── reports/              # Create Lost/Found Report, Edit Report, My Reports
│   │   ├── discovery/            # Browse listings, Filter dialog, Nearby map view
│   │   ├── matching/             # Suggested Matches list, Match Details, status actions
│   │   ├── contact/              # Contact requests (send, view, accept, reject)
│   │   └── notifications/        # In-app notifications screen & read status updates
│   └── services/                 # Abstract API clients and platform service bridges
├── test/                         # Unit tests and widget tests
│   ├── widget_test.dart
│   └── ...
├── integration_test/             # End-to-end Flutter integration tests
└── pubspec.yaml                  # Flutter package dependencies and assets
```

---

## 3. Technology & Dependency Decisions

1. **Flutter State Management**:
   - **Decision**: `flutter_riverpod` (v2.x).
   - **Rationale**: Riverpod is compile-safe, does not depend on `BuildContext`, supports seamless asynchronous state transitions (`AsyncValue`), is easily testable with overrides in widget tests, and eliminates boilerplate.
2. **Network Client**:
   - **Decision**: `dio` (with interceptors for JWT injection and transparent 401 token refresh).
3. **Local Storage**:
   - **Decision**: `flutter_secure_storage` for JWT tokens; `shared_preferences` for non-sensitive user settings.
4. **Backend ORM & Migrations**:
   - **Decision**: SQLAlchemy 2.0 with Alembic.
   - **Rationale**: Enforces type annotations, connection pooling, cross-platform compatibility (`GUID` and `JSONType` abstractions supporting PostgreSQL on Supabase while allowing zero-configuration SQLite for developer workstations and local Pytest execution).
5. **Security & Cryptography**:
   - **Decision**: `bcrypt` for secure salted password hashing, `pyjwt` with HMAC-SHA256 (`HS256`) for access and refresh tokens.

---

## 4. Requirements-to-Module Mapping

| SRS Section | Feature Domain | Backend Components | Mobile Components |
|:---|:---|:---|:---|
| **3.1** | User Authentication & Accounts | `api/v1/endpoints/auth.py`, `models/user.py`, `core/security.py` | `features/authentication/`, `core/network/` |
| **3.2** | Home Dashboard | `api/v1/endpoints/reports.py`, `discovery.py` | `features/home/` |
| **3.3, 3.4** | Lost & Found Pet Reporting | `api/v1/endpoints/reports.py`, `models/pet_report.py`, `services/report_service.py` | `features/reports/` |
| **3.5, 3.6** | Discovery, Search & Map | `api/v1/endpoints/discovery.py`, `utils/geo.py` | `features/discovery/` |
| **3.7, 3.8** | Automated Matching Engine | `services/matching_service.py`, `models/match.py`, `api/v1/endpoints/matches.py` | `features/matching/` |
| **3.9** | User Communication | `api/v1/endpoints/contact.py`, `models/contact_request.py` | `features/contact/` |
| **3.10** | In-App Notifications | `api/v1/endpoints/notifications.py`, `models/notification.py`, `services/notification_service.py` | `features/notifications/` |
| **3.11** | Report Status Management | `api/v1/endpoints/reports.py` (PATCH status), `services/report_service.py` | `features/reports/` |
| **3.12** | Profile & Report History | `api/v1/endpoints/auth.py` (me), `api/v1/endpoints/reports.py` (mine) | `features/profile/` |
| **3.13** | Abuse Moderation | `api/v1/endpoints/moderation.py`, `models/abuse_report.py` | `features/reports/widgets/abuse_dialog.dart` |
| **7** | Image Storage | `services/storage_service.py`, `models/pet_image.py` | `features/reports/widgets/image_picker.dart` |

---

## 5. Module Dependency Plan

```
[Module 00: Baseline Analysis & Structure]
       │
       ▼
[Module 01: Core Backend Setup, DB Schema & Alembic Migrations]
       │
       ▼
[Module 02: Authentication & User Accounts (Backend API + Unit Tests)]
       │
       ▼
[Module 03: Flutter App Setup, Navigation, Auth UI & API Client]
       │
       ▼
[Module 04: Pet Report Management & Image Storage Integration]
       │
       ▼
[Module 05: Pet Discovery, Search, Filtering & Nearby Map View]
       │
       ▼
[Module 06: Automated Matching Engine (Weighted Algorithm & Triggers)]
       │
       ▼
[Module 07: User Communication & In-App Notifications]
       │
       ▼
[Module 08: Profile, Report History, Moderation & Status Lifecycle]
       │
       ▼
[Module 09: End-to-End Testing, Bug Fixes & Academic Documentation]
```

---

## 6. Testing Strategy

1. **Backend Testing**:
   - **Framework**: `pytest` and `httpx.AsyncClient` / `TestClient`.
   - **Test Isolation**: In-memory SQLite or temporary database instance created and torn down per test session.
   - **Coverage**:
     - Password hashing and JWT generation/validation.
     - User registration, login, and token refresh.
     - Protected route access control (401 Unauthorized, 403 Forbidden).
     - Report CRUD and strict report ownership validation.
     - Spatial distance queries and discovery filters.
     - Matching algorithm scoring, weight application, and deduplication.
     - Contact request lifecycle and notification triggers.
2. **Frontend Testing**:
   - **Framework**: Flutter test runner (`flutter test`).
   - **Widget Tests**: Key screens (Login, Registration, Report Form, Match Card).
   - **Unit Tests**: Models, deserialization, repositories, validation logic.
   - **Integration Tests**: In `mobile/integration_test/` covering full user journey.
3. **Execution Rules**:
   - Every test must be executed before declaring module completion.
   - Test results (Name, Expected, Actual, Status) will be systematically recorded.

---

## 7. Unresolved Design Decisions & Mitigations

1. **Privacy vs. Map Precision**:
   - *Requirement*: Exact residential addresses and private coordinates must not be publicly exposed.
   - *Mitigation*: The backend discovery endpoints will return jittered/fuzzed coordinates (rounded to ~300m) for public map displays, while preserving precise coordinates internally for distance matching calculations.
2. **Supabase Storage Credentials during Offline/Local Development**:
   - *Requirement*: Store pet images in Supabase Storage.
   - *Mitigation*: The storage service will implement an abstract storage interface: when Supabase credentials are not supplied in `.env`, it falls back to saving uploads in a local static directory (`uploads/`) with public URL serving, allowing full end-to-end functionality without hardcoded credentials.
3. **Reverse Matching Trigger**:
   - *Requirement*: Matching must run when a new lost report is created, and in reverse when a new found report is created.
   - *Mitigation*: A shared `MatchingService.run_matching_for_report(report_id)` will be called automatically post-creation in the report service.

