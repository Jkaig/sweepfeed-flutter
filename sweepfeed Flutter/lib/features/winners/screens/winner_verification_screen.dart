import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/winner_model.dart';
import '../../../core/theme/app_colors.dart';
import '../services/winner_verification_service.dart';

class WinnerVerificationScreen extends StatefulWidget {
  const WinnerVerificationScreen({
    required this.winner,
    super.key,
  });
  final Winner winner;

  @override
  State<WinnerVerificationScreen> createState() =>
      _WinnerVerificationScreenState();
}

class _WinnerVerificationScreenState extends State<WinnerVerificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _progressController;

  final WinnerVerificationService _verificationService =
      WinnerVerificationService();
  final ImagePicker _imagePicker = ImagePicker();

  final Map<String, File?> _selectedDocuments = {};
  final Map<String, bool> _uploadingDocuments = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Start celebration animation
    _celebrationController.forward();

    // Start progress animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressController.animateTo(widget.winner.verificationProgress);
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: IconButton(
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
                title: const Text(
                  'Prize Verification',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Celebration Header
              SliverToBoxAdapter(
                child: _buildCelebrationHeader(),
              ),

              // Verification Progress
              SliverToBoxAdapter(
                child: _buildVerificationProgress(),
              ),

              // Prize Details
              SliverToBoxAdapter(
                child: _buildPrizeDetails(),
              ),

              // Document Upload Section
              SliverToBoxAdapter(
                child: _buildDocumentUploadSection(),
              ),

              // Status Timeline
              SliverToBoxAdapter(
                child: _buildStatusTimeline(),
              ),

              // Action Buttons
              SliverToBoxAdapter(
                child: _buildActionButtons(),
              ),
            ],
          ),
        ),
      );

  Widget _buildCelebrationHeader() => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Celebration Icon
            AnimatedBuilder(
              animation: _celebrationController,
              builder: (context, child) => Transform.scale(
                scale: 1 + (_celebrationController.value * 0.2),
                child: Transform.rotate(
                  angle: _celebrationController.value * 0.1,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.cyberYellow,
                          AppColors.accent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyberYellow.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      size: 60,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .scale(duration: 800.ms, curve: Curves.elasticOut)
                .then()
                .shimmer(duration: 2.seconds),

            const SizedBox(height: 24),

            // Congratulations Text
            const Text(
              '🎉 Congratulations! 🎉',
              style: TextStyle(
                color: AppColors.cyberYellow,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 8),

            const Text(
              "You've won a prize!",
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

            const SizedBox(height: 16),

            // Contest Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: AppColors.cyberYellow.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                widget.winner.contestTitle,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8)),
          ],
        ),
      );

  Widget _buildVerificationProgress() => Container(
        margin: const EdgeInsets.all(20),
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
            const Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: AppColors.cyberYellow,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Verification Progress',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Bar
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) => Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(_progressController.value * 100).round()}% Complete',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${widget.winner.submittedDocuments.length}/${widget.winner.requiredDocuments.length} Documents',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progressController.value,
                      minHeight: 12,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _progressController.value >= 1.0
                            ? AppColors.neonGreen
                            : AppColors.cyberYellow,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (widget.winner.isVerificationComplete) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.neonGreen.withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.neonGreen,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Verification Complete!',
                      style: TextStyle(
                        color: AppColors.neonGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      )
          .animate()
          .fadeIn(delay: 900.ms, duration: 600.ms)
          .slideX(begin: 0.1, end: 0);

  Widget _buildPrizeDetails() => Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prize Details',
              style: TextStyle(
                color: AppColors.cyberYellow,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.card_giftcard,
              label: 'Prize',
              value: widget.winner.prizeDescription,
            ),
            _buildDetailRow(
              icon: Icons.attach_money,
              label: 'Value',
              value: '\$${widget.winner.prizeValue.toStringAsFixed(2)}',
            ),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Won On',
              value: _formatDate(widget.winner.winDate),
            ),
            if (widget.winner.claimDeadline != null)
              _buildDetailRow(
                icon: Icons.access_time,
                label: 'Claim Deadline',
                value: _formatDate(widget.winner.claimDeadline!),
                isUrgent: widget.winner.daysUntilDeadline <= 7,
              ),
            _buildDetailRow(
              icon: Icons.local_shipping,
              label: 'Delivery Method',
              value: _getClaimMethodText(widget.winner.claimMethod),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: 1100.ms, duration: 600.ms)
          .slideX(begin: -0.1, end: 0);

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isUrgent = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isUrgent ? Colors.orange : AppColors.cyberYellow,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: isUrgent ? Colors.orange : AppColors.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildDocumentUploadSection() {
    if (widget.winner.requiredDocuments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(20),
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
            'Required Documents',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.winner.requiredDocuments.map((document) {
            final isSubmitted =
                widget.winner.submittedDocuments.contains(document);
            final isUploading = _uploadingDocuments[document] ?? false;

            return _buildDocumentUploadCard(
              documentType: document,
              isSubmitted: isSubmitted,
              isUploading: isUploading,
            );
          }),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 1300.ms, duration: 600.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildDocumentUploadCard({
    required String documentType,
    required bool isSubmitted,
    required bool isUploading,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSubmitted
              ? AppColors.neonGreen.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSubmitted
                ? AppColors.neonGreen.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Document Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isSubmitted ? AppColors.neonGreen : AppColors.cyberYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSubmitted ? Icons.check_circle : Icons.description,
                color: Colors.white,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Document Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDocumentDisplayName(documentType),
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSubmitted
                        ? 'Document submitted'
                        : 'Tap to upload document',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Upload Button
            if (!isSubmitted)
              GestureDetector(
                onTap: isUploading ? null : () => _uploadDocument(documentType),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cyberYellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryDark,
                            ),
                          ),
                        )
                      : const Text(
                          'Upload',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
          ],
        ),
      );

  Widget _buildStatusTimeline() {
    final statuses = [
      {
        'title': 'Prize Won',
        'subtitle': 'Congratulations on your win!',
        'completed': true,
        'date': widget.winner.winDate,
      },
      {
        'title': 'Documentation Required',
        'subtitle': 'Upload required verification documents',
        'completed': widget.winner.isVerificationComplete,
        'date': null,
      },
      {
        'title': 'Verification Review',
        'subtitle': 'Our team will review your submission',
        'completed': widget.winner.isVerified || widget.winner.isClaimed,
        'date': null,
      },
      {
        'title': 'Prize Delivery',
        'subtitle': 'Your prize will be delivered',
        'completed': widget.winner.isClaimed,
        'date': null,
      },
    ];

    return Container(
      margin: const EdgeInsets.all(20),
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
            'Prize Claim Timeline',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isLast = index == statuses.length - 1;

            return _buildTimelineItem(
              title: status['title']! as String,
              subtitle: status['subtitle']! as String,
              isCompleted: status['completed']! as bool,
              date: status['date'] as DateTime?,
              isLast: isLast,
            );
          }),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 1500.ms, duration: 600.ms)
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isLast,
    DateTime? date,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.neonGreen
                      : Colors.grey.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.neonGreen
                        : Colors.grey.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.circle,
                  color: isCompleted ? Colors.white : Colors.grey,
                  size: 16,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(date),
                      style: const TextStyle(
                        color: AppColors.cyberYellow,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildActionButtons() => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Primary Action Button
            if (!widget.winner.isVerificationComplete)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _uploadAllDocuments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyberYellow,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.primaryDark,
                        )
                      : const Text(
                          'Upload Missing Documents',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

            const SizedBox(height: 12),

            // Secondary Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to support/help
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textWhite,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Need Help?'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Share win on social media
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cyberYellow,
                      side: BorderSide(
                        color: AppColors.cyberYellow.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Share Win'),
                  ),
                ),
              ],
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: 1700.ms, duration: 600.ms)
          .slideY(begin: 0.1, end: 0);

  // Helper methods
  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

  String _getClaimMethodText(PrizeClaimMethod method) {
    switch (method) {
      case PrizeClaimMethod.digital:
        return 'Digital Delivery';
      case PrizeClaimMethod.mail:
        return 'Mail Delivery';
      case PrizeClaimMethod.pickup:
        return 'In-Person Pickup';
      case PrizeClaimMethod.directDeposit:
        return 'Direct Deposit';
    }
  }

  String _getDocumentDisplayName(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'id':
        return 'Government ID';
      case 'address':
        return 'Proof of Address';
      case 'tax':
        return 'Tax Information';
      case 'affidavit':
        return 'Affidavit of Eligibility';
      default:
        return documentType.replaceAll('_', ' ').toUpperCase();
    }
  }

  Future<void> _uploadDocument(String documentType) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _uploadingDocuments[documentType] = true;
        });

        final file = File(image.path);
        final success = await _verificationService.submitVerificationDocument(
          winnerId: widget.winner.id,
          documentType: documentType,
          documentFile: file,
        );

        if (success) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document uploaded successfully!'),
              backgroundColor: AppColors.neonGreen,
            ),
          );

          // Refresh the screen or update state as needed
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload document. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _uploadingDocuments[documentType] = false;
      });
    }
  }

  Future<void> _uploadAllDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Logic to upload all missing documents
      final missingDocuments = widget.winner.requiredDocuments
          .where((doc) => !widget.winner.submittedDocuments.contains(doc))
          .toList();

      for (final document in missingDocuments) {
        await _uploadDocument(document);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
