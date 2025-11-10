import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/entry_model.dart';
import '../../../core/theme/app_colors.dart';
import '../services/entry_management_service.dart';

class EntryHistoryScreen extends StatefulWidget {
  const EntryHistoryScreen({super.key});

  @override
  State<EntryHistoryScreen> createState() => _EntryHistoryScreenState();
}

class _EntryHistoryScreenState extends State<EntryHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final EntryManagementService _entryService = EntryManagementService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ContestEntry> _allEntries = [];
  List<ContestEntry> _filteredEntries = [];
  List<EntryReceipt> _receipts = [];
  Map<String, dynamic> _statistics = {};

  bool _isLoading = true;
  String _selectedFilter = 'All';

  final List<String> _filterOptions = ['All', 'Confirmed', 'Pending', 'Failed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load entries, receipts, and statistics in parallel
      final results = await Future.wait([
        _entryService.getUserEntries(userId: user.uid, limit: 100),
        _entryService.getUserReceipts(user.uid),
        _entryService.getUserEntryStatistics(user.uid),
      ]);

      setState(() {
        _allEntries = results[0] as List<ContestEntry>;
        _receipts = results[1] as List<EntryReceipt>;
        _statistics = results[2] as Map<String, dynamic>;
        _filteredEntries = _allEntries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading entry history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterEntries(String filter) {
    setState(() {
      _selectedFilter = filter;

      switch (filter) {
        case 'All':
          _filteredEntries = _allEntries;
          break;
        case 'Confirmed':
          _filteredEntries = _allEntries.where((e) => e.isConfirmed).toList();
          break;
        case 'Pending':
          _filteredEntries = _allEntries.where((e) => e.isPending).toList();
          break;
        case 'Failed':
          _filteredEntries = _allEntries.where((e) => e.isFailed).toList();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(),

              // Statistics Card
              if (!_isLoading) _buildStatisticsCard(),

              // Tab Bar
              _buildTabBar(),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEntriesTab(),
                    _buildReceiptsTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildAppBar() => Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Entry History',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Track your sweepstakes entries',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _loadData,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cyberYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.refresh,
                  color: AppColors.cyberYellow,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0);

  Widget _buildStatisticsCard() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.3),
              AppColors.secondary.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cyberYellow.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppColors.cyberYellow,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Entry Statistics',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Entries',
                    _statistics['totalEntries']?.toString() ?? '0',
                    Icons.input,
                    AppColors.cyberYellow,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'This Month',
                    _statistics['thisMonthEntries']?.toString() ?? '0',
                    Icons.calendar_month,
                    AppColors.electricBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Success Rate',
                    '${(_statistics['successRate'] ?? 0).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    AppColors.neonGreen,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Prize Value',
                    '\$${(_statistics['totalPrizeValue'] ?? 0).toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: 200.ms, duration: 600.ms)
          .slideX(begin: 0.1, end: 0);

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildTabBar() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.cyberYellow, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Entries'),
            Tab(text: 'Receipts'),
            Tab(text: 'Analytics'),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms, duration: 500.ms);

  Widget _buildEntriesTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.cyberYellow,
        ),
      );
    }

    return Column(
      children: [
        // Filter Bar
        Container(
          height: 50,
          margin: const EdgeInsets.all(16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filterOptions.length,
            itemBuilder: (context, index) {
              final filter = _filterOptions[index];
              final isSelected = filter == _selectedFilter;

              return GestureDetector(
                onTap: () => _filterEntries(filter),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.cyberYellow
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.cyberYellow
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.textWhite,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Entries List
        Expanded(
          child: _filteredEntries.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _filteredEntries[index];
                    return _buildEntryCard(entry, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEntryCard(ContestEntry entry, int index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor(entry.status).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.contestTitle,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(entry.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          _getStatusColor(entry.status).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    entry.statusDisplayText,
                    style: TextStyle(
                      color: _getStatusColor(entry.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details Row
            Row(
              children: [
                const Icon(
                  Icons.confirmation_number,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Confirmation: ${entry.confirmationCode ?? 'N/A'}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(entry.entryDate),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${entry.entryData['prizeValue'] ?? 0}',
                  style: const TextStyle(
                    color: AppColors.cyberYellow,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                if (entry.receiptUrl != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewReceipt(entry),
                      icon: const Icon(Icons.receipt, size: 16),
                      label: const Text('Receipt'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cyberYellow,
                        side: BorderSide(
                          color: AppColors.cyberYellow.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                if (entry.receiptUrl != null) const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewDetails(entry),
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textWhite,
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: (index * 100).ms, duration: 500.ms)
          .slideX(begin: 0.1, end: 0, delay: (index * 100).ms);

  Widget _buildReceiptsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.cyberYellow,
        ),
      );
    }

    if (_receipts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt,
        title: 'No Receipts',
        subtitle: 'Your entry receipts will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _receipts.length,
      itemBuilder: (context, index) {
        final receipt = _receipts[index];
        return _buildReceiptCard(receipt, index);
      },
    );
  }

  Widget _buildReceiptCard(EntryReceipt receipt, int index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cyberYellow.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.cyberYellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.contestTitle,
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Confirmation: ${receipt.confirmationCode}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _downloadReceipt(receipt),
                  icon: const Icon(
                    Icons.download,
                    color: AppColors.cyberYellow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Generated: ${_formatDate(receipt.createdAt)}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: (index * 100).ms, duration: 500.ms)
          .slideX(begin: -0.1, end: 0, delay: (index * 100).ms);

  Widget _buildAnalyticsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.cyberYellow,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entry Analytics',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // Success Rate Chart
          _buildAnalyticsCard(
            'Success Rate',
            '${(_statistics['successRate'] ?? 0).toStringAsFixed(1)}%',
            Icons.trending_up,
            AppColors.neonGreen,
            'Based on ${_statistics['totalEntries'] ?? 0} total entries',
          ),

          const SizedBox(height: 16),

          // Recent Activity
          _buildAnalyticsCard(
            'Recent Activity',
            '${_statistics['recentEntries'] ?? 0}',
            Icons.schedule,
            AppColors.electricBlue,
            'Entries in the last 7 days',
          ),

          const SizedBox(height: 16),

          // Entry Breakdown
          _buildEntryBreakdown(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildEntryBreakdown() {
    final confirmed = _statistics['confirmedEntries'] ?? 0;
    final pending = _statistics['pendingEntries'] ?? 0;
    final failed = _statistics['failedEntries'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entry Breakdown',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildBreakdownItem('Confirmed', confirmed, AppColors.neonGreen),
          _buildBreakdownItem('Pending', pending, AppColors.cyberYellow),
          _buildBreakdownItem('Failed', failed, Colors.red),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int count, Color color) {
    final total = _statistics['totalEntries'] ?? 1;
    final percentage = total > 0 ? (count / total) * 100 : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${percentage.toStringAsFixed(1)}%)',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    IconData icon = Icons.inbox,
    String title = 'No Entries',
    String subtitle = 'Your contest entries will appear here',
  }) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Color _getStatusColor(EntryStatus status) {
    switch (status) {
      case EntryStatus.confirmed:
        return AppColors.neonGreen;
      case EntryStatus.pending:
        return AppColors.cyberYellow;
      case EntryStatus.failed:
      case EntryStatus.invalid:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

  Future<void> _viewReceipt(ContestEntry entry) async {
    final receipt = await _entryService.getEntryReceipt(entry.id);
    if (receipt != null) {
      _downloadReceipt(receipt);
    }
  }

  Future<void> _downloadReceipt(EntryReceipt receipt) async {
    try {
      final uri = Uri.parse(receipt.receiptPdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening receipt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewDetails(ContestEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entry Details',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Contest', entry.contestTitle),
            _buildDetailRow(
              'Confirmation Code',
              entry.confirmationCode ?? 'N/A',
            ),
            _buildDetailRow('Entry Date', _formatDate(entry.entryDate)),
            _buildDetailRow('Method', entry.methodDisplayText),
            _buildDetailRow('Status', entry.statusDisplayText),
            _buildDetailRow(
              'Prize Value',
              '\$${entry.entryData['prizeValue'] ?? 0}',
            ),
            if (entry.isDailyEntry)
              _buildDetailRow(
                'Next Entry',
                entry.nextEntryAllowed != null
                    ? _formatDate(entry.nextEntryAllowed!)
                    : 'Available now',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
}
