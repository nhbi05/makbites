import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddEventForm extends StatefulWidget {
  final void Function(Map<String, dynamic> eventData)? onSave;
  final DateTime? initialDate;
  final String? initialTitle;
  final String? initialLocation;
  final DateTime? initialStartTime;
  final DateTime? initialEndTime;
  const AddEventForm({Key? key, this.onSave, this.initialDate, this.initialTitle, this.initialLocation, this.initialStartTime, this.initialEndTime}) : super(key: key);

  @override
  State<AddEventForm> createState() => _AddEventFormState();
}

class _AddEventFormState extends State<AddEventForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _eventType = 'CLASS';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  bool _isRecurring = false;

  final List<String> _eventTypes = ['CLASS', 'MEETING', 'WORK', 'OTHER'];

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialLocation != null) {
      _locationController.text = widget.initialLocation!;
    }
    if (widget.initialStartTime != null) {
      _startTime = TimeOfDay(hour: widget.initialStartTime!.hour, minute: widget.initialStartTime!.minute);
    }
    if (widget.initialEndTime != null) {
      _endTime = TimeOfDay(hour: widget.initialEndTime!.hour, minute: widget.initialEndTime!.minute);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text((widget.initialTitle != null || widget.initialLocation != null || widget.initialStartTime != null || widget.initialEndTime != null) ? 'Edit Event' : 'Add New Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  prefixIcon: Icon(Icons.text_fields),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _eventType,
                items: _eventTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _eventType = val);
                },
                decoration: const InputDecoration(
                  labelText: 'Event Type',
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat.yMMMMd().format(_selectedDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(isStart: true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(_startTime.format(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(isStart: false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(_endTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Switch(
                    value: _isRecurring,
                    onChanged: (val) => setState(() => _isRecurring = val),
                  ),
                  const SizedBox(width: 8),
                  const Text('Recurring Event'),
                  const SizedBox(width: 8),
                  if (_isRecurring)
                    const Text('Repeat this event weekly', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final eventData = {
                        'title': _titleController.text,
                        'location': _locationController.text,
                        'eventType': _eventType,
                        'date': _selectedDate,
                        'startTime': _startTime,
                        'endTime': _endTime,
                        'description': _descriptionController.text,
                        'isRecurring': _isRecurring,
                      };
                      if (widget.onSave != null) widget.onSave!(eventData);
                      Navigator.of(context).pop(eventData);
                    }
                  },
                  child: const Text('Save Event'),
                ),
              ),
              if (widget.initialTitle != null || widget.initialLocation != null || widget.initialStartTime != null || widget.initialEndTime != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text('Delete Event', style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      Navigator.of(context).pop('delete');
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 