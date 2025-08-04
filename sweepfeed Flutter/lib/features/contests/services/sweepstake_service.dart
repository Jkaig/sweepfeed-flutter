import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/services/auth_service.dart';

class SweepstakeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  // Show completion dialog with enhanced UI
  Future<void> showCompletionDialog(BuildContext context, String sweepstakeId,
      String title, String sponsor, String endDate) async {
    final TextEditingController commentController = TextEditingController();
    bool isSavedForLater = false;
    bool isFavorite = false;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isSubmitting = false;

          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sweepstakes Return',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text('Sponsored by $sponsor',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text('Ends $endDate',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('How did it go?'),
                  const SizedBox(height: 16),
                  // Completion checkbox
                  const CheckboxListTile(
                    value: true,
                    onChanged: null,
                    title: Text('I completed this sweepstake'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  // Save for later
                  CheckboxListTile(
                    value: isSavedForLater,
                    onChanged: (value) {
                      setState(() => isSavedForLater = value ?? false);
                      _toggleSaveForLater(sweepstakeId, value ?? false);
                    },
                    title: const Text('Save for later'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText:
                          'Add a comment (for referrals or additional info)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // Favorite button
                  ListTile(
                    leading: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border),
                    title: const Text('Favorite'),
                    onTap: () {
                      setState(() => isFavorite = !isFavorite);
                      _toggleFavorite(sweepstakeId, isFavorite);
                    },
                  ),
                  // Reminder options
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Add to Daily'),
                    onTap: () => _setReminder(sweepstakeId, 'daily'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_view_week),
                    title: const Text('Add to Weekly'),
                    onTap: () => _setReminder(sweepstakeId, 'weekly'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: const Text('Add to Monthly'),
                    onTap: () => _setReminder(sweepstakeId, 'monthly'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Add to Yearly'),
                    onTap: () => _setReminder(sweepstakeId, 'yearly'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() => isSubmitting = true);
                        try {
                          await _completeSweepstake(
                            sweepstakeId,
                            comment: commentController.text.trim(),
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Sweepstake completed successfully!')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          setState(() => isSubmitting = false);
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Complete'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Toggle save for later status
  Future<void> _toggleSaveForLater(String sweepstakeId, bool save) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore.collection('users').doc(userId).update({
      'sweepstakes.savedForLater': save
          ? FieldValue.arrayUnion([sweepstakeId])
          : FieldValue.arrayRemove([sweepstakeId]),
    });
  }

  // Toggle favorite status
  Future<void> _toggleFavorite(String sweepstakeId, bool favorite) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore.collection('users').doc(userId).update({
      'sweepstakes.favorites': favorite
          ? FieldValue.arrayUnion([sweepstakeId])
          : FieldValue.arrayRemove([sweepstakeId]),
    });
  }

  // Set reminder frequency
  Future<void> _setReminder(String sweepstakeId, String frequency) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final reminderData = {
      'userId': userId,
      'sweepstakeId': sweepstakeId,
      'frequency': frequency,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('reminders').add(reminderData);
  }

  // Complete a sweepstake
  Future<void> _completeSweepstake(String sweepstakeId,
      {String? comment}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final completionData = {
      'userId': userId,
      'sweepstakeId': sweepstakeId,
      'completedAt': FieldValue.serverTimestamp(),
      'comment': comment,
    };

    await _firestore.collection('users').doc(userId).update({
      'sweepstakes.completed': FieldValue.arrayUnion([sweepstakeId]),
    });

    await _firestore.collection('sweepstake_completions').add(completionData);

    await _firestore.collection('sweepstakes').doc(sweepstakeId).update({
      'completions': FieldValue.increment(1),
      'lastCompletedAt': FieldValue.serverTimestamp(),
    });

    await _authService.addPoints(10, 'Sweepstake Completion');
    await _authService.updateStreak();
  }

  // Get user's completed sweepstakes
  Future<List<String>> getCompletedSweepstakes() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final userDoc = await _firestore.collection('users').doc(userId).get();
    return List<String>.from(userDoc.data()?['sweepstakes']['completed'] ?? []);
  }

  // Get saved for later sweepstakes
  Future<List<String>> getSavedForLater() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final userDoc = await _firestore.collection('users').doc(userId).get();
    return List<String>.from(
        userDoc.data()?['sweepstakes']['savedForLater'] ?? []);
  }

  // Get favorite sweepstakes
  Future<List<String>> getFavorites() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final userDoc = await _firestore.collection('users').doc(userId).get();
    return List<String>.from(userDoc.data()?['sweepstakes']['favorites'] ?? []);
  }

  // Get user's reminders
  Stream<QuerySnapshot> getReminders() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // Get completion comments for a sweepstake
  Stream<QuerySnapshot> getCompletionComments(String sweepstakeId) {
    return _firestore
        .collection('sweepstake_completions')
        .where('sweepstakeId', isEqualTo: sweepstakeId)
        .where('comment', isNotEqualTo: null)
        .orderBy('completedAt', descending: true)
        .snapshots();
  }

  // Get user's completion history
  Stream<QuerySnapshot> getUserCompletionHistory() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('sweepstake_completions')
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .snapshots();
  }
}
