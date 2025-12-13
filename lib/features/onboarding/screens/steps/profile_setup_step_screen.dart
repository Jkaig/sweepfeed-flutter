import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/logger.dart';
import '../../controllers/unified_onboarding_controller.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_template.dart';

class ProfileSetupStepScreen extends ConsumerStatefulWidget {
  const ProfileSetupStepScreen({
    required this.onNext,
    this.onSkip,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback? onSkip;

  @override
  ConsumerState<ProfileSetupStepScreen> createState() =>
      _ProfileSetupStepScreenState();
}

class _ProfileSetupStepScreenState
    extends ConsumerState<ProfileSetupStepScreen> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  File? _profileImage;
  bool _isLoading = false;
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      // Pre-fill display name from Auth if available
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _displayNameController.text = user.displayName!;
      }
      
      // Try to get existing profile data
      final profile = await _userService.getUserProfile(user.uid);
      if (profile != null && mounted) {
        if (profile.name != null && profile.name!.isNotEmpty) {
          _displayNameController.text = profile.name!;
        }
        if (profile.bio != null) {
          _bioController.text = profile.bio!;
        }
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
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
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      logger.w('Error picking image: $e');
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
          'To upload a profile picture, please allow access to your photos in settings.',
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

  Future<void> _saveAndContinue() async {
    if (_displayNameController.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Display name must be at least 2 characters'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authServiceProvider).currentUser;

      // If user is NOT authenticated, store data in provider for later sync
      if (user == null) {
        logger.i('User not authenticated - storing profile data for later sync');

        // Store profile data in provider
        final pendingNotifier = ref.read(pendingProfileDataProvider.notifier);
        pendingNotifier.setDisplayName(_displayNameController.text.trim());
        pendingNotifier.setBio(_bioController.text.trim());

        if (_profileImage != null) {
          pendingNotifier.setProfileImagePath(_profileImage!.path);
        }

        // Proceed to next step - data will be synced when user authenticates
        if (mounted) {
          widget.onNext();
        }
        return;
      }

      // User IS authenticated - save directly to Firebase
      final profileService = ref.read(profileServiceProvider);
      
      String? photoUrl;
      if (_profileImage != null) {
        // User selected a new image - upload it (highest priority)
        photoUrl = await profileService.uploadProfilePicture(
          user.uid,
          _profileImage!,
        );
      }

      // Update User Profile
      final updates = {
        'name': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
      };

      if (photoUrl != null) {
        updates['profilePictureUrl'] = photoUrl;
      }

      await _userService.updateUserProfile(user.uid, updates);

      // Award bonus points if photo was uploaded
      if (_profileImage != null) {
         try {
           await ref.read(dustBunniesServiceProvider).awardDustBunnies(
             userId: user.uid,
             action: 'profile_photo_upload',
             customAmount: 25,
           );
         } catch (_) {
           // Ignore point award errors
         }
      }

      if (mounted) {
        widget.onNext();
      }
    } catch (e) {
      logger.e('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
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
  Widget build(BuildContext context) => OnboardingTemplate(
      child: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Complete Your Profile',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
            const SizedBox(height: 8),
          Text(
              'Stand out and connect with others!',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
            const SizedBox(height: 32),
            
            // Profile Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      border: Border.all(
                        color: AppColors.brandCyan,
                        width: 2,
                      ),
                      image: _profileImage != null
                          ? DecorationImage(
                              image: FileImage(_profileImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profileImage == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.textLight,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.brandCyan,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryDark,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_profileImage == null) ...[
              const SizedBox(height: 12),
              Text(
                'Add a photo for +25 bonus points!',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.brandCyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Form Fields
            TextField(
              controller: _displayNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Display Name',
                labelStyle: const TextStyle(color: AppColors.textWhite),
                filled: true,
                fillColor: AppColors.primaryLight.withValues(alpha: 0.2),
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
                  borderSide: const BorderSide(color: AppColors.brandCyan),
                ),
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.textWhite),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio (Optional)',
                labelStyle: const TextStyle(color: AppColors.textWhite),
                filled: true,
                fillColor: AppColors.primaryLight.withValues(alpha: 0.2),
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
                  borderSide: const BorderSide(color: AppColors.brandCyan),
                ),
                prefixIcon: const Icon(Icons.description_outlined, color: AppColors.textWhite),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 32),

            // Continue Button
            if (_isLoading)
              const CircularProgressIndicator()
            else
          OnboardingButton(
            text: 'Continue',
                onPressed: _saveAndContinue,
          ),
              
            if (widget.onSkip != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onSkip,
                child: Text(
                  'Skip for now',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ],
        ],
        ),
      ),
    );
}
