import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'myKey',
        channelName: 'Pomodoro Alert',
        channelDescription: 'Channel for pomodoro alerts',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: true,
        criticalAlerts: true,
      )
    ],
    debug: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro with Notifications',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await requestNotificationPermission();
    await fetchAndScheduleAlarms();
  }

  Future<void> requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> scheduleAlarmNotification(DateTime scheduledTime) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: scheduledTime.millisecondsSinceEpoch.remainder(100000),
        channelKey: 'myKey',
        title: 'Pomodoro Time!',
        body: 'Your scheduled pomodoro session is finished!',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduledTime.toLocal(), // Ensure we're using local time
        allowWhileIdle: true,
      ),
    );
  }

  Future<void> addAlarmToFirestore(DateTime dateTime) async {
    await FirebaseFirestore.instance.collection('alarms').add({
      'time': dateTime.toUtc().toIso8601String(), // Store as UTC
    });
  }

  Future<void> fetchAndScheduleAlarms() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('alarms').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timeString = data['time'] as String;
        final time = DateTime.parse(timeString).toLocal(); // Convert to local time

        print('Retrieved alarm from Firestore: $time');
        await scheduleAlarmNotification(time);
      }
    } catch (e) {
      print('Error fetching alarms: $e');
    }
  }

  void _scheduleAlarm() async {
    if (_selectedDateTime != null) {
      try {
        await addAlarmToFirestore(_selectedDateTime!);
        await scheduleAlarmNotification(_selectedDateTime!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pomodoro is Scheduled')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error scheduling alarm: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select the time')),
      );
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      final now = DateTime.now();
      final selected = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      final finalDateTime = selected.isBefore(now)
          ? selected.add(const Duration(days: 1))
          : selected;

      setState(() {
        _selectedDateTime = finalDateTime;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⏰ Time set for ${DateFormat('dd-MM-yyyy HH:mm').format(finalDateTime)}')),
      );
    }
  }

  void _sendTestNotification() {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 999,
        channelKey: 'myKey',
        title: 'Test Notification',
        body: 'This is a test to ensure notifications are working!',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBE9E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBF360C),
        title: const Text('Pomodoro Timer', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(Icons.access_time, size: 60, color: Colors.deepOrange),
                      const SizedBox(height: 16),
                      Text(
                        _selectedDateTime == null
                            ? 'No time selected'
                            : 'Scheduled for:\n${DateFormat('dd-MM-yyyy HH:mm').format(_selectedDateTime!)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.timer),
                        label: const Text('Pick Time', style: TextStyle(color: Colors.white)),
                        onPressed: _pickTime,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE64A19),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _scheduleAlarm,
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text('START SESSION', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _sendTestNotification,
                icon: const Icon(Icons.notifications_active, color: Colors.white),
                label: const Text('Send Test Notification', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}