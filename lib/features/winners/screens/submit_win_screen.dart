import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../services/winner_verification_service.dart';

class SubmitWinScreen extends StatefulWidget {
  const SubmitWinScreen({super.key});

  @override
  State<SubmitWinScreen> createState() => _SubmitWinScreenState();
}

class _SubmitWinScreenState extends State<SubmitWinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contestNameController = TextEditingController();
  final _prizeDescController = TextEditingController();
  final _prizeValueController = TextEditingController();
  final _notesController = TextEditingController();
  File? _proofImage;
  bool _isLoading = false;
  final _verificationService = WinnerVerificationService();

  @override
  void dispose() {
    _contestNameController.dispose();
    _prizeDescController.dispose();
    _prizeValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final status = await Permission.photos.request();

    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionSettingsDialog();
      }
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _proofImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Handle error cleanly
    }
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: const Text(
          'Photo Access Required',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'To upload proof of your win, please allow access to your photos in settings.',
          style: TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandCyan),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a proof image (screenshot/photo).'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _verificationService.submitExternalWin(
        contestName: _contestNameController.text.trim(),
        prizeDescription: _prizeDescController.text.trim(),
        prizeValue: double.parse(_prizeValueController.text.trim()),
        proofImage: _proofImage!,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Win submitted successfully! We will review it shortly.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting win: $e'),
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
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Submit External Win'),
        backgroundColor: AppColors.primaryMedium,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryMedium,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: AppColors.accent, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Did you win a contest found on SweepFeed or elsewhere? Let us know!',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Contest Details',
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _contestNameController,
                label: 'Contest Name',
                hint: 'e.g. Nike Summer Giveaway',
                icon: Icons.flag,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _prizeDescController,
                label: 'Prize Description',
                hint: 'e.g. \$100 Gift Card',
                icon: Icons.card_giftcard,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _prizeValueController,
                label: 'Approx. Value (\$)',
                hint: '100.00',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Proof of Win',
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a screenshot of the winning email or notification.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryMedium,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _proofImage != null ? AppColors.successGreen : AppColors.primaryLight,
                      width: _proofImage != null ? 2 : 1,
                    ),
                    image: _proofImage != null
                        ? DecorationImage(
                            image: FileImage(_proofImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _proofImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: AppColors.textLight, size: 48),
                            SizedBox(height: 8),
                            Text('Tap to upload image', style: TextStyle(color: AppColors.textLight)),
                          ],
                        )
                      : null,
                ),
              ),
              if (_proofImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Change Image'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'Any extra details...',
                icon: Icons.note,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text(
                          'Submit Win',
                        style: TextStyle(
                            color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) => TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textLight),
        filled: true,
        fillColor: AppColors.primaryMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
          ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
                  ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed),
              ),
      ),
    );
}
