# Techezm Attendance Portal

This repository contains a Flutter application implementing a geofenced and Wi‑Fi
restricted attendance system with separate **Admin** and **Employee** roles. The
app is built with **Flutter 3.22.2**, **Dart 3.4.3**, **Firebase** (Authentication
and Firestore) and **Riverpod** for state management. It targets Android
devices but can be extended to iOS as well.

## Folder structure

```
lib/
  app.dart                 # Root widget configuring themes and Firebase
  main.dart                # Entry point
  models/                  # Plain‑old Dart objects (UserModel, AttendanceRecord, etc.)
  services/                # Abstractions over Firebase, location and Wi‑Fi APIs
    auth_service.dart      # Authentication and user creation
    firestore_service.dart # CRUD operations for Firestore
    location_service.dart  # GPS location retrieval
    wifi_service.dart      # Fetches connected Wi‑Fi name
    attendance_service.dart# Combines location and Wi‑Fi checks to validate attendance
  providers/               # Riverpod providers for services and app state
    auth_provider.dart
    settings_provider.dart
    attendance_provider.dart
  screens/                 # All UI screens grouped by feature
    splash_screen.dart     # Splash with navigation logic
    onboarding_screen.dart # Minimal onboarding
    login_screen.dart      # Admin/employee login
    admin/
      admin_dashboard.dart       # Summary and navigation for admins
      employee_form_screen.dart  # Create employee accounts
      settings_screen.dart       # Configure geofence and Wi‑Fi
      attendance_report_screen.dart # View attendance reports
    employee/
      employee_dashboard.dart    # Main screen for employees
      attendance_history_screen.dart # List past attendances
      profile_screen.dart        # Update name/password
firebase/
  firestore.rules          # Firestore security rules
pubspec.yaml               # Dependency declarations
README.md                  # This file
```

## Connecting the app to Firebase

1. **Create a Firebase project** at <https://console.firebase.google.com/> and
   enable **Email/Password** sign‑in under *Authentication → Sign‑in method*.

2. **Add an Android app** in the Firebase project settings. Use your
   application ID (e.g. `com.example.techezm_attendance_portal`). Download the
   generated `google-services.json` file and place it under
   `android/app/` in your Flutter project.

3. **Initialize FlutterFire**: Install the FlutterFire CLI globally (`dart pub
   global activate flutterfire_cli`) and run:

   ```bash
   flutterfire configure
   ```

   Select your Firebase project and target platforms. This command generates
   `firebase_options.dart` in your `lib/` folder which is automatically used
   by `firebase_core` in this codebase.

4. **Update Android configuration**:

   * In `android/build.gradle`, ensure the Google services classpath is added:

     ```gradle
     dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
     }
     ```

   * In `android/app/build.gradle`, apply the Google services plugin at the
     bottom:

     ```gradle
     apply plugin: 'com.google.gms.google-services'
     ```

   The FlutterFire CLI usually configures these for you.

5. **Set up Android permissions**:

   The geolocator and network_info_plus packages require location and network
   permissions. Add the following lines to `android/app/src/main/AndroidManifest.xml`:

   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   ```

   Starting from Android 10, fine location permission is required to obtain
   Wi‑Fi information【85169722705482†L133-L144】.

6. **Deploy Firestore security rules**:

   Use the Firebase CLI to deploy the provided security rules:

   ```bash
   firebase deploy --only firestore:rules --project <your-project-id>
   ```

   The rules ensure that employees can only access their own attendance
   documents while admins can manage all data.

7. **Create an admin account**:

   You can create an admin user via the Firebase console under
   *Authentication → Users*. After creating an admin user, add a document in
   the `admins` collection with the same UID and fields `name`, `email`,
   `role: 'admin'` and `createdAt` (timestamp). The app checks this collection
   to determine admin privileges.

8. **Run the app**:

   ```bash
   flutter pub get
   flutter run
   ```

## How geofence and Wi‑Fi checks work

The app uses the **geolocator** package to retrieve the current GPS location and
compute the distance to the office geofence. The `distanceBetween` method of
`Geolocator` returns the distance in meters between two coordinates【434270494199287†L638-L651】. If the distance is less than or equal to the
configured radius, the employee is considered inside the allowed area.

The **network_info_plus** package provides the name (SSID) of the currently
connected Wi‑Fi network. Example usage from the package documentation shows
how to obtain the Wi‑Fi name and other properties【85169722705482†L92-L108】. On
Android the OS surrounds the SSID with quotes【85169722705482†L122-L128】; the
`WifiService` in this code removes those quotes before comparing it against the
allowed value. Accessing Wi‑Fi information on Android 10+ requires the
`ACCESS_FINE_LOCATION` permission and enabled location services【85169722705482†L133-L144】.

## Security rules rationale

The Firestore security rules (`firebase/firestore.rules`) restrict access as
follows:

* **Admins** can read/write their own admin document, settings and all
  attendance records. Admin status is determined by the existence of a document
  under `admins/{uid}`.
* **Employees** can read/write only their own user document and attendance
  subcollection. They cannot access other employees’ data. This is enforced by
  matching the authenticated UID to the document path.
* **Settings** can only be read and written by admins. Employees cannot
  discover the geofence coordinates or allowed Wi‑Fi SSID.

These rules follow the pattern shown in Firebase’s documentation for
owner‑based access control where reads and writes are allowed only if
`request.auth.uid == userId`【12960332139597†L1580-L1586】.