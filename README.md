# PrepMaster

Flutter app for IELTS and SAT prep, plus college application guides.

Backend: **Firebase** (Auth, Firestore, Storage, Cloud Functions). Quiz content lives in **Firestore**, not in the app binary — update questions without an App Store release.

## Features

- Daily practice sessions (Firestore-backed, cached offline)
- Full mock tests (IELTS / SAT) from Firestore `mock_tests`
- IELTS Reading passages & Listening transcripts
- College application guides
- Progress tracking synced to Firestore

## Firebase project

- Project ID: `prepmaster-tedy21`
- Console: https://console.firebase.google.com/project/prepmaster-tedy21

### One-time console setup

1. Open the console link above.
2. Enable **Authentication** → Email/Password + Anonymous.
3. Enable **Firestore** (production mode; rules in `firestore.rules`).
4. ~~Enable Storage~~ — **not required** (Storage needs Blaze/paid plan).
5. Deploy Firestore rules and indexes (**no Storage needed on free Spark plan**):

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

> **Free tier note:** Firebase Storage requires upgrading to the Blaze plan.
> PrepMaster does **not** use Storage — questions, passages, and transcripts
> are stored in Firestore. Listening audio uses on-device text-to-speech.

6. **Seed quiz content** (required before the app shows curated questions):

```bash
cd functions && npm install
export GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json   # optional if logged in via firebase login
npm run seed
```

The seed script reads `assets/data/quiz_bank.json` and uploads to:

| Collection | Purpose |
|------------|---------|
| `quiz_questions/{id}` | All SAT / IELTS questions (update anytime) |
| `mock_tests/{id}` | Mock test metadata + `questionIds` |
| `content_meta/catalog` | Content version & counts |
| `vocabulary`, `college_guides` | Other curated content |

7. (Optional) Deploy Cloud Functions:

```bash
firebase deploy --only functions
```

### Updating content (no app release)

1. Edit `assets/data/quiz_bank.json` (or add questions in Firebase Console).
2. Re-run `node scripts/seed_firestore.js`.
3. Users get new content on next app launch (cached copies refresh when online).

## Content architecture

```
App launch (online)
  → Firestore quiz_questions / mock_tests   ← primary
  → SharedPreferences cache                 ← offline fallback
  → Trivia APIs                               ← last resort if Firestore empty
```

Questions are **not** bundled in the APK/IPA. Only images/icons ship with the app.

## Architecture

Clean Architecture with BLoC:

- Presentation — pages, widgets, BLoCs
- Domain — entities, use cases, repository contracts
- Data — Firestore + local cache + API fallbacks

## Getting Started

```bash
flutter pub get
# Seed Firestore first (see above), then:
flutter run
```

### Linux: avoid snap Flutter for Android builds

If Gradle fails with `A problem occurred starting process 'command .../snap/flutter/...'`:

1. Use the manual SDK already on your machine (recommended):
   ```bash
   export PATH="$HOME/flutter/flutter_linux_3.29.0-stable/flutter/bin:$PATH"
   ```
   `android/local.properties` should point to:
   `flutter.sdk=/home/ted-g/flutter/flutter_linux_3.29.0-stable/flutter`

2. Or run the setup script:
   ```bash
   ./scripts/setup_flutter_sdk.sh
   ```

3. Then build from the **project root** (not `functions/`):
   ```bash
   cd ~/Documents/arifpay_projects/prep_master
   flutter clean && flutter pub get && flutter run
   ```

Add the `export PATH=...` line to `~/.bashrc` so it persists across terminals.

### Android build: Kotlin daemon / Java error

If mobile debug fails with `Could not connect to Kotlin compile daemon` or
`Cannot run program .../bin/java` but **Chrome works**, that is expected:
web builds do not use Gradle/Kotlin/Java.

This project is configured to use **JDK 21** and in-process Kotlin compilation.
If you still see the error, run once:

```bash
rm -rf ~/.local/share/kotlin/daemon
cd android && ./gradlew --stop && cd ..
flutter config --jdk-dir=/usr/lib/jvm/java-21-openjdk-amd64
flutter clean && flutter pub get && flutter run
```

Install JDK 21 if missing: `sudo apt install openjdk-21-jdk`

## Project Structure

```
lib/
  core/
    data/           FirestoreQuizDataSource
    firebase/       FirebaseService
    network/        API clients (fallback only)
  features/
    practice/
    exams/
    college_guides/
    progress/
    auth/
assets/data/
  quiz_bank.json    Seed source only (not bundled in app)
scripts/
  seed_firestore.js Upload content to Firestore
```
