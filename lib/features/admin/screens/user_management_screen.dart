import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/admin_permissions_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../services/admin_service.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkSuperAdmin();
    _loadUsers();
  }

  Future<void> _checkSuperAdmin() async {
    final isSuper = await _adminService.isSuperAdmin();
    setState(() {
      _isSuperAdmin = isSuper;
    });
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final usersList = await _adminService.getUsers(
        searchQuery: _searchController.text.trim().isEmpty 
            ? null 
            : _searchController.text.trim(),
      );
      setState(() {
        _users = usersList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _showPermissionsDialog(String userId, String userName, bool isAdmin) async {
    if (!isAdmin) return;

    // Get current permissions
    final currentPerms = await _adminService.getAdminPermissions(userId);
    
    var newPerms = currentPerms;
    final permController = _PermissionsController(currentPerms);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.primaryMedium,
          title: Text(
            'Admin Permissions',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set permissions for $userName',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                _buildPermissionSwitch(
                  'Manage Users',
                  permController.canManageUsers,
                  (value) => setState(() => permController.canManageUsers = value),
                ),
                _buildPermissionSwitch(
                  'Manage Support Tickets',
                  permController.canManageSupportTickets,
                  (value) => setState(() => permController.canManageSupportTickets = value),
                ),
                _buildPermissionSwitch(
                  'Manage Winner Claims',
                  permController.canManageWinnerClaims,
                  (value) => setState(() => permController.canManageWinnerClaims = value),
                ),
                _buildPermissionSwitch(
                  'Manage Contests',
                  permController.canManageContests,
                  (value) => setState(() => permController.canManageContests = value),
                ),
                _buildPermissionSwitch(
                  'View Analytics',
                  permController.canViewAnalytics,
                  (value) => setState(() => permController.canViewAnalytics = value),
                ),
                _buildPermissionSwitch(
                  'Manage Settings',
                  permController.canManageSettings,
                  (value) => setState(() => permController.canManageSettings = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          permController.setAll(true);
                          setState(() {});
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brandCyan,
                          side: const BorderSide(color: AppColors.brandCyan),
                        ),
                        child: const Text('Select All'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          permController.setAll(false);
                          setState(() {});
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textLight,
                          side: const BorderSide(color: AppColors.textLight),
                        ),
                        child: const Text('Clear All'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textLight),
              ),
            ),
            TextButton(
              onPressed: () {
                newPerms = permController.toPermissions();
                Navigator.of(context).pop(true);
              },
              child: Text(
                'Save',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.brandCyan),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.updateAdminPermissions(userId, newPerms);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissions updated successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating permissions: $e'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
  }

  Widget _buildPermissionSwitch(String label, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
      title: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.brandCyan,
    );

  Future<void> _toggleAdminRole(String userId, String userName, bool currentStatus) async {
    // Only superadmin can set other admins
    if (!_isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only superadmin can set other admins'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          currentStatus ? 'Remove Admin Access' : 'Grant Admin Access',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
        ),
        content: Text(
          currentStatus
              ? 'Are you sure you want to remove admin access from $userName?'
              : 'Are you sure you want to grant admin access to $userName?',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              currentStatus ? 'Remove' : 'Grant',
              style: AppTextStyles.labelLarge.copyWith(
                color: currentStatus ? AppColors.errorRed : AppColors.brandCyan,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _adminService.updateUserRole(userId, !currentStatus);
      
      // If granting admin access, show permissions dialog
      if (!currentStatus) {
        // Wait a bit for the role to be saved
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          await _showPermissionsDialog(userId, userName, true);
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus
                  ? 'Admin access removed from $userName'
                  : 'Admin access granted to $userName',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
      _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating role: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textLight),
                        onPressed: () {
                          _searchController.clear();
                          _loadUsers();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.brandCyan, width: 2),
                ),
                filled: true,
                fillColor: AppColors.primaryMedium,
              ),
              onChanged: (value) => _loadUsers(),
            ),
          ),

          // Superadmin Notice
          if (_isSuperAdmin)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.brandCyan.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: AppColors.brandCyan, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can grant or remove admin access to other users',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.brandCyan),
                    ),
                  ),
                ],
              ),
            ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final isAdmin = user['roles']?['admin'] ?? user['isAdmin'] ?? false;
                          final userName = user['name'] ?? 'Unknown User';
                          final userEmail = user['email'] ?? 'No email';
                          final userId = user['id'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryMedium,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAdmin
                                    ? AppColors.brandCyan.withOpacity(0.5)
                                    : AppColors.primaryLight.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                CircleAvatar(
                                  backgroundColor: isAdmin
                                      ? AppColors.brandCyan.withOpacity(0.2)
                                      : AppColors.primaryLight,
                                  radius: 24,
                                  child: Text(
                                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: isAdmin ? AppColors.brandCyan : AppColors.textWhite,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // User Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              userName,
                                              style: AppTextStyles.titleSmall.copyWith(
                                                color: AppColors.textWhite,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (isAdmin)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.brandCyan.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: AppColors.brandCyan,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.admin_panel_settings,
                                                    color: AppColors.brandCyan,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'ADMIN',
                                                    style: AppTextStyles.labelSmall.copyWith(
                                                      color: AppColors.brandCyan,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        userEmail,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Admin Toggle & Permissions
                                if (_isSuperAdmin)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isAdmin)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.settings,
                                            color: AppColors.brandCyan,
                                            size: 20,
                                          ),
                                          onPressed: () => _showPermissionsDialog(userId, userName, isAdmin),
                                          tooltip: 'Edit Permissions',
                                        ),
                                      Switch(
                                        value: isAdmin,
                                        activeThumbColor: AppColors.brandCyan,
                                        onChanged: (value) {
                                          _toggleAdminRole(userId, userName, isAdmin);
                                        },
                                      ),
                                    ],
                                  )
                                else if (isAdmin)
                                  const Icon(
                                    Icons.admin_panel_settings,
                                    color: AppColors.brandCyan,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Helper class to manage permission state in dialog
class _PermissionsController {

  _PermissionsController(AdminPermissions perms)
      : canManageUsers = perms.canManageUsers,
        canManageSupportTickets = perms.canManageSupportTickets,
        canManageWinnerClaims = perms.canManageWinnerClaims,
        canManageContests = perms.canManageContests,
        canViewAnalytics = perms.canViewAnalytics,
        canManageSettings = perms.canManageSettings;
  bool canManageUsers;
  bool canManageSupportTickets;
  bool canManageWinnerClaims;
  bool canManageContests;
  bool canViewAnalytics;
  bool canManageSettings;

  void setAll(bool value) {
    canManageUsers = value;
    canManageSupportTickets = value;
    canManageWinnerClaims = value;
    canManageContests = value;
    canViewAnalytics = value;
    canManageSettings = value;
  }

  AdminPermissions toPermissions() => AdminPermissions(
        canManageUsers: canManageUsers,
        canManageSupportTickets: canManageSupportTickets,
        canManageWinnerClaims: canManageWinnerClaims,
        canManageContests: canManageContests,
        canViewAnalytics: canViewAnalytics,
        canManageSettings: canManageSettings,
      );
}
