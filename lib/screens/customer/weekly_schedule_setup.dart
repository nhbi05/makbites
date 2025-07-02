import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import '../automation/add_event_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_event.dart';
import 'place_order_screen.dart';

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

  /// Returns a map of meal name to optimal DateTime for the selected day
  Map<String, DateTime?> getOptimalMealTimes(List<UserEvent> events) {
    // Define meal windows (updated)
    final mealWindows = {
      'Breakfast': [TimeOfDay(hour: 7, minute: 0), TimeOfDay(hour: 11, minute: 0)],
      'Lunch': [TimeOfDay(hour: 12, minute: 0), TimeOfDay(hour: 17, minute: 0)],
      'Supper': [TimeOfDay(hour: 18, minute: 0), TimeOfDay(hour: 23, minute: 0)],
    };
    // Sort events by start time
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    // Build free slots
    List<List<DateTime>> freeSlots = [];
    final day = _selectedDay!;
    DateTime dayStart = DateTime(day.year, day.month, day.day, 0, 0);
    DateTime dayEnd = DateTime(day.year, day.month, day.day, 23, 59);
    DateTime prevEnd = dayStart;
    for (final event in events) {
      if (event.startTime.isAfter(prevEnd)) {
        freeSlots.add([prevEnd, event.startTime]);
      }
      prevEnd = event.endTime.isAfter(prevEnd) ? event.endTime : prevEnd;
    }
    if (prevEnd.isBefore(dayEnd)) {
      freeSlots.add([prevEnd, dayEnd]);
    }
    // For each meal, find the largest free slot within the window
    Map<String, DateTime?> mealTimes = {};
    mealWindows.forEach((meal, window) {
      final windowStart = DateTime(day.year, day.month, day.day, window[0].hour, window[0].minute);
      final windowEnd = DateTime(day.year, day.month, day.day, window[1].hour, window[1].minute);
      List<List<DateTime>> slotsInWindow = freeSlots
        .map((slot) {
          final slotStart = slot[0].isBefore(windowStart) ? windowStart : slot[0];
          final slotEnd = slot[1].isAfter(windowEnd) ? windowEnd : slot[1];
          return [slotStart, slotEnd];
        })
        .where((slot) => slot[1].isAfter(slot[0]))
        .toList();
      if (slotsInWindow.isEmpty) {
        mealTimes[meal] = null;
      } else {
        // Pick the largest slot, suggest its start time (or middle)
        slotsInWindow.sort((a, b) => (b[1].difference(b[0]).inMinutes - a[1].difference(a[0]).inMinutes));
        final bestSlot = slotsInWindow.first;
        // Suggest the middle of the slot
        final suggested = bestSlot[0].add(bestSlot[1].difference(bestSlot[0]) ~/ 2);
        mealTimes[meal] = suggested;
      }
    });
    return mealTimes;
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
            calendarFormat: CalendarFormat.week,
            availableCalendarFormats: const {CalendarFormat.week: 'Week'},
            startingDayOfWeek: StartingDayOfWeek.monday,
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
                final text = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1];
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
          // Meal suggestion UI and event list in a scrollable ListView
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 0),
              children: [
                Builder(
                  builder: (context) {
                    final mealTimes = getOptimalMealTimes(events);
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      color: AppColors.secondary,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Optimal Meal Times', style: AppTextStyles.subHeader),
                            SizedBox(height: 8),
                            ...mealTimes.entries.map((entry) {
                              final meal = entry.key;
                              final time = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.restaurant, color: AppColors.primary, size: 20),
                                    SizedBox(width: 8),
                                    Text('$meal:', style: AppTextStyles.body),
                                    SizedBox(width: 8),
                                    Text(
                                      time != null ? _formatTime(time) : 'No free slot',
                                      style: AppTextStyles.body.copyWith(
                                        color: time != null ? AppColors.success : AppColors.warning,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ...(
                  events.isEmpty
                    ? [
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
                      ]
                    : events.map((e) => ListTile(
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
                      )).toList()
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final events = _getEventsForDay(_selectedDay!);
                  final mealTimes = getOptimalMealTimes(events);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaceOrderScreen(
                        initialDate: _selectedDay!,
                        initialOptimalMealTimes: mealTimes,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.shopping_cart_checkout, color: AppColors.white),
                label: Text('Place Order', style: AppTextStyles.button),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: AppColors.white),
        tooltip: 'Add Event',
      ),
    );
  }
} 