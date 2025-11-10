import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState
    extends ConsumerState<ReminderSettingsScreen> {
  bool _dailyReminderEnabled = false;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefsAsync = ref.read(sharedPreferencesProvider);
    if (prefsAsync.hasValue) {
      final prefs = prefsAsync.value!;
      setState(() {
        _dailyReminderEnabled = prefs.getBool('dailyReminderEnabled') ?? false;
        final timeString = prefs.getString('dailyReminderTime');
        if (timeString != null) {
          final timeParts = timeString.split(':');
          _selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefsAsync = ref.read(sharedPreferencesProvider);
    if (!prefsAsync.hasValue) return;
    final prefs = prefsAsync.value!;
    final reminderService = ref.read(reminderServiceProvider);

    await prefs.setBool('dailyReminderEnabled', _dailyReminderEnabled);
    if (_selectedTime != null) {
      await prefs.setString(
        'dailyReminderTime',
        '${_selectedTime!.hour}:${_selectedTime!.minute}',
      );
    }

    // After saving, update the scheduled notification
    if (_dailyReminderEnabled) {
      await reminderService.scheduleDailyReminder(prefs);
    } else {
      await reminderService.cancelDailyReminder(prefs);
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
      _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Reminder Settings'),
        ),
        body: ListView(
          children: [
            SwitchListTile(
              title: const Text('Enable Daily Reminders'),
              subtitle: const Text(
                'Receive one notification per day for all daily sweepstakes.',
              ),
              value: _dailyReminderEnabled,
              onChanged: (value) {
                setState(() {
                  _dailyReminderEnabled = value;
                });
                _saveSettings();
              },
            ),
            ListTile(
              title: const Text('Reminder Time'),
              subtitle: Text(
                _selectedTime?.format(context) ?? 'Not set',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _dailyReminderEnabled ? _pickTime : null,
              enabled: _dailyReminderEnabled,
            ),
          ],
        ),
      );
}
