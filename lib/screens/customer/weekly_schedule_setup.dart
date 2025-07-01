import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import '../automation/add_event_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_event.dart';

class WeeklyScheduleSetupScreen extends StatefulWidget {
  @override
  _WeeklyScheduleSetupScreenState createState() => _WeeklyScheduleSetupScreenState();
}

class _WeeklyScheduleSetupScreenState extends State<WeeklyScheduleSetupScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<UserEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('userId', isEqualTo: user.uid)
        .get();
    final events = snapshot.docs.map((doc) => UserEvent.fromMap(doc.data())).toList();
    setState(() {
      _events.clear();
      for (var event in events) {
        final key = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
        if (_events[key] == null) {
          _events[key] = [];
        }
        _events[key]!.add(event);
      }
    });
  }

  List<UserEvent> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  Future<void> _addEventToFirestore(Map<String, dynamic> eventData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final id = FirebaseFirestore.instance.collection('events').doc().id;
    final userEvent = UserEvent(
      id: id,
      userId: user.uid,
      title: eventData['title'] ?? 'Untitled Event',
      startTime: DateTime(
        eventData['date'].year,
        eventData['date'].month,
        eventData['date'].day,
        eventData['startTime'].hour,
        eventData['startTime'].minute,
      ),
      endTime: DateTime(
        eventData['date'].year,
        eventData['date'].month,
        eventData['date'].day,
        eventData['endTime'].hour,
        eventData['endTime'].minute,
      ),
      isGoogleEvent: false,
      googleEventId: null,
      location: eventData['location'],
    );
    await FirebaseFirestore.instance.collection('events').doc(id).set(userEvent.toMap());
    // Add to local map and update UI
    setState(() {
      final key = DateTime(userEvent.startTime.year, userEvent.startTime.month, userEvent.startTime.day);
      if (_events[key] == null) {
        _events[key] = [];
      }
      _events[key]!.add(userEvent);
    });
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEventsForDay(_selectedDay!);
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Management'),
        backgroundColor: AppColors.primary,
        leading: BackButton(),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                _focusedDay = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(color: Colors.grey),
              defaultTextStyle: TextStyle(color: AppColors.textDark),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: AppTextStyles.subHeader.copyWith(color: Colors.white),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final text = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][day.weekday % 7];
                return Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: day.weekday == DateTime.sunday ? Colors.red : AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            eventLoader: _getEventsForDay,
          ),
          Expanded(
            child: events.isEmpty
                ? ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      SizedBox(height: 48),
                      Icon(Icons.event_busy, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          'No events scheduled for ${_selectedDay != null ? _selectedDay!.toLocal().toString().split(' ')[0] : ''}',
                          style: AppTextStyles.body,
                        ),
                      ),
                      SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            final eventData = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEventForm(initialDate: _selectedDay),
                              ),
                            );
                            if (eventData != null) {
                              await _addEventToFirestore(eventData);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('+ Add Event'),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ...events.map((e) => ListTile(
                            leading: Icon(Icons.event, color: AppColors.primary),
                            title: Text(e.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_formatTime(e.startTime)} - ${_formatTime(e.endTime)}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                if (e.location != null && e.location!.isNotEmpty)
                                  Text(
                                    e.location!,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                              ],
                            ),
                            onTap: () async {
                              final eventData = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEventForm(
                                    initialDate: e.startTime,
                                    initialTitle: e.title,
                                    initialLocation: e.location,
                                    initialStartTime: e.startTime,
                                    initialEndTime: e.endTime,
                                  ),
                                ),
                              );
                              if (eventData == 'delete') {
                                await FirebaseFirestore.instance.collection('events').doc(e.id).delete();
                                setState(() {
                                  final key = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
                                  _events[key]?.removeWhere((ev) => ev.id == e.id);
                                });
                              } else if (eventData != null) {
                                final updatedEvent = UserEvent(
                                  id: e.id,
                                  userId: e.userId,
                                  title: eventData['title'] ?? e.title,
                                  startTime: DateTime(
                                    eventData['date'].year,
                                    eventData['date'].month,
                                    eventData['date'].day,
                                    eventData['startTime'].hour,
                                    eventData['startTime'].minute,
                                  ),
                                  endTime: DateTime(
                                    eventData['date'].year,
                                    eventData['date'].month,
                                    eventData['date'].day,
                                    eventData['endTime'].hour,
                                    eventData['endTime'].minute,
                                  ),
                                  isGoogleEvent: false,
                                  googleEventId: null,
                                  location: eventData['location'],
                                );
                                await FirebaseFirestore.instance.collection('events').doc(e.id).set(updatedEvent.toMap());
                                setState(() {
                                  final oldKey = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
                                  _events[oldKey]?.removeWhere((ev) => ev.id == e.id);
                                  final newKey = DateTime(updatedEvent.startTime.year, updatedEvent.startTime.month, updatedEvent.startTime.day);
                                  if (_events[newKey] == null) _events[newKey] = [];
                                  _events[newKey]!.add(updatedEvent);
                                });
                              }
                            },
                          )),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          final eventData = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEventForm(initialDate: _selectedDay),
                            ),
                          );
                          if (eventData != null) {
                            await _addEventToFirestore(eventData);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('+ Add Event'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
} 