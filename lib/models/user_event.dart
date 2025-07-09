import 'package:cloud_firestore/cloud_firestore.dart';

class UserEvent {
  final String id;
  final String userId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final bool isGoogleEvent;
  final String? googleEventId;
  final String? location;

  UserEvent({
    required this.id,
    required this.userId,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.isGoogleEvent = false,
    this.googleEventId,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isGoogleEvent': isGoogleEvent,
      'googleEventId': googleEventId,
      'location': location,
    };
  }

  factory UserEvent.fromMap(Map<String, dynamic> map) {
    return UserEvent(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      isGoogleEvent: map['isGoogleEvent'] ?? false,
      googleEventId: map['googleEventId'],
      location: map['location'],
    );
  }
} 