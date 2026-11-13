# PawFinder – Software Requirements Specification

**Project Title:** PawFinder – A Location-Based Lost and Found Pet Discovery Platform  
**Project Type:** Cross-Platform Mobile Application  
**Academic Context:** CPAD ESE Mini Project  
**Version:** 1.0

---

# 1. Project Overview

## 1.1 Introduction

PawFinder is a cross-platform mobile application designed to help people locate lost pets and reunite them with their owners.

The application provides a centralized platform where users can report missing pets, report animals they have found, browse nearby reports, and discover potential matches between lost and found pet listings.

Users can upload photographs, provide descriptions, specify the last-seen or found location, and receive potential match suggestions based on animal characteristics and geographical proximity.

PawFinder aims to simplify the process of locating missing pets through a location-aware reporting and matching system.

## 1.2 Problem Statement

When pets go missing, owners often rely on scattered social media posts, local messaging groups, posters, and word of mouth.

These approaches make it difficult to:
- Reach people in the immediate vicinity.
- Search through reports systematically.
- Identify whether a found animal matches an existing missing-pet report.
- Keep track of updates to missing-pet cases.
- Coordinate communication between pet owners and people who find animals.

PawFinder addresses these problems through a centralized mobile platform with location-based discovery and automated matching.

## 1.3 Project Objectives

1. Develop a functional Android and iOS-compatible mobile application.
2. Allow users to create and manage lost and found pet reports.
3. Enable image uploads and location-based reporting.
4. Implement an automated potential-match recommendation system.
5. Provide searchable and filterable pet listings.
6. Maintain user accounts, pet reports, match records, and report statuses in a persistent database.
7. Provide a secure communication mechanism between users.
8. Maintain a history of reports and their status updates.

---

# 2. Technology Stack

The application MUST use the following technology stack.

| Component | Technology |
|---|---|
| Mobile frontend | Flutter |
| Programming language | Dart |
| Backend | Python + FastAPI |
| Database | PostgreSQL |
| Database hosting | Supabase |
| ORM | SQLAlchemy |
| Database migrations | Alembic |
| Image storage | Supabase Storage |
| Authentication | JWT-based authentication |
| API communication | REST API |
| Maps and location | Google Maps SDK/API or an equivalent supported mapping solution |
| API documentation | FastAPI Swagger/OpenAPI |
| Version control | Git and GitHub |

### Architecture requirements

The application must follow a client-server architecture.

Flutter must communicate with the FastAPI backend through REST APIs.

The backend must:
- Validate incoming requests.
- Authenticate and authorize users.
- Execute application business logic.
- Perform database operations.
- Handle image-storage integration.
- Calculate potential pet matches.
- Return structured JSON responses.

The Flutter application must not directly manipulate database tables or bypass the backend for core business operations.

Supabase may be used for PostgreSQL hosting and image storage, but FastAPI must remain the primary application backend.

---

# 3. Functional Requirements

## 3.1 User Authentication and Account Management

Users must be able to create and manage accounts.

Required functionality:

- User registration using name, email, and password.
- User login.
- Secure password hashing.
- JWT access-token authentication.
- Token refresh or reauthentication.
- Logout.
- View and edit profile information.
- View the user's submitted reports.
- Change password through a secure workflow.

Each user must have a unique account identifier.

Unauthenticated users may browse publicly available pet reports, but must authenticate before creating reports or initiating contact.

## 3.2 Home Dashboard

The home screen should provide access to the application's major functionality.

Required elements:

- Application logo and branding.
- Search bar.
- Lost Pets section.
- Found Pets section.
- Nearby Reports section.
- Potential Matches section.
- Quick action to report a lost pet.
- Quick action to report a found pet.
- Navigation to profile and report history.

The interface should be intuitive and optimized for mobile devices.

## 3.3 Lost Pet Reporting

Users must be able to submit a missing-pet report.

Required input fields:

