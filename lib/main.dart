import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:js' as js;
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(ReminderApp());
}

class ReminderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminder App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ReminderHomePage(),
    );
  }
}

class ReminderHomePage extends StatefulWidget {
  @override
  _ReminderHomePageState createState() => _ReminderHomePageState();
}

class _ReminderHomePageState extends State<ReminderHomePage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AudioPlayer audioPlayer = AudioPlayer();
  String _selectedDay = 'Monday';
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedActivity = 'Wake up';

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();

    var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
      if (notificationResponse.payload != null) {
        _playAudio();
      }
    });

    // Request permission for web notifications
    if (isWeb) {
      js.context.callMethod('eval', [
        """
        Notification.requestPermission().then(function(permission) {
          console.log('Permission:', permission);
        });
        """
      ]);
    }
  }

  bool get isWeb => identical(0, 0.0);

  Future<void> _scheduleNotification() async {
    final now = DateTime.now();
    final nextReminder = DateTime(
      now.year,
      now.month,
      now.day + _calculateDaysUntilNext(_selectedDay),
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (isWeb) {
      // Schedule web notification
      final delay = nextReminder.difference(DateTime.now()).inMilliseconds;
      js.context.callMethod('setTimeout', [
        () {
          js.context.callMethod('eval', [
            """
            new Notification('Reminder', {body: '$_selectedActivity'});
            """
          ]);
          _playAudio();
        },
        delay
      ]);
    } else {
      // Schedule mobile notification
      final tz.TZDateTime scheduledNotificationDateTime =
          tz.TZDateTime.from(nextReminder, tz.local);
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id',
        'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );
      var iOSPlatformChannelSpecifics = DarwinNotificationDetails();
      var platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Reminder',
        _selectedActivity,
        scheduledNotificationDateTime,
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'Reminder'
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder successfully set'),
      ),
    );
  }

  int _calculateDaysUntilNext(String day) {
    int today = DateTime.now().weekday;
    int targetDay = _dayOfWeekToInt(day);
    if (targetDay >= today) {
      return targetDay - today;
    } else {
      return 7 - (today - targetDay);
    }
  }

  int _dayOfWeekToInt(String day) {
    switch (day) {
      case 'Monday':
        return 1;
      case 'Tuesday':
        return 2;
      case 'Wednesday':
        return 3;
      case 'Thursday':
        return 4;
      case 'Friday':
        return 5;
      case 'Saturday':
        return 6;
      case 'Sunday':
        return 7;
      default:
        return 1;
    }
  }

  void _playAudio() async {
    final player = AudioPlayer();
    await player.play('audio/notification_sound.mp3'); // The path should be relative to the assets folder
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 32.0),
                Text(
                  'Select Day:',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8.0),
                DropdownButton<String>(
                  value: _selectedDay,
                  dropdownColor: Colors.blue,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDay = newValue!;
                    });
                  },
                  items: <String>[
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Choose Time:',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (picked != null && picked != _selectedTime) {
                      setState(() {
                        _selectedTime = picked;
                      });
                    }
                  },
                  child: Text('${_selectedTime.format(context)}'),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Select Activity:',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8.0),
                DropdownButton<String>(
                  value: _selectedActivity,
                  dropdownColor: Colors.blue,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedActivity = newValue!;
                    });
                  },
                  items: <String>[
                    'Wake up',
                    'Go to gym',
                    'Breakfast',
                    'Meetings',
                    'Lunch',
                    'Quick nap',
                    'Go to library',
                    'Dinner',
                    'Go to sleep'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.0),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 15.0),
                    ),
                    onPressed: _scheduleNotification,
                    child: Text('Set Reminder'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
