*This is a submission for the Mobile Programming's Assignment to use Awesome Notifications with Firebase*

## What I Built
I developed a Flutter-based Pomodoro notification app that integrates local notifications using the [`awesome_notifications`](https://pub.dev/packages/awesome_notifications) package and uses Firebase Firestore to persist scheduled timer alarms.

This app allows users to:
- Pick a specific time for their Pomodoro session.
- Store the scheduled time in Firebase.
- Receive a local notification when the Pomodoro session ends.
- View and manage all alarms stored in Firestore.

## Features
- Schedule Pomodoro sessions for any time using a built-in time picker.
- Receive local notifications at the scheduled time using Awesome Notifications.
- Save and retrieve alarms from Firebase Firestore (stored in UTC).
- Automatically reschedules all stored alarms upon app startup.
- Send a test notification to verify that everything works.
  
### Installation & Setup
```bash
git clone https://github.com/zelvann/pomodoro-notification.git
cd pomodoro-notification
```
Then install dependencies,
```bash
flutter pub get
```
After that, run the app
```bash
flutter run
```