| Field | Description |
|---|---|
| Pet name | Name of the missing animal |
| Animal type | Dog, cat, bird, or other |
| Breed | Breed or approximate breed |
| Color | Primary and secondary colors |
| Gender | Male, female, or unknown |
| Approximate age | Age of the animal |
| Distinguishing features | Spots, markings, collar, scars, etc. |
| Description | Additional information |
| Photograph | One or more pet photographs |
| Last-seen location | Geographical location |
| Last-seen date and time | When the pet was last seen |
| Reward | Optional reward information |
| Contact preference | Preferred contact method |

Functional requirements:

- Users must be able to capture photographs using the device camera.
- Users must be able to select photographs from the gallery.
- Users must be able to select a location using GPS or a map.
- Users must be able to edit their submitted reports.
- Users must be able to delete or close their reports.
- Reports must be stored persistently in the database.

Every lost-pet report must have a unique report ID and a creation timestamp.

## 3.4 Found Pet Reporting

Users must be able to report an animal they have found.

Required input fields:

- Animal type.
- Approximate breed.
- Color.
- Approximate age.
- Gender, if identifiable.
- Distinguishing features.
- Description.
- Photograph.
- Found location.
- Date and time found.
- Additional observations.

Functional requirements:

- Capture or upload photographs.
- Obtain the current location through GPS.
- Allow manual location selection.
- Submit the report to the backend.
- Edit or close reports created by the user.
- View the report after submission.

The application must support found animals whose breed, gender, or other characteristics are unknown.

## 3.5 Pet Discovery and Search

Users must be able to browse available lost and found reports.

Required functionality:

- View lost-pet reports.
- View found-pet reports.
- Search by animal type.
- Filter by breed.
- Filter by color.
- Filter by location or distance.
- Filter by date.
- View individual report details.
- View associated photographs.
- View approximate report locations on a map.

Search and filtering must use backend APIs rather than filtering only a small hardcoded frontend dataset.

The application must support pagination or equivalent result loading for larger datasets.

## 3.6 Location-Based Discovery

PawFinder must provide geographical discovery of pet reports.

Requirements:

- Request location permission when necessary.
- Obtain device location through GPS.
- Allow users to manually select locations.
- Store geographical coordinates for reports.
- Search for reports within a configurable radius.
- Display approximate locations on a map.
- Allow users to change their search radius.

The default search radius should be configurable, with an initial value of 10 km.

**Privacy requirement:** Exact residential addresses and sensitive user coordinates must not be publicly exposed. Map markers should use appropriately approximate locations.

If location permission is denied, users must still be able to search using manually selected locations.

## 3.7 Automated Pet Matching System

This is one of PawFinder's most important features.

The backend must identify potential matches between lost-pet and found-pet reports.

For example:

- A user reports a missing brown Labrador in a particular area.
- Another user reports finding a brown Labrador nearby.
- The system compares both reports and recommends a possible match.

### Matching criteria

The matching algorithm must consider:

1. Animal type.
2. Breed similarity.
3. Color similarity.
4. Distinguishing features.
5. Geographical distance.
6. Date proximity.
7. Description similarity, where feasible.

### Initial matching algorithm

Implement a weighted scoring system.

Suggested initial weights:

| Criterion | Weight |
|---|---:|
| Animal type | 25% |
| Breed similarity | 15% |
| Color similarity | 15% |
| Location proximity | 20% |
| Date proximity | 10% |
| Distinguishing features and description | 15% |
| **Total** | **100%** |

The algorithm must normalize its component scores to a range of 0–100 before calculating the final score.

The weights must be configurable in the backend.

### Matching categories

| Score | Classification |
|---|---|
| 80–100 | High potential match |
| 60–79 | Possible match |
| Below 60 | Do not recommend by default |

These thresholds must be configurable.

### Matching workflow

1. A new lost-pet report is submitted.
2. The backend retrieves relevant open found-pet reports.
3. The matching algorithm calculates similarity scores.
4. Potential matches are saved in the database.
5. The owner can view suggested matches.
6. The user can open a suggested match and inspect its details.
7. The user can mark a match as relevant or dismiss it.

The matching process must also work in reverse when a new found-pet report is submitted.

Matching must not be limited to reports created at the same time. Existing open reports must also be considered.

A matching result is only a recommendation. It must never be presented as proof that two reports refer to the same animal.

### Future enhancement

