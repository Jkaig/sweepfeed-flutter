import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/services/auth_service.dart';
import '../services/admin_service.dart';
import 'support_ticket_list_screen.dart';
import 'user_management_screen.dart';
import 'winner_claims_screen.dart';

// Provider to check if current user is admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  // We need to instantiate AuthService directly or via provider if available
  // Assuming a simple direct instantiation for now based on AuthService code
  final authService = AuthService();
  return authService.isUserAdmin();
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  bool _canManageUsers = false;
  bool _canManageSupportTickets = false;
  bool _canManageWinnerClaims = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final user = AuthService().currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final perms = await _adminService.getAdminPermissions(user.uid);
    setState(() {
      _canManageUsers = perms.canManageUsers;
      _canManageSupportTickets = perms.canManageSupportTickets;
      _canManageWinnerClaims = perms.canManageWinnerClaims;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: isAdminAsync.when(
        data: (isAdmin) {
          if (!isAdmin) {
            return const Center(
              child: Text(
                'Access Denied',
                style: TextStyle(color: AppColors.errorRed, fontSize: 18),
              ),
            );
          }
          
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final cards = <Widget>[];
          
          if (_canManageSupportTickets) {
            cards.add(
              _buildDashboardCard(
                context,
                'Support Tickets',
                Icons.support_agent,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportTicketListScreen()),
                ),
              ),
            );
          }
          
          if (_canManageUsers) {
            cards.add(
              _buildDashboardCard(
                context,
                'User Management',
                Icons.people,
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserManagementScreen(),
                  ),
                ),
              ),
            );
          }
          
          if (_canManageWinnerClaims) {
            cards.add(
              _buildDashboardCard(
                context,
                'Winner Claims',
                Icons.emoji_events,
                Colors.amber,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WinnerClaimsScreen(),
                  ),
                ),
              ),
            );
          }

          if (cards.isEmpty) {
            return const Center(
              child: Text(
                'No permissions assigned',
                style: TextStyle(color: AppColors.textLight, fontSize: 16),
              ),
                  );
          }

          return GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: cards,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) => GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
}
