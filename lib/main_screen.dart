import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:pushnotifications/new_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  TextEditingController username = TextEditingController();
  TextEditingController title = TextEditingController();
  TextEditingController body = TextEditingController();
  String? mytoken = " ";
  @override
  void initState() {
    super.initState();
    requestPermission();
    getToken();
    initInfo();
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted permission");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("User granted provisional permission");
    } else {
      print("User declined or has not accepted prrmission");
    }
  }

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        mytoken = token;
        print("My token is $mytoken");
      });
    });
  }

  void seveToken(String token) async {
    await FirebaseFirestore.instance.collection("UserTokens").doc("User1").set({
      'token': token,
    });
  }

  initInfo() {
    var androidInitialize =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOSInitialize = const IOSInitializationSettings();
    var initializationsSettings =
        InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    flutterLocalNotificationsPlugin.initialize(initializationsSettings,
        onSelectNotification: (String? payload) async {
      try {
        if (payload != null && payload.isNotEmpty) {
          Navigator.push(context,
              MaterialPageRoute(builder: (BuildContext context) {
            return NewPage(info: payload.toString());
          }));
        } else {}
      } catch (e) {}
      return;
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(".................onMessange.................");
      print(
          "onMessage:${message.notification!.title}/${message.notification?.body}");
      BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
        message.notification!.body.toString(),
        htmlFormatBigText: true,
        contentTitle: message.notification!.title.toString(),
        htmlFormatContentTitle: true,
      );
      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'Food',
        'Food',
        importance: Importance.high,
        styleInformation: bigTextStyleInformation,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification'),
      );
      NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(0, message.notification?.title,
          message.notification?.body, platformChannelSpecifics,
          payload: message.data['body']);
    });
  }

  void sendPushMessage(String token, String body, String title) async {
    try {
      await http.post(
        Uri.parse('http://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'key=AAAAQoFIQL0:APA91bGnLIxdl4imLGYgxEpR7mErS0Lls6E64Zmz7W7fZGRZYC1lK3vTEwMOnasP_-bm8aLBPu8pZGeoOOQbbmi6m1K_VeaLTTb9GGT7dk57PKufh6Dvq0rAbmE8KDrblrri0fpkHbMo',
        },
        body: jsonEncode(
          <String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': body,
              'title': title
            },
            "notification": <String, dynamic>{
              "title": title,
              'body': body,
              "android_channel_id": "food"
            },
            "to": token
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print("error push notification");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: username,
            ),
            TextFormField(
              controller: title,
            ),
            TextFormField(
              controller: body,
            ),
            GestureDetector(
              onTap: () async {
                String name = username.text.trim();
                String titleText = title.text;
                String bodyText = body.text;
                if (name != "") {
                  DocumentSnapshot snap = await FirebaseFirestore.instance
                      .collection("UserTokens")
                      .doc(name)
                      .get();
                  String token = snap['token'];
                  print(token);
                  sendPushMessage(token, titleText, bodyText);
                }
              },
              child: Container(
                margin: const EdgeInsets.all(20),
                height: 40,
                width: 200,
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.redAccent.withOpacity(0.5))
                    ]),
                child: const Center(
                  child: Text("button"),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