Image similarity using a computer-vision model may be added as an optional enhancement, but it is not mandatory for the first complete version.

The initial weighted matching algorithm must work independently of any AI model.

## 3.8 Match Management

Users must be able to:

- View potential matches associated with their reports.
- Open the original lost and found reports.
- View the matching score and reasons for the recommendation.
- Mark a match as relevant.
- Dismiss an irrelevant suggestion.
- Track whether a match has been resolved.

The backend must prevent duplicate match records for the same pair of reports.

## 3.9 User Communication

Users must have a safe way to communicate about a potential match.

Minimum required functionality:

- A contact-request mechanism.
- A way for the report owner to accept or reject the request.
- A way for the requesting user to see the request status.
- A secure method to exchange contact information after acceptance.

Users' private contact information must not be displayed publicly on pet listings.

A full real-time chat system is optional and should only be implemented after the core application is complete.

## 3.10 Notifications

The application must provide notifications for important events.

Required notification events:

- A potential match is identified.
- A contact request is received.
- A contact request is accepted or rejected.
- A report status is updated.
- A report is marked as resolved.

At minimum, notifications must be stored in the database and displayed in an in-app notification screen.

Push notifications through Firebase Cloud Messaging may be implemented as an additional enhancement.

## 3.11 Report Status Management

Every pet report must have a status.

Supported statuses:

- Open
- Under Review
- Reunited / Resolved
- Closed

Users must be able to update the status of their own reports.

Resolved or closed reports must no longer appear in active discovery results or generate new active matches.

The application must retain historical records.

## 3.12 User Profile and Report History

Users must be able to view:

- Profile information.
- Reports submitted by them.
- Lost-pet reports.
- Found-pet reports.
- Suggested matches.
- Contact requests.
- Notifications.
- Resolved cases.

Users must be able to edit profile details and manage their reports.

## 3.13 Abuse Reporting and Moderation

Implement basic mechanisms to improve platform safety.

Requirements:

- Users can report suspicious pet listings.
- Users can report inappropriate content.
- Reports must be stored for administrative review.
- Users cannot modify another user's pet reports.
- Only authorized administrators may review or change moderation status.

A basic administrator interface or protected administrative API is sufficient for the initial version.

---

# 4. Database Requirements

The database must use PostgreSQL.

Use normalized relational tables and appropriate foreign-key constraints.

The following tables are required.

## 4.1 Users

| Column | Type |
|---|---|
| id | UUID, Primary Key |
| name | VARCHAR |
| email | VARCHAR, Unique |
| password_hash | VARCHAR |
| phone | VARCHAR, Nullable |
| profile_image_url | TEXT, Nullable |
| role | VARCHAR |
| created_at | TIMESTAMP |
| updated_at | TIMESTAMP |

## 4.2 Pet Reports

A common table must be used for lost and found reports, distinguished using a report type.

| Column | Type |
|---|---|
| id | UUID, Primary Key |
| user_id | UUID, Foreign Key |
| report_type | ENUM: LOST / FOUND |
| pet_name | VARCHAR, Nullable |
| animal_type | VARCHAR |
| breed | VARCHAR, Nullable |
| color | VARCHAR |
| gender | VARCHAR, Nullable |
| approximate_age | VARCHAR, Nullable |
| distinguishing_features | TEXT |
| description | TEXT |
| latitude | DECIMAL |
| longitude | DECIMAL |
| location_label | VARCHAR |
| event_datetime | TIMESTAMP |
| reward | DECIMAL, Nullable |
| status | VARCHAR |
| created_at | TIMESTAMP |
| updated_at | TIMESTAMP |

## 4.3 Pet Images

| Column | Type |
|---|---|
| id | UUID, Primary Key |
| report_id | UUID, Foreign Key |
| image_url | TEXT |
| storage_path | TEXT |
| uploaded_at | TIMESTAMP |

## 4.4 Matches

| Column | Type |
|---|---|
| id | UUID, Primary Key |
| lost_report_id | UUID, Foreign Key |
| found_report_id | UUID, Foreign Key |
| match_score | DECIMAL |
| match_category | VARCHAR |
| match_reasons | JSONB |
| status | VARCHAR |
| created_at | TIMESTAMP |
| updated_at | TIMESTAMP |

