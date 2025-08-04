import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sweepfeed_app/core/theme/app_colors.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  _ReferralScreenState createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _referralCode;
  int _referralCount = 0;
  int _referralPoints = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = "User not logged in.";
        _isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          setState(() {
            _referralCode = data['referralCode'] as String?;
            _referralCount = data['referralCount'] as int? ?? 0;
            // Assuming points are stored under gamification -> points -> available
            final gamification = data['gamification'] as Map<String, dynamic>?;
            final pointsData = gamification?['points'] as Map<String, dynamic>?;
            _referralPoints = pointsData?['available'] as int? ?? 0; 
            // Or, if we decide to use a specific 'referralPoints' field at root of user doc:
            // _referralPoints = data['referralPoints'] as int? ?? 0;
          });
        } else {
          _errorMessage = "Could not load referral data.";
        }
      } else {
        _errorMessage = "User profile not found.";
      }
    } catch (e) {
      _errorMessage = "Error loading data: ${e.toString()}";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _shareReferralCode() {
    if (_referralCode != null && _referralCode!.isNotEmpty) {
      final shareText =
          'Join SweepFeed and win amazing prizes! Use my referral code: $_referralCode\n'
          'Download the app here: https://yourappstorelink.com'; // Replace with actual link
      Share.share(shareText, subject: 'Join me on SweepFeed!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral code not available.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral Program'),
        backgroundColor: AppColors.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReferralData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
                  ))
                : _referralCode == null 
                    ? Center(
                        child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _auth.currentUser == null 
                              ? "Please log in to view your referral information." 
                              : "Your referral information could not be loaded. Pull to refresh.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16)
                        ),
                      ))
                    : _buildReferralContent(),
      ),
    );
  }

  Widget _buildReferralContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Invite Friends, Earn Rewards!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Share your unique referral code with friends. When they sign up using your code, both you and your friend get bonus points!',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    'Your Referral Code:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    _referralCode ?? 'Not available',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent, // Use accent color for the code
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Share Your Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _shareReferralCode,
          ),
          const SizedBox(height: 32),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildStatCard('Friends Referred', _referralCount.toString()),
              _buildStatCard('Points Earned', _referralPoints.toString()),
            ],
          ),
           const SizedBox(height: 24),
           Text(
            "Note: Points shown are your total available gamification points. Referral points contribute to this total.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
