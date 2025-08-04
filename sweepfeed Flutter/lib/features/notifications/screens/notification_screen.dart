import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sweepfeed_app/features/notifications/services/notification_service.dart';
import 'package:sweepfeed_app/features/notifications/screens/notification_preferences_screen.dart';

class Notification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  bool isRead;

  Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.data,
    this.isRead = false,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Notification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() async {
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);

    // This would normally fetch from a database or shared preferences
    // For now, we'll use mock data
    setState(() {
      _isLoading = false;
      _notifications = [
        Notification(
          id: '1',
          title: 'New Sweepstakes Added',
          body: 'A new sweepstakes worth \$10,000 has been added!',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          data: {'contestId': '123'},
        ),
        Notification(
          id: '2',
          title: 'Deadline Approaching',
          body: 'The Vacation Giveaway sweepstakes ends tomorrow!',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          data: {'contestId': '456'},
          isRead: true,
        ),
        Notification(
          id: '3',
          title: 'Recommended for You',
          body:
              'Based on your interests, check out the Electronics Sweepstakes',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          data: {'contestId': '789'},
        ),
      ];
    });
  }

  void _markAsRead(String id) {
    setState(() {
      final index =
          _notifications.indexWhere((notification) => notification.id == id);
      if (index != -1) {
        _notifications[index].isRead = true;
      }
    });
    // In a real app, update this in persistent storage via NotificationService
  }

  void _markAsUnread(String id) {
    setState(() {
      final index =
          _notifications.indexWhere((notification) => notification.id == id);
      if (index != -1) {
        _notifications[index].isRead = false;
      }
    });
    // In a real app, update this in persistent storage via NotificationService
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((notification) => notification.id == id);
    });
    // In a real app, remove this from persistent storage via NotificationService
  }

  void _navigateToPreferences() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationPreferencesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToPreferences,
            tooltip: 'Notification Preferences',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return Dismissible(
                      key: Key(notification.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deleteNotification(notification.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Notification deleted'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                setState(() {
                                  _notifications.insert(index, notification);
                                });
                              },
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        title: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${notification.body}\n${DateFormat.yMMMd().add_jm().format(notification.timestamp)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                        leading: CircleAvatar(
                          backgroundColor: notification.isRead
                              ? Colors.grey.shade300
                              : Theme.of(context).primaryColor,
                          child: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'read') {
                              _markAsRead(notification.id);
                            } else if (value == 'unread') {
                              _markAsUnread(notification.id);
                            } else if (value == 'delete') {
                              _deleteNotification(notification.id);
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              if (!notification.isRead)
                                const PopupMenuItem(
                                  value: 'read',
                                  child: Text('Mark as read'),
                                ),
                              if (notification.isRead)
                                const PopupMenuItem(
                                  value: 'unread',
                                  child: Text('Mark as unread'),
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ];
                          },
                        ),
                        onTap: () {
                          // Navigate to related screen based on notification.data
                          if (notification.data != null &&
                              notification.data!.containsKey('contestId')) {
                            // TODO: Navigate to contest details
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Navigate to contest ${notification.data!['contestId']}'),
                              ),
                            );
                          }

                          // Mark as read when tapped
                          if (!notification.isRead) {
                            _markAsRead(notification.id);
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