A unique constraint must prevent duplicate pairs of lost and found reports.

## 4.5 Contact Requests

| Column | Type |
|---|---|
| id | UUID, Primary Key |
| sender_id | UUID, Foreign Key |
| receiver_id | UUID, Foreign Key |
| report_id | UUID, Foreign Key |
| message | TEXT |
| status | VARCHAR |
| created_at | TIMESTAMP |
| updated_at | TIMESTAMP |

## 4.6 Notifications

| Column | Type |
|---|---|
| id | UUID, Primary Key |
| user_id | UUID, Foreign Key |
| title | VARCHAR |
| message | TEXT |
| notification_type | VARCHAR |
| related_entity_id | UUID, Nullable |
| is_read | BOOLEAN |
| created_at | TIMESTAMP |

## 4.7 Abuse Reports

| Column | Type |
|---|---|
| id | UUID, Primary Key |
| reporter_id | UUID, Foreign Key |
| reported_user_id | UUID, Foreign Key |
| pet_report_id | UUID, Foreign Key, Nullable |
| reason | TEXT |
| status | VARCHAR |
| created_at | TIMESTAMP |

### Database implementation requirements

- Use SQLAlchemy models.
- Use Alembic migrations.
- Create database indexes for frequently queried columns.
- Add indexes for report type, status, animal type, and geographical queries.
- Use transactions where multiple related records must be updated together.
- Store timestamps consistently in UTC.
- Enforce foreign-key relationships and validation constraints.
- Never store plaintext passwords.
- Use UUID identifiers for primary keys.

---

# 5. Backend API Requirements

The FastAPI backend must expose REST endpoints.

All endpoints must return structured JSON responses with appropriate HTTP status codes.

## 5.1 Authentication

| Method | Endpoint | Purpose |
|---|---|---|
| POST | /api/auth/register | Register user |
| POST | /api/auth/login | Authenticate user |
| POST | /api/auth/refresh | Refresh access token |
| GET | /api/auth/me | Get current user |
| PUT | /api/auth/me | Update profile |

## 5.2 Pet Reports

| Method | Endpoint | Purpose |
|---|---|---|
| POST | /api/reports | Create lost/found report |
| GET | /api/reports | Retrieve reports |
| GET | /api/reports/{id} | Retrieve individual report |
| PUT | /api/reports/{id} | Update report |
| DELETE | /api/reports/{id} | Delete or archive report |
| PATCH | /api/reports/{id}/status | Update report status |
| GET | /api/reports/mine | Get current user's reports |

## 5.3 Images

| Method | Endpoint | Purpose |
|---|---|---|
| POST | /api/reports/{id}/images | Upload report images |
| GET | /api/reports/{id}/images | Retrieve report images |
| DELETE | /api/images/{id} | Delete an image |

Images must be validated for file type and size before storage.

## 5.4 Discovery and Search

| Method | Endpoint | Purpose |
|---|---|---|
| GET | /api/discovery | Browse reports |
| GET | /api/discovery/nearby | Search nearby reports |
| GET | /api/discovery/map | Retrieve map listings |

Support query parameters for:

- Report type.
- Animal type.
- Breed.
- Color.
- Latitude.
- Longitude.
- Search radius.
- Date range.
- Page number.
- Page size.

## 5.5 Matching

| Method | Endpoint | Purpose |
|---|---|---|
| POST | /api/matches/run/{report_id} | Run matching for a report |
| GET | /api/matches | Retrieve current user's matches |
| GET | /api/matches/{id} | View individual match |
| PATCH | /api/matches/{id}/status | Update match status |

The backend must enforce report ownership and authorization when running matching or modifying match records.

## 5.6 Contact Requests

| Method | Endpoint | Purpose |
|---|---|---|
| POST | /api/contact-requests | Send contact request |
| GET | /api/contact-requests | Retrieve received and sent requests |
| PATCH | /api/contact-requests/{id} | Accept or reject request |

## 5.7 Notifications

