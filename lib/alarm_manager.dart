import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';

class AlarmManager {
  static Future<void> setAlarm(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin, int id, int intervalDays, TimeOfDay timeOfDay, String sound) async {
    tz.initializeTimeZones();
    var androidDetails = AndroidNotificationDetails(
      'alarm_notif_$id',
      '알람 $id',
      channelDescription: '알람 채널 $id',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(sound.split('/').last.split('.').first),
      playSound: true,
      enableVibration: true,
      additionalFlags: Int32List.fromList(<int>[4]), // 4: FLAG_INSISTENT
    );
    var iosDetails = IOSNotificationDetails(
      sound: sound.split('/').last,
    );
    var generalNotificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    var now = tz.TZDateTime.now(tz.local);
    var firstNotificationDateTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    if (firstNotificationDateTime.isBefore(now)) {
      firstNotificationDateTime = firstNotificationDateTime.add(Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      '반복 알람 $id',
      '알람이 울립니다',
      firstNotificationDateTime,
      generalNotificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 이후 알람
    for (int i = 1; i <= 365; i++) {
      var nextNotificationDateTime = firstNotificationDateTime.add(Duration(days: i * intervalDays));
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id + i * 1000,
        '반복 알람 $id',
        '알람이 울립니다',
        nextNotificationDateTime,
        generalNotificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> cancelAlarm(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin, int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    for (int i = 1; i <= 365; i++) {
      await flutterLocalNotificationsPlugin.cancel(id + i * 1000);
    }
  }
}
