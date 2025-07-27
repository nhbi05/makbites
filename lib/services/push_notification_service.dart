import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize(BuildContext context, String userId) async {
    await _fcm.requestPermission();

    String? token = await _fcm.getToken();
    if (token != null && userId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(message.notification!.title ?? ''),
            content: Text(message.notification!.body ?? ''),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle navigation if needed
    });

    // Handle token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      if (userId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': newToken,
        });
      }
    });
  }
}