| Method | Endpoint | Purpose |
|---|---|---|
| GET | /api/notifications | Retrieve notifications |
| PATCH | /api/notifications/{id}/read | Mark notification as read |
| PATCH | /api/notifications/read-all | Mark all notifications as read |

## 5.8 Moderation

| Method | Endpoint | Purpose |
|---|---|---|
| POST | /api/abuse-reports | Submit abuse report |
| GET | /api/admin/abuse-reports | View reports as administrator |
| PATCH | /api/admin/abuse-reports/{id} | Update moderation status |

All protected endpoints must require valid authentication and appropriate authorization.

---

# 6. Flutter Application Requirements

The Flutter application must provide a polished, responsive mobile interface.

## 6.1 Required Screens

1. Splash Screen
2. Onboarding Screen
3. Login Screen
4. Registration Screen
5. Home Dashboard
6. Lost Pet Listing Screen
7. Found Pet Listing Screen
8. Create Lost Pet Report Screen
9. Create Found Pet Report Screen
10. Pet Details Screen
11. Search and Filter Screen
12. Nearby Pets Map Screen
13. Potential Matches Screen
14. Match Details Screen
15. Contact Request Screen
16. Notifications Screen
17. User Profile Screen
18. My Reports Screen
19. Edit Report Screen
20. Settings Screen

An administrator screen may be implemented as a separate protected interface.

## 6.2 Navigation

Use a consistent bottom navigation bar.

Suggested tabs:

- Home
- Discover
- Report
- Matches
- Profile

The Report tab should provide options to report a lost pet or a found pet.

## 6.3 UI/UX Guidelines

The application should have a friendly, trustworthy and modern visual identity.

Suggested design direction:

- Warm cream or off-white backgrounds.
- Teal, green or orange accent colors.
- Rounded cards.
- Clear typography.
- Consistent spacing.
- Pet photographs as prominent visual elements.
- Accessible buttons and form controls.
- Loading indicators and empty states.
- Error messages and confirmation dialogs.

Avoid generic default Flutter layouts.

The application must support different Android screen sizes and should be designed with accessibility in mind.

## 6.4 Flutter Architecture

Use a maintainable feature-based project structure.

Suggested structure:

    mobile/
      lib/
        main.dart
        app/
          app.dart
          routes.dart
          theme.dart
        core/
          constants/
          network/
          storage/
          utils/
          widgets/
        features/
          authentication/
            data/
            models/
            screens/
            widgets/
          home/
          reports/
          discovery/
          matching/
          contact/
          notifications/
          profile/
        services/
        models/

Use a suitable state-management solution such as Riverpod or Provider.

Keep API communication in dedicated service/repository classes rather than directly inside UI widgets.

Use proper model classes for API request and response data.

## 6.5 Device Integrations

The application should integrate with:

- Device camera.
- Image gallery.
- GPS and location services.
- Map interface.
- Local notification display.

Handle permission denial and device failures gracefully.

---

# 7. Image Storage Requirements

Pet photographs must be stored in Supabase Storage.

Requirements:

- Store images separately from relational database records.
- Save storage paths and associated metadata in PostgreSQL.
- Validate image formats.
- Restrict maximum upload size.
- Generate unique filenames.
- Prevent unauthorized deletion or replacement.
- Use appropriate storage access policies.
- Display uploaded images in pet report cards and details screens.

The application must not store large image binaries directly in PostgreSQL.

---

# 8. Security Requirements

The implementation must follow basic application security practices.

1. Hash passwords using a secure password-hashing algorithm such as Argon2 or bcrypt.
2. Never store passwords in plaintext.
3. Protect API endpoints with authentication.
4. Verify ownership before modifying or deleting reports.
5. Validate all user inputs on the backend.
6. Restrict file upload types and sizes.
7. Protect sensitive user information.
8. Avoid exposing exact private user locations.
9. Store secrets in environment variables.
10. Never commit API keys, database passwords, JWT secrets or service-role keys to GitHub.
11. Configure CORS appropriately.
12. Return safe error messages without exposing stack traces or sensitive information in production.

---

# 9. Non-Functional Requirements

## 9.1 Performance

