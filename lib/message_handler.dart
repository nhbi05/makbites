import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessagingHandler extends StatefulWidget {
  final Widget child;
  const MessagingHandler({required this.child, Key? key}) : super(key: key);

  @override
  _MessagingHandlerState createState() => _MessagingHandlerState();
}

class _MessagingHandlerState extends State<MessagingHandler> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    requestPermission();
    getToken();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message in the foreground!');
      // TODO: You can show a local notification here if you want
    });
  }

  void requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
  }

  void getToken() async {
    String? token = await _messaging.getToken();
    print("Firebase Messaging Token: $token");

    if (token != null) {
      await saveTokenToFirestore(token);
    }
  }

  Future<void> saveTokenToFirestore(String token) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "unknown";

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'deviceToken': token,
      });
      print("Token saved to Firestore for user $userId");
    } catch (e) {
      print("Error saving token to Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
