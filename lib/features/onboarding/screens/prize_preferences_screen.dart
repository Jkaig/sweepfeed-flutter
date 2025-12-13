import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth/screens/auth_wrapper.dart';

class PrizePreferencesScreen extends StatefulWidget {
  const PrizePreferencesScreen({super.key});

  @override
  _PrizePreferencesScreenState createState() => _PrizePreferencesScreenState();
}

class _PrizePreferencesScreenState extends State<PrizePreferencesScreen> {
  final List<String> _selectedPrizes = [];
  bool _isSaving = false;

  void _togglePrize(String prize) {
    setState(() {
      if (_selectedPrizes.contains(prize)) {
        _selectedPrizes.remove(prize);
      } else {
        _selectedPrizes.add(prize);
      }
    });
  }

  Future<void> _savePrizePreferences() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {
            'prizePreferences': _selectedPrizes,
            'onboardingCompleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Prize Preferences'),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  CheckboxListTile(
                    title: const Text('Cash'),
                    value: _selectedPrizes.contains('Cash'),
                    onChanged: (value) => _togglePrize('Cash'),
                  ),
                  CheckboxListTile(
                    title: const Text('Gift Cards'),
                    value: _selectedPrizes.contains('Gift Cards'),
                    onChanged: (value) => _togglePrize('Gift Cards'),
                  ),
                  CheckboxListTile(
                    title: const Text('Electronics'),
                    value: _selectedPrizes.contains('Electronics'),
                    onChanged: (value) => _togglePrize('Electronics'),
                  ),
                  CheckboxListTile(
                    title: const Text('Cars'),
                    value: _selectedPrizes.contains('Cars'),
                    onChanged: (value) => _togglePrize('Cars'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePrizePreferences,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Finish'),
              ),
            ),
          ],
        ),
      );
}
