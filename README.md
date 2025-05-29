# Contact & SMS Backup App

A Flutter application to backup, restore, and manage your contacts and SMS messages with Firebase Cloud integration.

## Features

- Backup contacts and SMS to Firebase Cloud
- Restore contacts and SMS from the cloud to your device
- View, search, and favorite contacts
- View SMS conversations in a modern UI
- Make calls and send SMS directly from the app
- Sync favorites and interaction statistics
- Material 3 design and dark mode support

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Firebase Project](https://console.firebase.google.com/)
- Android device or emulator (SMS/Contacts features require a real device for full functionality)

### Setup

1. **Clone the repository:**
   ```sh
   git clone <your-repo-url>
   cd contact_sms_app
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Configure Firebase:**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective directories.
   - Update `firebase_options.dart` if needed.

4. **Android Permissions:**
   - The app requires permissions for contacts, SMS, phone, and storage.
   - For SMS restore, the app may need to be set as the default SMS app.

5. **Run the app:**
   ```sh
   flutter run
   ```

## Usage

- **Backup:** Use the "Backup & Restore" screen to backup contacts and SMS to the cloud.
- **Restore:** Restore contacts and SMS from the cloud to your device.
- **Contacts:** Browse, search, and favorite contacts. Tap a contact for details, call, or SMS.
- **SMS:** View SMS conversations. Pull to refresh.
- **Favorites:** See your most contacted people and quick actions.

## Notes

- Some features (like writing SMS to device) require the app to be the default SMS app on Android.
- Permissions must be granted for full functionality.
- The app uses local SQLite for favorites and Firebase Realtime Database for cloud backup.

## License

MIT License

---

**Developed with Flutter & Firebase**
