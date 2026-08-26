# PrepMaster

Your pocket-sized exam coach. AI-powered daily practice, personalized study plans, and full-length mock tests for **IELTS** & **SAT**, plus **college application guides** — built with Flutter.

<p align="center">
  <img src="screenshots/home_screen.png" width="250" alt="Home Screen"/>
  <img src="screenshots/quiz_screen.png" width="250" alt="Quiz Screen"/>
  <img src="screenshots/result_screen.png" width="250" alt="Result Screen"/>
</p>

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [State Management](#state-management)
- [Contributing](#contributing)

## Features

### Core Learning

| Feature | Description | Status |
|---------|-------------|--------|
| Daily Practice | Personalized 15–30 min sessions | ✅ scaffold |
| Skill-Based Quizzes | Targeted practice (Algebra, Grammar, etc.) | 🚧 |
| Full Mock Tests | Timed IELTS / SAT simulations | ✅ scaffold |
| Error Log | Track mistakes with explanations | 🚧 |
| Progress Dashboard | Streak, XP, accuracy | ✅ scaffold |
| Vocabulary Builder | Spaced-repetition flashcards | 🚧 |
| College Application Guides | Essays, recs, deadlines, aid, interviews | ✅ scaffold |

### Exam Coverage

| Exam | Sections |
|------|----------|
| IELTS | Listening, Reading, Writing, Speaking |
| SAT | Math, Reading & Writing |
| College Apps | Personal statements, recommendations, FAFSA, timelines |

## Architecture

PrepMaster follows **Clean Architecture** with feature-first folders. Presentation uses **BLoC** (not GetX).

```
┌─────────────────────────────────────────────┐
│  PRESENTATION LAYER                         │
│  • Pages / Widgets                          │
│  • BLoCs (events → states)                  │
├─────────────────────────────────────────────┤
│  DOMAIN LAYER                               │
│  • Entities                                 │
│  • Repository contracts                     │
│  • Use cases (Either<Failure, T>)           │
├─────────────────────────────────────────────┤
│  DATA LAYER                                 │
│  • Repository implementations               │
│  • Remote / Local data sources              │
│  • Models (DTOs)                            │
└─────────────────────────────────────────────┘
```

**Dependency rule:** Presentation → Domain ← Data. Domain has no Flutter/Dio/Hive imports.

## Tech Stack

| Concern | Package |
|---------|---------|
| State | `flutter_bloc`, `equatable` |
| DI | `get_it`, `injectable` |
| Errors | `dartz` (`Either`) |
| Network | `dio`, `connectivity_plus` |
| Storage | `hive`, `shared_preferences` |
| UI | `flutter_screenutil`, `shimmer`, `confetti` |

## Getting Started

```bash
flutter pub get
flutter run
```

Optional code generation (when you add `@injectable` / `@freezed` / Hive adapters):

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Project Structure

```
lib/
├── main.dart                 # bootstrap (Hive + DI)
├── app.dart                  # MaterialApp + theme
├── injection.dart            # get_it registrations
├── core/
│   ├── constants/            # app + API constants
│   ├── error/                # Failures + Exceptions
│   ├── network/              # DioClient, NetworkInfo
│   ├── theme/
│   ├── usecase/
│   ├── utils/
│   └── widgets/
└── features/
    ├── home/                 # shell + bottom nav
    ├── practice/             # daily sessions
    ├── exams/                # IELTS / SAT mocks
    ├── college_guides/       # application guides
    ├── progress/             # streak / XP
    ├── vocabulary/           # (folder ready)
    ├── auth/                 # (folder ready)
    └── settings/             # (folder ready)
```

Each feature (where implemented) follows:

```
feature/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

## State Management

1. UI dispatches a **BLoC event**
2. BLoC calls a **use case**
3. Use case calls the **repository** contract
4. Repository picks remote vs cache via `NetworkInfo`
5. Result comes back as `Either<Failure, T>` → mapped to a **state**

## Contributing

1. Keep new features under `lib/features/<name>/` with the three layers
2. Domain stays pure Dart (no Flutter UI packages)
3. Register new deps in `lib/injection.dart`

## License

Private / TBD