- Standard API operations should respond promptly under normal development loads.
- Use pagination for report listings.
- Optimize uploaded images where appropriate.
- Avoid unnecessary database queries.
- Load images efficiently.
- Run matching without blocking unrelated application operations for excessive periods.

## 9.2 Reliability

- Handle network failures.
- Handle expired authentication tokens.
- Provide retry mechanisms where appropriate.
- Prevent duplicate report submissions caused by accidental repeated taps.
- Maintain database consistency.

## 9.3 Maintainability

- Use modular frontend and backend code.
- Follow consistent naming conventions.
- Separate business logic from API routes.
- Maintain clear documentation.
- Use Git for version control.

## 9.4 Compatibility

- Android must be fully functional and tested.
- iOS compatibility should be maintained where practical.
- The application should adapt to different mobile screen sizes.

---

# 10. Testing Requirements

The project must include testing for both frontend and backend functionality.

## 10.1 Backend Testing

Use Pytest and FastAPI TestClient.

Test:

- User registration.
- Login and authentication.
- Unauthorized API access.
- Report creation.
- Report retrieval.
- Report modification.
- Report ownership checks.
- Image upload validation.
- Discovery filters.
- Location-based searches.
- Matching algorithm.
- Duplicate match prevention.
- Contact requests.
- Notification generation.
- Report status updates.

## 10.2 Flutter Testing

Include:

- Widget tests for important screens.
- Form validation tests.
- Navigation tests.
- API integration tests.
- Error-state handling tests.

## 10.3 End-to-End Testing

Demonstrate the following complete workflow:

1. User A registers.
2. User A reports a missing dog with a photograph and location.
3. User B registers.
4. User B reports finding a similar dog in a nearby location.
5. The backend runs the matching algorithm.
6. User A receives a potential-match notification.
7. User A views the suggested match.
8. User A sends a contact request.
9. User B accepts the request.
10. Both users can coordinate through the application's approved contact mechanism.
11. User A marks the missing-pet report as resolved.

This workflow must be tested using actual database records and API calls.

---

# 11. Development and Deployment Requirements

The project must run locally with clearly documented setup instructions.

## 11.1 Backend

Requirements:

- Python virtual environment.
- Dependency file (`requirements.txt` or `pyproject.toml`).
- Environment configuration (`.env.example`).
- Database connection configuration.
- Alembic migrations.
- FastAPI application startup instructions.
- Swagger documentation at `/docs`.

## 11.2 Flutter

Requirements:

- Flutter project with a valid `pubspec.yaml`.
- Documented dependency installation.
- API base URL configuration.
- Android build configuration.
- Instructions to run on an emulator or physical device.

## 11.3 Environment Configuration

Provide an `.env.example` file containing placeholders for:

- DATABASE_URL
- JWT_SECRET_KEY
- JWT_ACCESS_TOKEN_EXPIRE_MINUTES
- JWT_REFRESH_TOKEN_EXPIRE_DAYS
- SUPABASE_URL
- SUPABASE_SERVICE_ROLE_KEY
- SUPABASE_STORAGE_BUCKET
- GOOGLE_MAPS_API_KEY, if applicable

Actual secrets must never be included in the repository.

The Flutter application must use appropriate environment configuration for its API base URL and public configuration values.

---

# 12. Documentation Requirements

The repository must include a comprehensive README and a separate project report.

The README must include:

- Project overview.
- Features.
- Technology stack.
- Architecture.
- Prerequisites.
- Installation instructions.
- Backend setup.
- Flutter setup.
- Database setup.
- Environment configuration.
- API documentation.
- Testing instructions.
- Troubleshooting.

The academic project report must include:

1. Abstract.
2. Introduction.
3. Problem statement.
4. Objectives.
5. Existing system and limitations.
6. Proposed system.
7. Software and hardware requirements.
8. Technology stack.
9. System architecture.
10. Use-case diagram.
11. Data-flow diagram.
12. ER diagram.
13. Database design.
14. Module descriptions.
15. API documentation.
16. Screenshots.
17. Testing and results.
18. Limitations.
19. Future enhancements.
20. Conclusion.
21. References.

