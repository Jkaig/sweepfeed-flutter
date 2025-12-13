import 'package:flutter/material.dart';
import '../../../core/models/contest.dart';
import '../services/admin_service.dart';

class ContestManagementCard extends StatefulWidget {
  const ContestManagementCard({super.key});

  @override
  State<ContestManagementCard> createState() =>
      _ContestManagementCardState();
}

class _ContestManagementCardState extends State<ContestManagementCard> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  List<Contest> contests = [];
  bool isLoading = true;
  String? selectedCategory;
  bool? isActive;

  @override
  void initState() {
    super.initState();
    _loadContests();
  }

  Future<void> _loadContests() async {
    setState(() => isLoading = true);
    try {
      final contestsList = await _adminService.getContests(
        searchQuery: _searchController.text.trim(),
        category: selectedCategory,
        isActive: isActive,
      );
      setState(() {
        contests = contestsList;
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
              // Search and Filter Row
              Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search contests...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                      ),
                      onChanged: (value) => _loadContests(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add New Contest Button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle add new contest
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: selectedCategory == null && isActive == null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedCategory = null;
                            isActive = null;
                          });
                          _loadContests();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Active'),
                      selected: isActive == true,
                      onSelected: (selected) {
                        setState(() {
                          isActive = selected ? true : null;
                        });
                        _loadContests();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Ended'),
                      selected: isActive == false,
                      onSelected: (selected) {
                        setState(() {
                          isActive = selected ? false : null;
                        });
                        _loadContests();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contests List
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (contests.isEmpty)
                const Text(
                  'No contests found',
                  style: TextStyle(color: Colors.white70),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: contests.length,
                  itemBuilder: (context, index) {
                    final contest = contests[index];
                    return ListTile(
                      leading: Image.network(
                        contest.imageUrl,
                        width: 48,
                        height: 48,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey[700],
                          child: const Icon(Icons.image, color: Colors.white),
                        ),
                      ),
                      title: Text(
                        contest.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Ends: ${contest.endDate.toString()}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit Button
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () {
                              // Handle edit contest
                            },
                          ),
                          // Delete Button
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Contest'),
                                  content: const Text(
                                    'Are you sure you want to delete this contest?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await _adminService
                                    .deleteContest(contest.id);
                                _loadContests();
                              }
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
