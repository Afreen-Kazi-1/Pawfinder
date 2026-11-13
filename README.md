# PawFinder – Location-Based Lost and Found Pet Discovery Platform

[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688.svg?style=flat&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B.svg?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Supabase-4169E1.svg?style=flat&logo=postgresql&logoColor=white)](https://supabase.com)
[![SQLAlchemy](https://img.shields.io/badge/SQLAlchemy-2.0+-D71F00.svg?style=flat&logo=sqlalchemy&logoColor=white)](https://www.sqlalchemy.org)
[![Alembic](https://img.shields.io/badge/Alembic-Migrations-orange.svg?style=flat)](https://alembic.sqlalchemy.org)
[![Pytest](https://img.shields.io/badge/Pytest-Tests%20Passing-green.svg?style=flat&logo=pytest&logoColor=white)](https://pytest.org)

PawFinder is a production-quality, cross-platform mobile application and RESTful backend service engineered to help communities discover, report, and reunite lost and found pets with their families through location-based reporting and explainable, automated matching algorithms.

---

## 1. System Architecture

PawFinder follows a clean, decoupled client-server architecture:
- **Mobile Client**: Flutter / Dart application providing an intuitive Material 3 UI (warm-cream tones with teal and orange accents), reactive state management via Riverpod, and location services.
- **Backend API**: Python FastAPI application exposing secure RESTful endpoints, OpenAPI 3.0 documentation (`/docs`), centralized exception handling, and JWT authentication.
- **Relational Database**: PostgreSQL (hosted on Supabase) utilizing SQLAlchemy 2.0 ORM with cross-platform GUIDs, JSONB match explanations, spatial coordinate indexing, and Alembic database migrations.
- **Object Storage**: Supabase Storage for pet photographs with metadata stored in PostgreSQL.

For comprehensive architectural design and module breakdown, refer to [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## 2. Prerequisites

- **Python**: Version 3.10+ (tested on Python 3.13)
- **Flutter**: Version 3.20+ (tested on Flutter 3.44.8, Dart 3.12.2)
- **PostgreSQL**: Version 14+ or hosted Supabase project
- **Git**: Installed and configured

---

## 3. Backend Setup & Local Execution

### Step 1: Create and Activate Virtual Environment
```bash
# Windows (PowerShell)
python -m venv backend/venv
.\backend\venv\Scripts\Activate.ps1

# Linux / macOS
python3 -m venv backend/venv
source backend/venv/bin/activate
```

### Step 2: Install Dependencies
```bash
pip install -r backend/requirements.txt
```

### Step 3: Configure Environment Variables
Copy `.env.example` to `.env`:
```bash
cp backend/.env.example backend/.env
```
Key configuration settings in `backend/.env`:
```env
PROJECT_NAME=PawFinder
API_V1_STR=/api
ENVIRONMENT=development
DATABASE_URL=sqlite:///./pawfinder.db   # For local dev; or postgresql://... for Supabase
JWT_SECRET_KEY=your-secure-jwt-secret-key-min-32-chars
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=60
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
SUPABASE_STORAGE_BUCKET=pet-images
```

### Step 4: Run Database Migrations
```bash
cd backend
alembic -c alembic.ini upgrade head
cd ..
```

### Step 5: Start FastAPI Server
```bash
# From workspace root
.\backend\venv\Scripts\uvicorn.exe app.main:app --app-dir backend --reload --port 8000
```
- Interactive Swagger UI: [http://localhost:8000/docs](http://localhost:8000/docs)
- Alternative ReDoc UI: [http://localhost:8000/redoc](http://localhost:8000/redoc)
- Health check: [http://localhost:8000/health](http://localhost:8000/health)

### Authentication Endpoints (`/api/auth`)
| Method | Endpoint | Description | Auth Required |
|:---|:---|:---|:---|
| `POST` | `/api/auth/register` | Register a new user account (name, email, password) | No |
| `POST` | `/api/auth/login` | Authenticate with email/password; returns JWT access & refresh tokens | No |
| `POST` | `/api/auth/refresh` | Rotate an active refresh token to obtain a fresh token pair | No |
| `POST` | `/api/auth/logout` | Revoke the provided refresh token session | Yes (Bearer) |
| `GET` | `/api/auth/me` | Fetch authenticated user profile details | Yes (Bearer) |
| `PUT` | `/api/auth/me` | Update authenticated user profile (name, phone, avatar) | Yes (Bearer) |
| `POST` | `/api/auth/change-password` | Change password and revoke all existing sessions | Yes (Bearer) |

---

## 4. Mobile Client Setup

```bash
cd mobile
flutter pub get
```

### Run Application
```bash
# Connect Android emulator or physical device
# Default API points to Android emulator bridge: http://10.0.2.2:8000/api
flutter run

# Or provide custom API URL via --dart-define:
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
```

### Mobile Architectural Foundation
- **State Management**: Riverpod (`NotifierProvider` / `Notifier` architecture)
- **Design System**: Material 3 with brand palette (Deep Teal `#00796B`, Coral `#FF7043`, Warm Cream `#FFFBF5`)
- **Network Layer**: Dio client with automated Bearer JWT injection and 401 refresh token interceptor
- **Storage**: Secure hardware-backed token storage via `flutter_secure_storage` with `TokenStorage` abstraction
- **Navigation**: Named routes (`/`, `/onboarding`, `/login`, `/register`, `/home`) with 5-tab main shell and bottom sheet report triggers
- **Reusable Components**: PrimaryButton, SecondaryButton, CustomTextField, PasswordTextField, LoadingIndicator, ErrorDisplay, EmptyStateWidget, ConfirmationDialog, PetImageCard, SectionHeader

---

## 5. Automated Testing

### Backend Testing (Pytest)
PawFinder uses an isolated in-memory test database fixture for all backend tests to prevent touching development or production data.

```bash
# Run all backend tests
.\backend\venv\Scripts\pytest.exe -v
```

Verified test coverage includes:
- FastAPI startup & root endpoint
- Database health check & ping endpoints
- Database connection & transactional session lifecycle
- Model instantiation, UUID generation & UTC timestamps for all entities
- Database constraints: unique email, duplicate match pair prevention, cascade deletes
- Alembic migration upgrade, downgrade rollback, and re-upgrade

### Frontend Testing (Flutter Test)
```bash
cd mobile
flutter test
```

---

## 6. Project Directory Layout

```
Pawfinder/
├── backend/                  # FastAPI application & Alembic migrations
│   ├── alembic/              # Database migration versions & env.py
│   ├── app/
│   │   ├── api/              # API endpoints and dependency injection
│   │   ├── core/             # Configuration, database engine & security
│   │   ├── db/               # Seed scripts & DB session helpers
│   │   ├── models/           # SQLAlchemy models & database constraints
│   │   ├── repositories/     # Data query abstraction layer
│   │   ├── schemas/          # Pydantic request/response validation
│   │   ├── services/         # Business logic (matching, notifications, storage)
│   │   └── utils/            # Geospatial math and helpers
│   ├── tests/                # Pytest automated test suite
│   ├── alembic.ini
│   ├── pytest.ini
│   └── requirements.txt
├── mobile/                   # Flutter mobile client
│   ├── integration_test/     # End-to-end integration tests
│   ├── lib/                  # Feature-first application code
│   └── test/                 # Flutter widget & unit tests
├── docs/                     # Project architecture & development progress
│   ├── ARCHITECTURE.md
│   └── DEVELOPMENT_PROGRESS.md
├── requirements.md           # Master software requirements specification
└── README.md
```

