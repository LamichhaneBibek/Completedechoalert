# EchoAlert

**One Tap. Everyone Safe.**

EchoAlert is a Flutter-based emergency alert app that lets you instantly notify your trusted contacts and nearby users when you're in danger. Press the SOS button, choose your emergency type, and your location and alert are broadcast in real time.

---

## Features

- **One-tap SOS** — triggers an emergency alert with your live GPS location
- **Emergency categories** — Fire, Medical, Theft, or Other
- **Trusted contacts** — add contacts by name, phone number, and email; call them directly from the app
- **Nearest-user alerts** — uses the Haversine formula to find registered app users within 5 km and shows them on a live map
- **Push notifications** — FCM-powered alerts delivered even when the app is in the background
- **Emergency hotlines** — quick-dial Nepal emergency numbers (Police 100, Fire 101, Ambulance 102, Child Helpline 104, Women Helpline 1145)
- **Alert history** — browse past SOS events
- **Location permission flow** — guided in-app banner to enable GPS so every alert includes your position
- **Secure auth** — Firebase email/password authentication with Firestore user profiles

---

## Screenshots
<div style="display: flex;">
  <img src="./assets/logo.png" alt="Description" width="200" height="200"/>
<img src="./assets/images/home.jpg" alt="Description" width="200" height="auto"/>
</div>



---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Maps | Google Maps Flutter |
| Location | Geolocator |
| Local notifications | flutter_local_notifications |

---

## Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── screens/
│   ├── splash_screen.dart
│   ├── login.dart
│   ├── signup_screen.dart
│   ├── home_screen.dart
│   ├── contact_screen.dart
│   ├── history_screen.dart
│   ├── profile_screen.dart
│   └── report_screen.dart
├── services/
│   ├── aftersos_screen.dart       # SOS type selection & alert dispatch
│   ├── fcm_service.dart           # FCM init, token save, foreground handler
│   ├── nearest_contacts_service.dart  # Haversine distance & nearby-user lookup
│   ├── receiver.dart
│   └── setting_screen.dart
└── components/
    ├── custom_appbar.dart
    ├── navbar_screen.dart
    ├── drawer.dart
    └── my_list_tile.dart
```

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.8.1`
- A Firebase project with **Authentication**, **Firestore**, and **Cloud Messaging** enabled
- Google Maps API key with **Maps SDK for Android** enabled

### Setup

1. **Clone the repo**
   ```bash
   git clone <your-repo-url>
   cd Completedechoalert
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Download `google-services.json` from your Firebase project and place it in `android/app/`
   - The `lib/firebase_options.dart` file is already generated — replace it if you use a different Firebase project

4. **Add your Google Maps API key**  
   Open `android/app/src/main/AndroidManifest.xml` and set:
   ```xml
   <meta-data
     android:name="com.google.android.geo.API_KEY"
     android:value="YOUR_API_KEY_HERE"/>
   ```

5. **Set Firestore security rules**  
   In Firebase Console → Firestore → Rules:
   ```js
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {

       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;

         match /myContacts/{contactId} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
       }

       match /alerts/{alertId} {
         allow read: if request.auth != null;
         allow create: if request.auth != null;
       }
     }
   }
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

---

## How SOS Works

1. User taps the pulsing SOS button on the home screen
2. Selects the emergency type (Fire / Medical / Theft / Other)
3. App captures the current GPS position
4. An alert document is written to Firestore (`alerts` collection) with name, address, type, and coordinates
5. All subscribers of the `sos_alerts` FCM topic receive a push notification
6. Users within 5 km see a popup with the sender's details and distance
7. The map on the home screen animates to the alert location

---

## Permissions

| Permission | Why |
|---|---|
| `ACCESS_FINE_LOCATION` | Attach GPS coordinates to SOS alerts and find nearby users |
| `INTERNET` | Firebase, FCM, Google Maps |
| `POST_NOTIFICATIONS` | Show incoming SOS push notifications |
| `CALL_PHONE` | Direct-dial trusted contacts and emergency hotlines |

---

## Developer

**Riti Shrestha**
