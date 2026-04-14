# Habit Tracker - Flutter

A cross-platform habit tracking app built with Flutter and Dart. Track daily habits, maintain streaks, and view detailed statistics.

## Features

- **Habit Management**: Create, edit, and delete habits with custom colors and target days
- **Daily Check-ins**: Toggle daily completions with a single tap
- **Streak Tracking**: Automatic consecutive-day streak calculation 🔥
- **Statistics Dashboard**: View current streaks, total check-ins, and achievement badges
- **Swipe to Delete**: Swipe habits to delete with confirmation dialog
- **Material Design 3**: Modern UI following Material You design guidelines
- **Local Storage**: Data persisted using SharedPreferences

## Screens

1. **Habits** - Main screen with habit cards, daily toggle, streak badges, and FAB
2. **New/Edit Habit** - Form with name, description, color picker, and target days selector
3. **Statistics** - Per-habit stats with streaks, totals, and achievement badges

## Tech Stack

- **Flutter** 3.x with **Dart** 3.x
- **Provider** for state management
- **SharedPreferences** for local persistence
- **Material Design 3** components
- **intl** for date formatting
- **uuid** for unique ID generation

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

## Project Structure

```
lib/
├── main.dart                  # App entry point + navigation
├── models/
│   └── habit.dart             # Habit & Completion data models
├── providers/
│   └── habit_provider.dart    # State management + persistence
└── screens/
    ├── habit_list_screen.dart     # Main habit list
    ├── habit_detail_screen.dart   # Create/edit form
    └── stats_screen.dart          # Statistics dashboard
```

## Based On

Port of the [habit-tracker-android](https://github.com/Rybak1234/habit-tracker-android) Kotlin/Android app, maintaining feature parity with a Flutter cross-platform approach.
