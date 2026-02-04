import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/subject_stats.dart';
import 'attendance_repository.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print("Background Service: Starting Attendance Check..."); // Debug log

      // 1. Initialize Storage
      const storage = FlutterSecureStorage();
      final String? cookie = await storage.read(key: 'session_cookie');

      if (cookie == null) {
        print("Background Service: No session cookie found. Aborting.");
        return Future.value(true);
      }

      // 2. Initialize Repository
      final repository = AttendanceRepository();

      // 3. Fetch New Data
      // Note: fetchAttendance might throw if session is expired
      Map<String, dynamic> result;
      try {
        result = await repository.fetchAttendance(cookie);
      } catch (e) {
        print("Background Service: Fetch failed (likely session expired): $e");
        await _showNotification("Session Expired",
            "Please open the app to login and resume tracking.");
        return Future.value(true);
      }

      final Map<String, SubjectStats> newStatsMap =
          result['stats'] as Map<String, SubjectStats>;
      final List<SubjectStats> newSubjects = newStatsMap.values.toList();

      // 4. Load Cached Data
      final String? cachedJson =
          await storage.read(key: 'cached_attendance_data');
      List<SubjectStats> oldSubjects = [];
      if (cachedJson != null) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        oldSubjects = decoded
            .map((e) => SubjectStats.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // 5. Compare & Notify
      if (oldSubjects.isNotEmpty) {
        final Map<String, SubjectStats> oldMap = {
          for (var s in oldSubjects) s.code: s
        };

        for (var newSub in newSubjects) {
          if (oldMap.containsKey(newSub.code)) {
            final oldSub = oldMap[newSub.code]!;

            // Calculate 'Real' Absents (Absent - Duty Leave)
            int oldRealAbsents =
                (oldSub.blueAbsents - oldSub.greenDutyLeaves).clamp(0, 1000);
            int newRealAbsents =
                (newSub.blueAbsents - newSub.greenDutyLeaves).clamp(0, 1000);

            if (newRealAbsents > oldRealAbsents) {
              int diff = newRealAbsents - oldRealAbsents;
              await _showNotification(
                "New Absent Marked!",
                "You have been marked absent for $diff hour(s) in ${newSub.name}.",
              );
            }
          }
        }
      } else {
        print(
            "Background Service: No old data to compare. Saving first snapshot.");
      }

      // 6. Update Cache
      // Only update if we successfully fetched.
      // This ensures we always compare against the most recent valid state.
      final String newJson =
          jsonEncode(newSubjects.map((e) => e.toJson()).toList());
      await storage.write(key: 'cached_attendance_data', value: newJson);

      print("Background Service: Check Complete.");
      return Future.value(true);
    } catch (e) {
      print("Background Service: Generic Error: $e");
      return Future.value(false); // Retry?
    }
  });
}

// Helper to show notification
Future<void> _showNotification(String title, String body) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // Verify icon name

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'attendance_alert_channel', // id
    'Attendance Alerts', // name
    channelDescription: 'Notifications for new attendance entries',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecond, // unique id
    title,
    body,
    platformChannelSpecifics,
  );
}
