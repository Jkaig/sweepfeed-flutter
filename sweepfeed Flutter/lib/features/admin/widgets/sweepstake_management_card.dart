import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class SweepstakeManagementCard extends StatefulWidget {
  const SweepstakeManagementCard({super.key});

  @override
  State<SweepstakeManagementCard> createState() =>
      _SweepstakeManagementCardState();
}

class _SweepstakeManagementCardState extends State<SweepstakeManagementCard> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> sweepstakes = [];
  bool isLoading = true;
  String? selectedCategory;
  bool? isActive;

  @override
  void initState() {
    super.initState();
    _loadSweepstakes();
  }

  Future<void> _loadSweepstakes() async {
    setState(() => isLoading = true);
    try {
      final sweepstakesList = await _adminService.getSweepstakes(
        searchQuery: _searchController.text.trim(),
        category: selectedCategory,
        isActive: isActive,
      );
      setState(() {
        sweepstakes = sweepstakesList;
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
                        hintText: 'Search sweepstakes...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                      ),
                      onChanged: (value) => _loadSweepstakes(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add New Sweepstake Button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle add new sweepstake
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
                          _loadSweepstakes();
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
                        _loadSweepstakes();
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
                        _loadSweepstakes();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sweepstakes List
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (sweepstakes.isEmpty)
                const Text(
                  'No sweepstakes found',
                  style: TextStyle(color: Colors.white70),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sweepstakes.length,
                  itemBuilder: (context, index) {
                    final sweepstake = sweepstakes[index];
                    return ListTile(
                      leading: Image.network(
                        sweepstake['logoUrl'] ?? '',
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
                        sweepstake['title'] ?? 'Untitled Sweepstake',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Ends: ${sweepstake['endDate']?.toString() ?? 'No end date'}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit Button
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () {
                              // Handle edit sweepstake
                            },
                          ),
                          // Delete Button
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Sweepstake'),
                                  content: const Text(
                                    'Are you sure you want to delete this sweepstake?',
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
                                    .deleteSweepstake(sweepstake['id']);
                                _loadSweepstakes();
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
