---
name: Siyaphila MVP Architecture
description: Key architectural decisions and setup for the Siyaphila AI Chronic Adherence Platform MVP build
type: project
---

MVP build completed June 2026 for Harvard HSIL & UCT Hackathon.

**Color palette**: Deep Navy #1E3A5F (primary) + Emerald #10B981 (secondary) + White #F8FAFC (background). All defined in `lib/theme.dart` as `AppTheme.primary/secondary`.

**Backend**: `backend/` folder, FastAPI + SQLite. Run with `cd backend && uvicorn main:app --reload`. API docs at http://localhost:8000/docs. Auth is JWT (python-jose + bcrypt). Tables: users, patients, medications, dose_events, risk_scores.

**Auth flow**: `lib/services/auth_service.dart` uses `flutter_secure_storage` for JWT token persistence. `MedisyncApp` in `main.dart` holds a `ValueNotifier<_AuthStatus>` that gates the entire app. Logout is triggered via `MedisyncApp.of(context).onLogout()`.

**Onboarding**: 3-step flow (language → profile → conditions) in `lib/screens/onboarding_screen.dart`. After completing, calls `AuthService().setOnboarded()` then `onComplete()` callback.

**Flutter base URL**: `http://10.0.2.2:8000` (Android emulator → localhost) in `lib/services/api_service.dart`. Change to actual IP for physical device testing.

**Why:** Harvard HSIL & UCT Hackathon MVP. Patient-facing adherence app with gamification + backend risk flagging for clinicians.
**How to apply:** When modifying auth flow or onboarding, check that `_AuthStatus` enum in main.dart and `MedisyncAppState` transitions are correct.
