import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'alarm_manager.dart';

class AlarmInfo {
  int id;
  String repeatInterval;
  TimeOfDay timeOfDay;
  bool isEnabled;
  String sound;

  AlarmInfo({
    required this.id,
    required this.repeatInterval,
    required this.timeOfDay,
    required this.isEnabled,
    required this.sound,
  });

  factory AlarmInfo.fromJson(Map<String, dynamic> json) {
    return AlarmInfo(
      id: json['id'],
      repeatInterval: json['repeatInterval'],
      timeOfDay: TimeOfDay(hour: json['hour'], minute: json['minute']),
      isEnabled: json['isEnabled'],
      sound: json['sound'] ?? 'assets/sounds/sound1.mp3', // 기본 소리 설정
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repeatInterval': repeatInterval,
      'hour': timeOfDay.hour,
      'minute': timeOfDay.minute,
      'isEnabled': isEnabled,
      'sound': sound,
    };
  }
}

class AlarmPage extends StatefulWidget {
  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  List<AlarmInfo> _alarms = [];
  int _nextId = 0;
  final List<String> _sounds = [
    'assets/sounds/sound1.mp3',
    'assets/sounds/sound2.mp3',
    'assets/sounds/sound3.mp3',
    'assets/sounds/sound4.mp3',
    'assets/sounds/sound5.mp3'
  ];

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    _loadAlarms();
  }

  void _loadAlarms() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? alarmsJson = prefs.getString('alarms');
    if (alarmsJson != null) {
      List<dynamic> alarmsList = json.decode(alarmsJson);
      setState(() {
        _alarms = alarmsList.map((alarmJson) => AlarmInfo.fromJson(alarmJson)).toList();
        if (_alarms.isNotEmpty) {
          _nextId = _alarms.map((alarm) => alarm.id).reduce((a, b) => a > b ? a : b) + 1;
        }
      });

      for (var alarm in _alarms) {
        if (alarm.isEnabled) {
          _setAlarm(alarm);
        }
      }
    }
  }

  void _saveAlarms() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String alarmsJson = json.encode(_alarms.map((alarm) => alarm.toJson()).toList());
    await prefs.setString('alarms', alarmsJson);
  }

  void _addAlarm() {
    setState(() {
      _alarms.add(AlarmInfo(
        id: _nextId++,
        repeatInterval: '1일',
        timeOfDay: TimeOfDay.now(),
        isEnabled: true,
        sound: _sounds.first,
      ));
    });
    _saveAlarms();
  }

  void _setAlarm(AlarmInfo alarm) async {
    int intervalDays = _getIntervalInDays(alarm.repeatInterval);
    await AlarmManager.setAlarm(flutterLocalNotificationsPlugin, alarm.id, intervalDays, alarm.timeOfDay, alarm.sound);
    _saveAlarms();
  }

  void _cancelAlarm(int id) async {
    await AlarmManager.cancelAlarm(flutterLocalNotificationsPlugin, id);
    _saveAlarms();
  }

  int _getIntervalInDays(String repeatInterval) {
    switch (repeatInterval) {
      case '1일':
        return 1;
      case '2일':
        return 2;
      case '3일':
        return 3;
      case '4일':
        return 4;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alarm App'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addAlarm,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _alarms.length,
        itemBuilder: (context, index) {
          AlarmInfo alarm = _alarms[index];
          return ListTile(
            title: Text('알람 ${index + 1} - ${alarm.timeOfDay.format(context)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('반복 간격: ${alarm.repeatInterval}'),
                DropdownButton<String>(
                  value: alarm.sound,
                  onChanged: (String? newSound) {
                    setState(() {
                      alarm.sound = newSound!;
                    });
                    _saveAlarms();
                  },
                  items: _sounds.map((String sound) {
                    return DropdownMenuItem<String>(
                      value: sound,
                      child: Text(sound.split('/').last),
                    );
                  }).toList(),
                ),
              ],
            ),
            trailing: Switch(
              value: alarm.isEnabled,
              onChanged: (bool value) {
                setState(() {
                  alarm.isEnabled = value;
                });
                if (alarm.isEnabled) {
                  _setAlarm(alarm);
                } else {
                  _cancelAlarm(alarm.id);
                }
              },
            ),
            onTap: () async {
              TimeOfDay? selectedTime = await showTimePicker(
                context: context,
                initialTime: alarm.timeOfDay,
              );
              if (selectedTime != null) {
                setState(() {
                  alarm.timeOfDay = selectedTime;
                });
                if (alarm.isEnabled) {
                  _setAlarm(alarm);
                }
              }
            },
          );
        },
      ),
    );
  }
}
