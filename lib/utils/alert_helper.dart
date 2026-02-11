import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:background_sms/background_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'preferences_helper.dart';

class AlertHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  static Future<List<String>> getSelectedSoundsList() async {
    return await PreferencesHelper.getSelectedSounds();
  }

  static final Map<String, DateTime> _lastAlertTimes = {};

  static Future<void> triggerAlert(String soundLabel) async {
    // 0. Rate Limiting: Check if we alerted recently for this sound
    final now = DateTime.now();
    int cooldown = 30; // default 30s cooldown to prevent spam
    if (soundLabel == 'Fire alarm' || soundLabel == 'Siren') cooldown = 10;
    
    if (_lastAlertTimes.containsKey(soundLabel)) {
      final lastAlert = _lastAlertTimes[soundLabel]!;
      if (now.difference(lastAlert).inSeconds < cooldown) {
        print('Rate limiting alert for $soundLabel. Cooldown: ${cooldown}s');
        return;
      }
    }
    
    // Update last alert time
    _lastAlertTimes[soundLabel] = now;

    // 1. Check Preferences for filtering
    final selectedSounds = await PreferencesHelper.getSelectedSounds();
    if (!selectedSounds.contains(soundLabel)) {
      print('Ignoring alert for $soundLabel: Not selected in settings.');
      return;
    }

    // 2. High Priority Notification
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'silent_guard_alerts',
      'Silent Guard Alerts',
      channelDescription: 'Notifications for detected sounds',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      fullScreenIntent: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: 'Sound Detected: $soundLabel',
      body: 'Silent Guard detected: $soundLabel',
      notificationDetails: platformChannelSpecifics,
    );

    // 3. Vibration Pattern
    if (await Vibration.hasVibrator() ?? false) {
       Vibration.vibrate(pattern: [0, 500, 200, 500]); 
    }

    // 4. Send SMS
    final emergencyNumber = await PreferencesHelper.getEmergencyNumber();
    print('Checking SMS readiness: Num=$emergencyNumber');
    
    if (emergencyNumber != null && emergencyNumber.isNotEmpty) {
      // In some background isolates, Permission checks can be unreliable.
      // We try to send and catch errors if permission is truly missing.
      try {
        print('Attempting to send background SMS to $emergencyNumber...');
        final result = await BackgroundSms.sendMessage(
             phoneNumber: emergencyNumber, 
             message: 'Silent Guard Alert: $soundLabel detected nearby!'
        );
        print('SMS Result: $result');
      } catch (e) {
        print('CRITICAL: Failed to send SMS: $e');
      }
    } else {
      print('SMS Aborted: No emergency number found in preferences.');
    }
  }
  static Future<void> sendTestSMS() async {
    final emergencyNumber = await PreferencesHelper.getEmergencyNumber();
    if (emergencyNumber != null && emergencyNumber.isNotEmpty) {
      if (await Permission.sms.request().isGranted) {
        print("Sending Test SMS to $emergencyNumber...");
        var result = await BackgroundSms.sendMessage(
             phoneNumber: emergencyNumber, 
             message: 'Silent Guard Test: This IS A TEST ALERT verifying SMS functionality.'
        );
        if (result == SmsStatus.sent) {
            print("Test SMS Sent Successfully!");
        } else {
            print("Test SMS Failed: $result");
        }
      } else {
        print("SMS Permission Denied for Test");
      }
    } else {
      print("No Emergency Number Set");
    }
  }
}
