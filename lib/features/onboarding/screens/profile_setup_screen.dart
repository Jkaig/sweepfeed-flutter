import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../utils/onboarding_constants.dart';
import '../widgets/common_onboarding_widgets.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    required this.onNext,
    required this.onSkip,
    super.key,
    this.currentStep = 5,
  });
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int currentStep;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  File? _profileImage;
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _hasPhoto = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
        _hasPhoto = true;
      });
    }
  }

  bool get _canContinue => _displayNameController.text.trim().length >= 2;

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        semanticLabel: OnboardingConstants.semanticProfileScreen,
        currentStep: widget.currentStep,
        skipButton: OnboardingSkipButton(onPressed: widget.onSkip),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primaryMedium],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: OnboardingConstants.verticalSpacingXXLarge,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Create Your Profile',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(duration: OnboardingConstants.fadeInDuration)
                        .slideY(),
                  ),
                  const SizedBox(
                    height: OnboardingConstants.verticalSpacingMedium,
                  ),
                  Text(
                    'Stand out and connect with others!',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: OnboardingConstants.fadeInDelayShort),
                  const SizedBox(
                    height: OnboardingConstants.verticalSpacingXXLarge,
                  ),
                  Semantics(
                    label: _hasPhoto
                        ? 'Profile photo uploaded. Tap to change.'
                        : 'Upload profile photo. Earn 25 DustBunnies!',
                    button: true,
                    child: Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.brandCyan.withValues(alpha: 0.3),
                                    Colors.deepPurple.withValues(alpha: 0.3),
                                  ],
                                ),
                                border: Border.all(
                                  color: AppColors.brandCyan,
                                  width: 3,
                                ),
                              ),
                              child: _profileImage != null
                                  ? ClipOval(
                                      child: Image.file(
                                        _profileImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppColors.textLight,
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
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
                                  size: 20,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: OnboardingConstants.fadeInDelayMedium)
                          .scale(),
                    ),
                  ),
                  const SizedBox(
                    height: OnboardingConstants.verticalSpacingMedium,
                  ),
                  if (_hasPhoto)
                    Semantics(
                      label:
                          'Congratulations! You earned 25 DustBunnies for uploading a photo',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OnboardingConstants.pillPaddingHorizontal,
                          vertical: OnboardingConstants.pillPaddingVertical,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green,
                            width: OnboardingConstants.borderWidth,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars,
                                color: Colors.amber, size: 20,),
                            const SizedBox(width: 8),
                            Text(
                              '+25 DustBunnies!',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().scale(),
                    )
                  else
                    Text(
                      'Add a photo for +25 DustBunnies!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.brandCyan,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayMedium),
                  const SizedBox(
                    height: OnboardingConstants.verticalSpacingXXLarge,
                  ),
                  Semantics(
                    label:
                        'Display name input field. Required. Minimum 2 characters.',
                    textField: true,
                    child: TextField(
                      controller: _displayNameController,
                      style:
                          AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Display Name *',
                        labelStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textLight,
                        ),
                        hintText: 'Enter your name',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor:
                            AppColors.primaryLight.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            OnboardingConstants.buttonBorderRadius,
                          ),
                          borderSide:
                              const BorderSide(color: AppColors.brandCyan),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            OnboardingConstants.buttonBorderRadius,
                          ),
                          borderSide: BorderSide(
                            color: AppColors.textMuted.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            OnboardingConstants.buttonBorderRadius,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.brandCyan,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayLong)
                        .slideX(),
                  ),
                  const SizedBox(
                    height: OnboardingConstants.verticalSpacingMedium,
                  ),
                  Semantics(
                    label: 'Bio input field. Optional. Maximum 150 characters.',
                    textField: true,
                    child: TextField(
                      controller: _bioController,
                      style:
                          AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                      maxLines: 3,
                      maxLength: 150,
                      decoration: InputDecoration(
                        labelText: 'Bio (Optional)',
                        labelStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textLight,
                        ),
                        hintText: 'Tell us about yourself...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor:
                            AppColors.primaryLight.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            OnboardingConstants.buttonBorderRadius,
                          ),
                          borderSide:
                              const BorderSide(color: AppColors.brandCyan),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            OnboardingConstants.buttonBorderRadius,
                          ),
                          borderSide: BorderSide(
                            color: AppColors.textMuted.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            OnboardingConstants.buttonBorderRadius,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.brandCyan,
                            width: 2,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayXLong)
                        .slideX(),
                  ),
                  const SizedBox(
                    height: OnboardingConstants.verticalSpacingXXLarge,
                  ),
                  OnboardingContinueButton(
                    onPressed: _canContinue ? widget.onNext : () {},
                    enabled: _canContinue,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 1000)),
                  const SizedBox(
                    height: OnboardingConstants.verticalSpacingMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
