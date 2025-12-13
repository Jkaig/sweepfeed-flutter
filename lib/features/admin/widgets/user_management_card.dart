import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class UserManagementCard extends StatefulWidget {
  const UserManagementCard({super.key});

  @override
  State<UserManagementCard> createState() => _UserManagementCardState();
}

class _UserManagementCardState extends State<UserManagementCard> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final usersList = await _adminService.getUsers(
        searchQuery: _searchController.text.trim(),
      );
      setState(() {
        users = usersList;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.grey[850],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[900],
                ),
                onChanged: (value) => _loadUsers(),
              ),
              const SizedBox(height: 16),

              // Users List
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (users.isEmpty)
                const Text(
                  'No users found',
                  style: TextStyle(color: Colors.white70),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[700],
                        child: Text(
                          user['name']?[0].toUpperCase() ?? '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        user['name'] ?? 'Unknown User',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        user['email'] ?? '',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pro Status Toggle
                          Switch(
                            value: user['isPro'] ?? false,
                            onChanged: (value) async {
                              await _adminService.updateUserProStatus(
                                user['id'],
                                value,
                              );
                              _loadUsers();
                            },
                          ),
                          // Admin Role Toggle
                          IconButton(
                            icon: Icon(
                              user['isAdmin'] ?? false
                                  ? Icons.admin_panel_settings
                                  : Icons.admin_panel_settings_outlined,
                              color: user['isAdmin'] ?? false
                                  ? Colors.amber
                                  : Colors.grey,
                            ),
                            onPressed: () async {
                              await _adminService.updateUserRole(
                                user['id'],
                                !(user['isAdmin'] ?? false),
                              );
                              _loadUsers();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
