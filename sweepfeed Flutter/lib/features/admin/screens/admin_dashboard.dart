import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../widgets/stats_card.dart';
import '../widgets/user_management_card.dart';
import '../widgets/sweepstake_management_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  bool isLoading = true;
  Map<String, dynamic> stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final dashboardStats = await _adminService.getDashboardStats();
      setState(() {
        stats = dashboardStats;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick Stats Section
          Text(
            'Quick Stats',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Total Users',
                  value: stats['totalUsers']?.toString() ?? '0',
                  icon: Icons.people,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Active Today',
                  value: stats['activeToday']?.toString() ?? '0',
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Pro Users',
                  value: stats['proUsers']?.toString() ?? '0',
                  icon: Icons.star,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Total Sweepstakes',
                  value: stats['totalSweepstakes']?.toString() ?? '0',
                  icon: Icons.card_giftcard,
                ),
              ),
            ],
          ),

          // User Management Section
          const SizedBox(height: 32),
          Text(
            'User Management',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          const UserManagementCard(),

          // Sweepstake Management Section
          const SizedBox(height: 32),
          Text(
            'Sweepstake Management',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          const SweepstakeManagementCard(),

          // Settings Section
          const SizedBox(height: 32),
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.grey[850],
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.white),
                  title: const Text('Push Notifications',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    // Handle push notifications settings
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.verified_user, color: Colors.white),
                  title: const Text('User Verification',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    // Handle user verification settings
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.policy, color: Colors.white),
                  title: const Text('Content Moderation',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    // Handle content moderation settings
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
