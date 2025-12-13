import 'package:cloud_firestore/cloud_firestore.dart'; // Required for Timestamp
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';
import '../../../core/security/security_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';

class SubmitContestScreen extends ConsumerStatefulWidget {
  const SubmitContestScreen({super.key});

  @override
  _SubmitContestScreenState createState() => _SubmitContestScreenState();
}

class _SubmitContestScreenState extends ConsumerState<SubmitContestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _prizeController = TextEditingController();
  final _entryUrlController = TextEditingController();
  final _rulesUrlController = TextEditingController(); // Optional
  final _sponsorController = TextEditingController(); // Optional
  final _categoriesController = TextEditingController(); // Comma-separated

  DateTime? _selectedEndDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _prizeController.dispose();
    _entryUrlController.dispose();
    _rulesUrlController.dispose();
    _sponsorController.dispose();
    _categoriesController.dispose();
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedEndDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        // Theme the picker
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              // Added const
              primary: AppColors.accent,
              onPrimary: AppColors.primaryDark,
              surface: AppColors.primaryMedium,
              onSurface: AppColors.textWhite,
            ),
            // Optional: Style other parts like button text
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent, // Button text color
              ),
            ),
            dialogTheme:
                const DialogThemeData(backgroundColor: AppColors.primaryMedium),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  Future<void> _submitContest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        // Added mounted check
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You must be logged in to submit.',
              style: AppTextStyles.bodyMedium,
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    // Sanitize all user inputs before sending to Firestore
    final sanitizedTitle = SecurityUtils.sanitizeString(_titleController.text.trim());
    final sanitizedPrize = SecurityUtils.sanitizeString(_prizeController.text.trim());
    final sanitizedEntryUrl = _entryUrlController.text.trim();
    final sanitizedRulesUrl = _rulesUrlController.text.trim().isEmpty
        ? null
        : _rulesUrlController.text.trim();
    final sanitizedSponsor = _sponsorController.text.trim().isEmpty
        ? null
        : SecurityUtils.sanitizeString(_sponsorController.text.trim());

    // Validate URLs
    if (!SecurityUtils.isValidUrl(sanitizedEntryUrl)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid entry URL'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    // Ensure all fields expected by Contest model are present or explicitly null
    final contestData = {
      'title': sanitizedTitle,
      // 'prize' in Contest model is String, using prizeDescription for clarity in submission
      'prize': sanitizedPrize,
      'entryUrl': sanitizedEntryUrl,
      'rulesUrl': sanitizedRulesUrl,
      'sponsor': sanitizedSponsor,
      'endDate': _selectedEndDate != null
          ? Timestamp.fromDate(_selectedEndDate!)
          : null,
      'categories': _categoriesController.text
          .split(',')
          .map((s) => SecurityUtils.sanitizeString(s.trim()))
          .where((s) => s.isNotEmpty)
          .toList(),

      // Default values for fields admin might fill or that are standard for user submissions
      'imageUrl': null, // Admin to add image or fetch from URL later
      'source': {
        'name': 'User Submitted',
        'url': sanitizedEntryUrl,
      },
      'frequency': 'once', // Default, admin can adjust
      'eligibility': 'US', // Default, admin can adjust
      'badges': <String>[], // Default empty
      'isPremium': false, // Default
      'platform': 'general', // Default
      'entryMethod': 'website', // Default, admin can adjust
      'prizeValue': null, // Admin to add or parse from prize description
      'isHot': false, // Default
      // 'createdAt' will be set by server timestamp in service if needed, or by Firestore itself
    };

    try {
      await ref
          .read(contestServiceProvider)
          .submitContestForReview(contestData, currentUser.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Contest submitted for review!',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Submission failed: ${e.toString()}',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            'Submit a Sweepstake',
            style:
                AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite),
          ),
          backgroundColor: AppColors.primaryMedium,
          iconTheme: const IconThemeData(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.primaryDark,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: 'Contest Title',
                  controller: _titleController,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Prize Description',
                  controller: _prizeController,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Entry URL',
                  controller: _entryUrlController,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Rules URL (Optional)',
                  controller: _rulesUrlController,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Sponsor Name (Optional)',
                  controller: _sponsorController,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'End Date',
                    hintText: _selectedEndDate == null
                        ? 'Select Date'
                        : DateFormat('MMMM d, yyyy').format(_selectedEndDate!),
                    prefixIcon: const Icon(
                      Icons.calendar_today,
                      color: AppColors.textLight,
                    ),
                    labelStyle: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textLight),
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: _selectedEndDate == null
                          ? AppColors.textMuted
                          : AppColors.textWhite,
                    ),
                    filled: true,
                    fillColor: AppColors.primaryMedium,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.primaryLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.primaryLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textWhite),
                  readOnly: true,
                  onTap: _pickEndDate,
                  validator: (value) => _selectedEndDate == null
                      ? 'Please select an end date'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Categories (comma-separated)',
                  controller: _categoriesController,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Submit for Review',
                  onPressed: _submitContest,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      );
}
