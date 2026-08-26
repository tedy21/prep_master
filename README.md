# PrepMaster

Flutter app for IELTS and SAT prep, plus college application guides.

## Features

- Daily practice sessions
- Full mock tests (IELTS / SAT)
- College application guides
- Progress tracking (streak, XP, accuracy)

## Architecture

Clean Architecture with BLoC:

- **Presentation** — pages, widgets, BLoCs
- **Domain** — entities, use cases, repository contracts
- **Data** — repositories, remote/local sources, models

## Getting Started

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
  core/           shared utilities, theme, network
  features/
    practice/
    exams/
    college_guides/
    progress/
    home/
```

Each feature uses `data/`, `domain/`, and `presentation/` layers.
