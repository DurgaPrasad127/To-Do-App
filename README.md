# TimeBlock – To-Do & Time Management App

TimeBlock is a Flutter-based productivity app that combines **task management, time blocking, daily planning, calendar tracking, and progress insights** in one place.

The app is designed to help users plan what they need to do and track what they actually completed.

---

## ✨ Features

- 📝 Add and manage tasks
- ⏰ Time-block tasks for specific time periods
- 📅 View tasks by day and calendar
- ✅ Mark tasks as completed
- 📊 Track daily progress
- 📈 View productivity insights
- 🎨 Clean and attractive UI
- 🔄 Track tasks across different days
- ⚙️ Customizable settings

---

## 🛠️ Technologies Used

- **Flutter**
- **Dart**
- **Android SDK**
- **Material Design**
- **Provider** for state management
- **Shared Preferences** for local data storage

---

# 🚀 How to Run the App

## 1. Requirements

Before running the project, install:

- Flutter SDK
- Android Studio
- Android SDK
- Git
- A physical Android phone or Android Emulator

Check your Flutter installation:

```bash
flutter doctor
```

Make sure the Android toolchain is properly configured.

---

## 2. Clone the Repository

Open PowerShell / Terminal and run:

```bash
git clone https://github.com/DurgaPrasad127/To-Do-App.git
```

Go into the project:

```bash
cd To-Do-App
```

---

## 3. Install Dependencies

Run:

```bash
flutter pub get
```

---

# 📱 Run on Your Android Mobile

### Step 1 – Enable Developer Options

On your Android phone:

1. Open **Settings**
2. Go to **About Phone**
3. Find **Build Number**
4. Tap **Build Number 7 times**
5. Developer Options will be enabled

### Step 2 – Enable USB Debugging

Go to:

**Settings → Developer Options → USB Debugging**

Turn it ON.

---

### Step 3 – Connect Your Phone

Connect your Android phone to your computer using a USB cable.

If your phone asks for permission:

> Allow USB debugging

Tap **Allow**.

Also select:

> **File Transfer / Android Auto**

if your phone asks for the USB connection mode.

---

### Step 4 – Check Connected Devices

Run:

```bash
flutter devices
```

You should see your Android phone listed.

For example:

```text
Android Phone • ABC123XYZ • android-arm64 • Android 15
```

---

### Step 5 – Run the App

You can simply run:

```bash
flutter run
```

Flutter will automatically use the connected device.

Alternatively, you can specify a particular device:

```bash
flutter run -d DEVICE_ID
```

For example:

```bash
flutter run -d ABC123XYZ
```

---

## ⚠️ Important Note About Device ID

**Do NOT copy the device ID from this project documentation.**

The device ID is **different for each Android phone**.

For example, my development device had an ID similar to:

```text
d58129577d75
```

Your device will have a different ID.

To find your own device ID, run:

```bash
flutter devices
```

Then use the ID shown for your phone:

```bash
flutter run -d YOUR_DEVICE_ID
```

### Recommended

You usually don't need to specify the device ID at all.

Just use:

```bash
flutter run
```

Flutter will detect the connected device and run the application.

---

# 📦 Build an APK

If you don't want to run the application directly from Flutter, you can generate an Android APK.

Run:

```bash
flutter build apk --release
```

The APK will be generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

You can transfer this APK to your Android phone and install it.

---

# 🔧 Troubleshooting

### Flutter does not detect my phone

Run:

```bash
flutter devices
```

If your phone doesn't appear:

1. Make sure USB debugging is enabled.
2. Unlock your phone.
3. Reconnect the USB cable.
4. Select **File Transfer** mode.
5. Accept the **Allow USB debugging** popup.
6. Try:

```bash
flutter doctor
```

---

### `adb` is not recognized

If PowerShell says:

```text
adb is not recognized
```

you can still use Flutter:

```bash
flutter devices
```

and:

```bash
flutter run
```

Flutter can use the Android SDK tools directly.

---

### Android platform files are missing

If you cloned the project and the Android folder is missing, run:

```bash
flutter create --platforms=android .
```

Then:

```bash
flutter pub get
```

and:

```bash
flutter run
```

---

# 📂 Project Structure

```text
To-Do-App/
│
├── android/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   └── utils/
│   │
│   ├── models/
│   ├── providers/
│   ├── screens/
│   │   ├── calendar/
│   │   ├── insights/
│   │   ├── onboarding/
│   │   ├── settings/
│   │   ├── tasks/
│   │   └── today/
│   │
│   ├── services/
│   ├── widgets/
│   ├── app.dart
│   └── main.dart
│
├── pubspec.yaml
├── pubspec.lock
├── README.md
└── LICENSE
```

---

# 👨‍💻 Author

**Durga Prasad**

GitHub:  
https://github.com/DurgaPrasad127

---

## 📄 License

This project is available under the license included in this repository.
