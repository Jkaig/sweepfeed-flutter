import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart'; 

import 'package:sweep_feed/core/models/user_profile.dart';
import 'package:sweep_feed/features/auth/services/auth_service.dart';
import 'package:sweep_feed/features/profile/services/profile_service.dart';
import 'package:sweep_feed/core/services/gamification_service.dart';
import 'package:sweep_feed/core/theme/app_colors.dart'; 
import 'package:sweep_feed/core/theme/app_text_styles.dart'; 
import 'package:sweep_feed/core/widgets/loading_indicator.dart'; 

import '../../notifications/screens/notification_preferences_screen.dart';
import '../../subscription/screens/subscription_screen.dart';
import 'profile_settings_screen.dart';
import 'referral_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();

  Future<UserProfile?>? _userProfileFuture;
  Future<Map<String, dynamic>?>? _authUserDocFuture;
  Future<List<Map<String, dynamic>>>? _contestHistoryFuture;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = context.read<User?>();
    if (_currentUser != null) {
      _loadUserData();
    }
  }

  void _loadUserData() {
    if (_currentUser == null) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    
    _userProfileFuture = _profileService.getUserProfile(_currentUser!.uid);
    _authUserDocFuture = authService.getUserDocument(); 
    _contestHistoryFuture = _profileService.getUserEntriesWithContestDetails(_currentUser!.uid);
  }
  
  void _refreshData() {
    if (_currentUser != null) {
      setState(() {
        _loadUserData();
      });
    }
  }

  void _navigateToProfileSettings() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileSettingsScreen(),
      ),
    );
    if (result == true) {
      _refreshData();
    }
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite)),
          Text(value, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: AppBar(title: Text('Profile', style: AppTextStyles.titleLarge)),
        body: Center(child: Text('Please log in.', style: AppTextStyles.bodyLarge)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text('My Profile', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite)),
        backgroundColor: AppColors.primaryMedium,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textWhite),
            onPressed: _navigateToProfileSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        color: AppColors.accent,
        backgroundColor: AppColors.primaryMedium,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            FutureBuilder<UserProfile?>(
              future: _userProfileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _authUserDocFuture == null) { 
                  return const Center(child: LoadingIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.errorRed)));
                }
                final userProfile = snapshot.data;
                final displayName = _currentUser!.displayName ?? userProfile?.name ?? 'Sweepstakes User';
                final email = _currentUser!.email ?? 'No email provided';

                return Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: userProfile?.profilePictureUrl != null && userProfile!.profilePictureUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(userProfile.profilePictureUrl!)
                          : null,
                      child: userProfile?.profilePictureUrl == null || userProfile!.profilePictureUrl!.isEmpty
                          ? Icon(Icons.person, size: 50, color: AppColors.textMuted)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textWhite),
                    ),
                    const SizedBox(height: 4),
                    Text(email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight)),
                    if (userProfile?.bio != null && userProfile!.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          userProfile!.bio!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
                        ),
                      ),
                     if (userProfile?.location != null && userProfile!.location!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(userProfile.location!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Divider(color: AppColors.primaryLight.withOpacity(0.5)),

            ListTile(
              leading: Icon(Icons.edit_outlined, color: AppColors.textLight),
              title: Text('Edit Profile', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite)),
              trailing: Icon(Icons.chevron_right, color: AppColors.textLight),
              onTap: _navigateToProfileSettings,
            ),
            Divider(color: AppColors.primaryLight.withOpacity(0.5)),
            ListTile(
              leading: Icon(Icons.notifications_outlined, color: AppColors.textLight),
              title: Text('Notification Preferences', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite)),
              trailing: Icon(Icons.chevron_right, color: AppColors.textLight),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()),
                );
              },
            ),
            Divider(color: AppColors.primaryLight.withOpacity(0.5)),
            ListTile(
              leading: Icon(Icons.star_outline_rounded, color: AppColors.textLight),
              title: Text('Subscription', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite)),
              trailing: Icon(Icons.chevron_right, color: AppColors.textLight),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              },
            ),
            Divider(color: AppColors.primaryLight.withOpacity(0.5)),
            ListTile(
              leading: Icon(Icons.people_alt_outlined, color: AppColors.textLight),
              title: Text('Refer a Friend', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite)),
              trailing: Icon(Icons.chevron_right, color: AppColors.textLight),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReferralScreen()),
                );
              },
            ),
            Divider(color: AppColors.primaryLight.withOpacity(0.5)),
            ListTile( 
              leading: Icon(Icons.help_outline, color: AppColors.textLight),
              title: Text('Help & Support', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite)),
              trailing: Icon(Icons.chevron_right, color: AppColors.textLight),
              onTap: () {
                debugPrint("Help & Support tapped");
              },
            ),
            Divider(color: AppColors.primaryLight.withOpacity(0.5)),
            
            Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
              child: Text('My Achievements', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite)),
            ),
            _buildBadgesSection(), 
            Divider(color: AppColors.primaryLight.withOpacity(0.5)),

            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Text('My Stats', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite)),
            ),
            FutureBuilder<Map<String, dynamic>?>(
              future: _authUserDocFuture, 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LoadingIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading stats: ${snapshot.error}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.errorRed)));
                }
                final userData = snapshot.data;
                final stats = userData?['stats'] as Map<String, dynamic>?;
                final totalEntries = stats?['totalEntries'] ?? 0;
                final totalWins = stats?['totalWins'] ?? 0;
                final winRate = totalEntries > 0 ? (totalWins / totalEntries * 100) : 0.0;

                return Card(
                  elevation: 0, 
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  color: AppColors.primaryMedium,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.primaryLight.withOpacity(0.5))
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatRow(context, 'Total Entries', (stats?['totalEntries'] ?? 0).toString()),
                        _buildStatRow(context, 'Active Entries', (stats?['activeEntries'] ?? 0).toString()),
                        _buildStatRow(context, 'Contests Won', (stats?['totalWins'] ?? 0).toString()),
                        _buildStatRow(context, 'Win Rate', '${winRate.toStringAsFixed(1)}%'),
                      ],
                    ),
                  ),
                );
              },
            ),
            Divider(color: AppColors.primaryLight.withOpacity(0.5)),
            
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Text('Contest Entry History', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite)),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _contestHistoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LoadingIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.errorRed)));
                }
                final history = snapshot.data;
                if (history == null || history.isEmpty) {
                  return Center(child: Text('No contest entries yet.', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted)));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    final entryDate = entry['entryDate'] as DateTime?;
                    final formattedDate = entryDate != null ? DateFormat.yMMMd().format(entryDate) : 'N/A';
                    return Card(
                      color: AppColors.primaryMedium,
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      elevation: 0,
                       shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppColors.primaryLight.withOpacity(0.3))
                      ),
                      child: ListTile(
                        title: Text(entry['contestName'] ?? 'Contest Name Missing', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite)),
                        subtitle: Text(
                            'Entered: $formattedDate\nPrize: ${entry['prize'] ?? 'N/A'}',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Note: Contest win/loss status is not currently tracked.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed.withOpacity(0.15),
                  foregroundColor: AppColors.errorRed,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.errorRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.primaryMedium,
                      title: Text('Confirm Sign Out', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite)),
                      content: Text('Are you sure you want to sign out?', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textLight)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Sign Out', style: AppTextStyles.labelLarge.copyWith(color: AppColors.errorRed)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _authService.signOut(); 
                  }
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _authUserDocFuture, 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator(size: 20));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('Could not load badges.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)));
        }

        final userData = snapshot.data!;
        final gamificationData = userData['gamification'] as Map<String, dynamic>?;
        final badgesData = gamificationData?['badges'] as Map<String, dynamic>?;
        final collectedBadgeIds = (badgesData?['collected'] as List<dynamic>?)
            ?.map((id) => id.toString())
            .toList() ?? [];

        if (collectedBadgeIds.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text('No badges earned yet. Keep exploring!', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted)),
            ),
          );
        }

        List<Widget> badgeWidgets = [];
        for (String badgeId in collectedBadgeIds) {
          final badgeMeta = GamificationService.getBadgeById(badgeId); 
          if (badgeMeta != null) {
            badgeWidgets.add(
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${badgeMeta.name}: ${badgeMeta.description}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textWhite)),
                      backgroundColor: AppColors.primaryMedium,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                child: Chip(
                  avatar: Icon(badgeMeta.icon, color: AppColors.accent, size: 18),
                  label: Text(badgeMeta.name, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textWhite)),
                  backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              )
            );
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: badgeWidgets,
          ),
        );
      },
    );
  }
}
