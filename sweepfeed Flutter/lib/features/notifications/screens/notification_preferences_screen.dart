import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  _NotificationPreferencesScreenState createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
    final Map<String, bool> _preferences = {
    'new_sweepstakes': false,
    'high_value': false,
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _preferences['new_sweepstakes'] = prefs.getBool('new_sweepstakes') ?? false;
      _preferences['ending_soon'] = prefs.getBool('ending_soon') ?? false;
    });
  }

  Future<void> _togglePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _preferences[key] = value;
    });
    if(key == 'new_sweepstakes'){
       await prefs.setBool('new_sweepstakes', value);
    }else{
       await prefs.setBool('ending_soon', value);
    }
     // Subscribe/unsubscribe to relevant topics
    if (value) {
      await context.read<NotificationService>().subscribeToTopic(key);
    } else {
      await context.read<NotificationService>().unsubscribeFromTopic(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: ListView(
        children: [
          _buildPreferenceTile(
            'Daily Entry Reminders',
            'Get notified when new sweepstakes are available',
            'new_sweepstakes',
          ),
          _buildPreferenceTile(
            'Ending Soon Alerts',
            'Get notified when sweepstakes are about to end',
            'ending_soon',
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile(String title, String subtitle, String key) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: _preferences[key] ?? false,
      onChanged: (value) => _togglePreference(key, value),
    );
  }
}
