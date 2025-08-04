# SweepFeed Mobile App

A Flutter mobile app for discovering and tracking the best sweepstakes and contests.

## 🚀 Features

- **🎉 Browse Sweepstakes**: Discover active contests and sweepstakes from various trusted sources.
- **🔍 Advanced Filtering**: Filter by prize value, entry method, ending soon, and more.
- **📊 Daily Checklist**: Track daily-entry sweepstakes to maximize your chances.
- **🔔 Notifications**: Get alerts for new high-value sweepstakes and when favorites are ending soon.
- **👤 User Profiles**: Save favorites, track entered contests, and manage preferences.
- **🎮 Gamification**: Earn points for entries, daily streaks, and sharing.
- **💰 Premium Features**: Support the app with subscription options for advanced features.

## 📱 Screenshots

(Screenshots will be added once the app is built)

## 🛠️ Tech Stack

- **Flutter**: Cross-platform UI toolkit for iOS and Android
- **Firebase**: Authentication, Cloud Firestore, Storage, and Analytics
- **Provider/Riverpod**: State management

## 🚧 Project Structure

```
lib/
├── config/               # App-wide configuration
├── core/                 # Core functionality and utilities
│   ├── constants/        # App constants
│   ├── theme/            # Theme data
│   └── utils/            # Helper functions
├── features/             # Feature-based architecture
│   ├── auth/             # Authentication
│   ├── contests/         # Contest listings & details
│   ├── notifications/    # Push notifications
│   ├── profile/          # User profile
│   └── subscription/     # Premium features
└── main.dart             # App entry point
```

## 🧠 Backend Integration

The app integrates with a Firebase backend that includes:

- **Contest Bot**: Python-based system that crawls for new sweepstakes and parses rules
- **Firestore Database**: Stores contest data, user profiles, and preferences
- **Cloud Functions**: Handles notifications, sweepstakes validation, and API integrations

## 📦 Environment Setup

1. Clone this repository
2. Create a `.env` file in the root with the following variables:
   ```
   # Firebase Configuration
   FIREBASE_API_KEY=xxx
   FIREBASE_AUTH_DOMAIN=xxx
   FIREBASE_PROJECT_ID=xxx
   FIREBASE_STORAGE_BUCKET=xxx
   FIREBASE_MESSAGING_SENDER_ID=xxx
   FIREBASE_APP_ID=xxx
   FIREBASE_MEASUREMENT_ID=xxx
   ```
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app on a connected device or simulator

## 📝 License

Copyright © 2024 SweepFeed. All rights reserved.
# flutter-sweepfeed