Include actual application screenshots and diagrams generated from the implemented system.

Do not fabricate test results or claim that unimplemented features work.

---

# 13. Project Scope and Priorities

To ensure completion within the academic project timeline, divide implementation into priorities.

## Priority 1 – Mandatory MVP

These features must be completed before considering the project functional:

- Flutter application setup.
- User registration and login.
- FastAPI backend.
- PostgreSQL integration.
- Lost-pet reporting.
- Found-pet reporting.
- Image uploads.
- Pet discovery and search.
- Location capture and manual location selection.
- Potential-match algorithm.
- Match display.
- Report history.
- Report status management.
- Basic in-app notifications.
- Documentation and testing.

## Priority 2 – Important Enhancements

Implement after the MVP is stable:

- Interactive map with nearby listings.
- Contact requests and approval.
- Advanced filters.
- Profile image and profile management.
- Abuse reporting and basic administration.
- Push notifications.

## Priority 3 – Optional Enhancements

These are not required for the first submission:

- AI-based image similarity.
- Breed recognition using computer vision.
- Real-time chat.
- Advanced recommendation algorithms.
- Analytics dashboard.
- Multi-language support.

Do not allow optional enhancements to delay the completion of mandatory features.

---

# 14. Definition of Done

The project will be considered complete only when:

- The Flutter application runs on an Android device or emulator.
- The FastAPI backend runs successfully.
- PostgreSQL stores actual application data.
- Authentication works.
- Users can submit lost and found pet reports.
- Images are uploaded to persistent storage.
- Location information is captured and saved.
- Users can search and browse real reports.
- The matching algorithm produces explainable recommendations.
- Match results are persisted in the database.
- Users can manage their own reports.
- In-app notifications work.
- The complete lost-pet-to-found-pet workflow works.
- Backend and frontend have been integrated and tested.
- Setup instructions are sufficient for another developer to run the application.
- Documentation and screenshots are included.
- No mandatory functionality depends on hardcoded sample data.

---

# 15. Instructions to the Coding Agent

You are responsible for implementing the complete PawFinder application according to this specification.

Follow these instructions strictly:

1. Inspect the existing repository before making changes.
2. If no implementation exists, create the project structure from scratch.
3. Implement the Flutter frontend and FastAPI backend as separate applications.
4. Use PostgreSQL as the persistent database.
5. Integrate Supabase Storage for pet photographs.
6. Implement actual API communication between Flutter and FastAPI.
7. Do not substitute backend operations with local mock data.
8. Do not use hardcoded report listings as the primary application data source.
9. Do not leave placeholder buttons or non-functional navigation.
10. Implement authentication and authorization properly.
11. Implement the matching algorithm as backend business logic.
12. Ensure that users can only modify their own reports.
13. Handle loading, success, empty and error states.
14. Maintain a consistent mobile UI.
15. Include database migrations and sample seed data for development.
16. Write tests for the critical backend operations.
17. Keep the code modular and maintainable.
18. Document all setup and execution steps.
19. Do not silently omit requirements. Document any limitations.
20. Do not claim completion until the application has been built, integrated and tested.

### Implementation strategy

Build the application in the following sequence:

**Phase 1:** Project setup, database schema, authentication and backend foundation.

**Phase 2:** Flutter UI, navigation, authentication and API integration.

**Phase 3:** Lost and found report creation, editing, image uploads and discovery.

**Phase 4:** Location-based search and automated matching.

**Phase 5:** Contact requests, notifications and report management.

**Phase 6:** Testing, bug fixing, documentation and final Android build.

After each phase:
- Verify that the implementation runs.
- Test the functionality.
- Fix integration errors.
- Update the README.
- Report completed and remaining requirements.

### Final deliverables

The final repository must contain:

- Complete Flutter source code.
- Complete FastAPI source code.
- Database models and migrations.
- API documentation.
- Environment example files.
- Automated tests.
- README with setup instructions.
- Academic project documentation.
- Screenshots of the working application.

**Final objective:** Deliver a fully integrated, functional and demonstrable PawFinder mobile application that satisfies the CPAD mini-project requirements, rather than a frontend-only prototype.