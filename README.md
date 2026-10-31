# Patente Italiana B - Driving License Exam Prep 🇮🇹

A modern, offline-first Flutter application designed to help candidates prepare for and pass the Italian Driving License (Patente di Guida B) ministerial theory examination. Features trilingual support (Italian, English, and Urdu with authentic Nastaleeq calligraphy), an intelligent ministerial exam simulator, topic-by-topic drills, error bank review, ministerial tips ("Trucchi"), and an interactive AI Tutor.

---

## 🚀 Key Features

- **Ministerial Exam Simulation**:
  - Faithful to official 2026 Italian Ministry of Transport (Ministero dei Trasporti) exam standards:
    - 30 randomly selected questions across 20 official syllabus topics.
    - Balanced distribution of 13–17 VERO (True) and 13–17 FALSO (False) answers.
    - 20-minute timer with background pause/resume handling.
    - Passing criteria: Maximum 3 errors allowed.
  - Active exam session state recovery (prevents loss of progress on phone calls or accidental app kills).

- **Trilingual Support**:
  - Italian (official exam language).
  - English translations and explanations.
  - Urdu translations with high-legibility **Jameel Noori Nastaleeq** typography.
  - Native Text-to-Speech (TTS) audio narration for Italian and Urdu explanations.

- **Offline-First Quiz Engine**:
  - Complete 7,139-question database bundled in local JSON assets.
  - Heavy JSON parsing offloaded to a background Dart isolate (`Isolate.run`), ensuring 60fps UI performance without frame drops.

- **Smart Error Bank (Banca Errori)**:
  - Automatically captures mistaken questions.
  - Implements spaced repetition: questions are removed only after 2 consecutive correct answers.

- **Ministerial Tricks ("Trucchi Ministeriali")**:
  - Highlights recurring ministerial trap keywords (`esclusivamente`, `soltanto`, `tassativamente`, `mai`, `sempre`) to build candidate intuition.

- **AI Tutor & Instant Chat**:
  - AI-powered explanations for complex road signs and highway code scenarios.
  - Multi-model fallback architecture with configurable endpoints (OpenRouter).

- **Freemium & In-App Purchases**:
  - Integrated via RevenueCat SDK.
  - Pro features: unlimited exams, full ministerial tricks bank, advanced spaced repetition error bank.
  - Secure `--dart-define` configuration with zero secret leakage in client binaries.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: Flutter 3.3.4+ / Dart SDK 3.x
- **State Management**: Provider (`QuizProvider`, `SubscriptionProvider`, `LanguageProvider`, `SettingsProvider`)
- **Local Persistence**: `shared_preferences`
- **Typography & Styling**: `google_fonts` (Outfit, Plus Jakarta Sans, Inter, JetBrains Mono) & Jameel Noori Nastaleeq font
- **Audio / TTS**: `flutter_tts`
- **Monetization**: `purchases_flutter` (RevenueCat)
- **Image Caching**: `cached_network_image` with interactive pinch-to-zoom (`InteractiveViewer`)

---

## 📂 Project Structure

```
lib/
├── main.dart                  # Application entry point, theme init, error guards
├── models/                    # Data models (Question, ExamResult, Topic, GlossaryItem)
├── providers/                 # State management
│   ├── quiz_provider.dart     # Core exam logic, ministerial generator, isolate parser
│   ├── subscription_provider.dart # Freemium state & RevenueCat bridge
│   ├── language_provider.dart # Trilingual locale selector
│   └── settings_provider.dart # User audio & display settings
├── screens/                   # User interface
│   ├── home_screen.dart       # Dashboard, streak tracker, exam launcher
│   ├── exam_simulation_screen.dart # Ministerial exam screen with timer & zoom
│   ├── result_screen.dart     # Pass/fail scorecard with error breakdown
│   ├── topic_quiz_screen.dart # Topic-based practice mode with audio
│   ├── error_review_screen.dart # Error bank with consecutive-success clearance
│   ├── trucchi_screen.dart    # Ministerial trap keywords reference
│   ├── ai_tutor_screen.dart   # Interactive road theory tutor
│   └── premium_paywall_screen.dart # Subscription plans & feature matrix
└── services/                  # Infrastructure & external APIs
    ├── storage_service.dart   # SharedPreferences persistence
    ├── tts_service.dart       # Text-to-speech engine
    ├── revenuecat_service.dart # IAP configuration
    └── openrouter_service.dart # AI tutor API client
```

---

## ⚙️ Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.3.4 or later)
- Android Studio / Xcode for mobile deployment
- macOS, Linux, or Windows development environment

### 2. Clone the Repository
```bash
git clone https://github.com/syedwajahatattari/patente_italiana_app.git
cd patente_italiana_app
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Configuration (Environment Keys)
Sensitive API keys are passed securely at build time using `--dart-define` flags.

Create a `.env` file for local development (copy from `.env.example`):
```bash
cp .env.example .env
```

Or pass them directly when launching Flutter:
```bash
flutter run \
  --dart-define=REVENUECAT_GOOGLE_KEY="your_google_key_here" \
  --dart-define=REVENUECAT_APPLE_KEY="your_apple_key_here" \
  --dart-define=OPENROUTER_API_KEY="your_openrouter_key_here"
```

> **Note**: If keys are not provided, the app will gracefully run in **safe mode** without crashing. Free tiers and offline quizzes work immediately out of the box.

---

## 🧪 Testing

Run all unit tests:
```bash
flutter test
```

### Key Test Suites:
- `test/ministerial_exam_distribution_test.dart`:
  - Verifies that `startMinisterialExam()` produces **exactly 30 unique questions** per exam without duplicates.
  - Validates that the True/False balance strictly conforms to ministerial standards (13–17 VERO, 13–17 FALSO) over 100 test iterations.

---

## 🔒 Security & Privacy

- Secret keys (`.env`) are strictly excluded via `.gitignore` and are **never** bundled in `pubspec.yaml` assets.
- In-app purchases are strictly validated server-side by RevenueCat.
- Offline quiz answers and progress are stored locally on-device in private application storage.

---

## 📄 License
This project is proprietary and confidential. All rights reserved.
