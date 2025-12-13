import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/winner_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../winners/services/winner_verification_service.dart';

class WinnerClaimsScreen extends ConsumerStatefulWidget {
  const WinnerClaimsScreen({super.key});

  @override
  ConsumerState<WinnerClaimsScreen> createState() => _WinnerClaimsScreenState();
}

class _WinnerClaimsScreenState extends ConsumerState<WinnerClaimsScreen> {
  final WinnerVerificationService _winnerService = WinnerVerificationService();
  String _selectedFilter = 'all'; // all, pending, verified, claimed, disputed, expired
  List<Winner> _winners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWinners();
  }

  Future<void> _loadWinners() async {
    setState(() => _isLoading = true);
    try {
      final allWinners = await _winnerService.getAllWinners();
      setState(() {
        _winners = allWinners;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading winners: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _updateWinnerStatus(String winnerId, WinnerStatus newStatus, {String? reason}) async {
    try {
      await _winnerService.updateWinnerStatus(winnerId, newStatus, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Winner status updated'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
      _loadWinners();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _showWinnerDetails(Winner winner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Winner Claim Details',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('User', winner.userName),
              _buildDetailRow('Email', 'N/A'), // Email not in core model
              _buildDetailRow('Contest', winner.contestTitle),
              _buildDetailRow('Prize', winner.prizeDescription),
              _buildDetailRow('Value', '\$${winner.prizeValue.toStringAsFixed(2)}'),
              _buildDetailRow('Status', _getStatusText(winner.status)),
              _buildDetailRow('Win Date', DateFormat('MMM d, y').format(winner.winDate)),
              if (winner.claimDeadline != null)
                _buildDetailRow(
                  'Claim Deadline',
                  DateFormat('MMM d, y').format(winner.claimDeadline!),
                ),
              if (winner.rejectionReason != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Rejection Reason:',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.errorRed),
                ),
                const SizedBox(height: 8),
                Text(
                  winner.rejectionReason!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
                ),
              ],
              if (winner.verificationData.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Verification Data:',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.brandCyan),
                ),
                const SizedBox(height: 8),
                ...winner.verificationData.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                      ),
                    ),),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.textLight),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
            ),
          ),
        ],
      ),
    );

  String _getStatusText(WinnerStatus status) {
    switch (status) {
      case WinnerStatus.pending:
        return 'Pending';
      case WinnerStatus.verified:
        return 'Verified';
      case WinnerStatus.claimed:
        return 'Claimed';
      case WinnerStatus.disputed:
        return 'Disputed';
      case WinnerStatus.expired:
        return 'Expired';
    }
  }

  Color _getStatusColor(WinnerStatus status) {
    switch (status) {
      case WinnerStatus.pending:
        return Colors.orange;
      case WinnerStatus.verified:
        return Colors.green;
      case WinnerStatus.claimed:
        return Colors.blue;
      case WinnerStatus.disputed:
        return Colors.red;
      case WinnerStatus.expired:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredWinners = _selectedFilter == 'all'
        ? _winners
        : _winners.where((w) {
            switch (_selectedFilter) {
              case 'pending':
                return w.status == WinnerStatus.pending;
              case 'verified':
                return w.status == WinnerStatus.verified;
              case 'claimed':
                return w.status == WinnerStatus.claimed;
              case 'disputed':
                return w.status == WinnerStatus.disputed;
              case 'expired':
                return w.status == WinnerStatus.expired;
              default:
                return true;
            }
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Winner Claims'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('pending', 'Pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('verified', 'Verified'),
                  const SizedBox(width: 8),
                  _buildFilterChip('claimed', 'Claimed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('disputed', 'Disputed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('expired', 'Expired'),
                ],
              ),
            ),
          ),

          // Winners List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredWinners.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No winner claims found',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadWinners,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredWinners.length,
                          itemBuilder: (context, index) {
                            final winner = filteredWinners[index];
                            return _buildWinnerCard(winner);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppColors.brandCyan.withOpacity(0.3),
      checkmarkColor: AppColors.brandCyan,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.brandCyan : AppColors.textLight,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.brandCyan : AppColors.primaryLight,
      ),
    );
  }

  Widget _buildWinnerCard(Winner winner) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(winner.status).withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      winner.contestTitle,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      winner.userName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(winner.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(winner.status)),
                ),
                child: Text(
                  _getStatusText(winner.status).toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _getStatusColor(winner.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.card_giftcard, size: 16, color: AppColors.brandCyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  winner.prizeDescription,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.attach_money, size: 16, color: AppColors.brandCyan),
              const SizedBox(width: 8),
              Text(
                '\$${winner.prizeValue.toStringAsFixed(2)}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.brandCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, y').format(winner.winDate),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (winner.status == WinnerStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showVerifyDialog(winner),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Verify'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.successGreen,
                      side: const BorderSide(color: AppColors.successGreen),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(winner),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: const BorderSide(color: AppColors.errorRed),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showWinnerDetails(winner),
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('View Details'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brandCyan,
            ),
          ),
        ],
      ),
    );

  void _showVerifyDialog(Winner winner) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Verify Winner',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Verify this winner claim for ${winner.contestTitle}?',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Admin notes (optional)',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.brandCyan),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.brandCyan, width: 2),
                ),
                filled: true,
                fillColor: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textLight),
            ),
          ),
          TextButton(
            onPressed: () async {
              // verifyWinner already sends notification via _updateWinnerStatus -> _sendStatusUpdateNotification
              if (notesController.text.isNotEmpty) {
                await _winnerService.verifyWinner(winner.id, notes: notesController.text);
              } else {
                await _winnerService.verifyWinner(winner.id);
              }
              if (mounted) Navigator.of(context).pop();
            },
            child: Text(
              'Verify',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.successGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Winner winner) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Reject Winner Claim',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.errorRed),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reject this winner claim? Please provide a reason.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Rejection reason (required)',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.errorRed),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
                ),
                filled: true,
                fillColor: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textLight),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
                return;
              }
              // rejectWinnerVerification already sends notification via _updateWinnerStatus -> _sendStatusUpdateNotification
              await _winnerService.rejectWinnerVerification(
                winner.id,
                reasonController.text,
              );
              if (mounted) Navigator.of(context).pop();
            },
            child: Text(
              'Reject',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
