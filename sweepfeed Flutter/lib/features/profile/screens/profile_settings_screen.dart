import 'dart:io'; // For File

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../reminders/screens/reminder_settings_screen.dart';
import '../services/profile_service.dart';
import 'brand_selection_screen.dart';
import 'charity_selection_screen.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final UserService _userService = UserService();
  late ProfileService _profileService;
  String? _currentUserId; // To store the actual user ID
  late Future<UserProfile?> _profileFuture;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<String> _interests = [];
  List<String> _favoriteBrands = [];
  File? _selectedImageFile; // To store the selected image file
  String? _currentProfilePictureUrl; // To store the current URL for display
  final List<String> _allInterests = ['Tech', 'Sports', 'Fashion', 'Travel'];
  final List<String> _allBrands = ['Nike', 'Adidas', 'Apple', 'Samsung'];
  bool _isLoading = true; // To manage loading state

  @override
  void initState() {
    super.initState();
    _profileService = ref.read(profileServiceProvider);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _isLoading = true;
      });
      _profileFuture = _userService.getUserProfile(_currentUserId!);
      final profile = await _profileFuture;
      if (mounted && profile != null) {
        setState(() {
          _nameController.text = profile.name ?? '';
          _currentProfilePictureUrl = profile.profilePictureUrl;
          _bioController.text = profile.bio ?? '';
          _locationController.text = profile.location ?? '';
          _interests = List<String>.from(profile.interests);
          _favoriteBrands = List<String>.from(profile.favoriteBrands);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No authenticated user found.')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!mounted) return;

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated. Cannot save profile.'),
        ),
      );
      return;
    }

    // Show loading indicator while saving
    setState(() => _isLoading = true);

    try {
      var newProfilePictureUrl = _currentProfilePictureUrl;

      // Upload new image if selected
      if (_selectedImageFile != null) {
        newProfilePictureUrl = await _profileService.uploadProfilePicture(
          _currentUserId!,
          _selectedImageFile!,
        );
        if (newProfilePictureUrl == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload profile picture.')),
          );
          setState(() => _isLoading = false);
          return; // Stop if upload failed
        }
      }

      final updatedProfile = UserProfile(
        id: _currentUserId!, // Use actual user ID
        name: _nameController.text,
        bio: _bioController.text,
        location: _locationController.text,
        profilePictureUrl: newProfilePictureUrl,
        interests: _interests,
        favoriteBrands: _favoriteBrands,
        reference:
            (await _userService.getUserProfile(_currentUserId!))!.reference,
      );

      await _userService.updateUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        Navigator.pop(context, true); // Pass true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildCheckboxList(
    String title,
    List<String> values,
    List<String> allValues,
    void Function(List<String>) onChanged,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: allValues
                .map(
                  (value) => FilterChip(
                    label: Text(
                      value,
                      style: TextStyle(
                        color: values.contains(value)
                            ? AppColors.primaryDark
                            : Colors.white,
                        fontWeight: values.contains(value)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: values.contains(value),
                    backgroundColor:
                        AppColors.primaryLight.withValues(alpha: 0.5),
                    selectedColor: AppColors.brandCyan,
                    checkmarkColor: AppColors.primaryDark,
                    side: BorderSide(
                      color: values.contains(value)
                          ? AppColors.brandCyan
                          : AppColors.primaryLight,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          values.add(value);
                        } else {
                          values.remove(value);
                        }
                        onChanged(values);
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: CustomAppBar(
          title: 'Edit Profile',
          leading: const CustomBackButton(),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: AppColors.brandCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.brandCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.save,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: (_isLoading || _currentUserId == null)
                    ? null
                    : _saveProfile,
                tooltip: 'Save Profile',
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _currentUserId == null
                ? const Center(
                    child: Text('User not authenticated. Please log in.'),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Profile Picture Section ---
                        Card(
                          color: AppColors.primaryMedium,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppColors.brandCyan.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.brandCyan
                                            .withValues(alpha: 0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: AppColors.primaryLight,
                                        backgroundImage: _selectedImageFile !=
                                                null
                                            ? FileImage(_selectedImageFile!)
                                            : (_currentProfilePictureUrl !=
                                                        null &&
                                                    _currentProfilePictureUrl!
                                                        .isNotEmpty
                                                ? CachedNetworkImageProvider(
                                                    _currentProfilePictureUrl!,
                                                  )
                                                : null) as ImageProvider?,
                                        child: (_selectedImageFile == null &&
                                                (_currentProfilePictureUrl ==
                                                        null ||
                                                    _currentProfilePictureUrl!
                                                        .isEmpty))
                                            ? const Icon(
                                                Icons.camera_alt,
                                                size: 30,
                                                color: AppColors.brandCyan,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(
                                      Icons.photo_camera,
                                      color: AppColors.brandCyan,
                                    ),
                                    label: const Text(
                                      'Change Profile Picture',
                                      style:
                                          TextStyle(color: AppColors.brandCyan),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- Personal Information Section ---
                        Card(
                          color: AppColors.primaryMedium,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppColors.brandCyan.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    labelStyle: const TextStyle(
                                        color: AppColors.textLight),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.brandCyan,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.primaryLight
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _bioController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Bio',
                                    labelStyle: const TextStyle(
                                        color: AppColors.textLight),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.brandCyan,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.primaryLight
                                        .withValues(alpha: 0.3),
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _locationController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Location',
                                    labelStyle: const TextStyle(
                                        color: AppColors.textLight),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.brandCyan,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.primaryLight
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // --- Preferences Section ---
                        Card(
                          color: AppColors.primaryMedium,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppColors.brandCyan.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Preferences',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildCheckboxList(
                                  'Interests',
                                  _interests,
                                  _allInterests,
                                  (values) =>
                                      setState(() => _interests = values),
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Favorite Brands',
                                          style: TextStyle(
                                            color: AppColors.textLight,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    BrandSelectionScreen(
                                                  selectedBrandNames:
                                                      _favoriteBrands,
                                                ),
                                              ),
                                            );
                                            if (result != null &&
                                                result is List<String>) {
                                              setState(
                                                () => _favoriteBrands = result,
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: AppColors.brandCyan,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Select Brands',
                                            style: TextStyle(
                                              color: AppColors.brandCyan,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (_favoriteBrands.isEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.primaryLight
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: AppColors.textLight,
                                              size: 20,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Select your favorite brands to see personalized sweepstakes',
                                                style: TextStyle(
                                                  color: AppColors.textLight,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Wrap(
                                        spacing: 8.0,
                                        runSpacing: 8.0,
                                        children: _favoriteBrands
                                            .map(
                                              (brand) => Chip(
                                                avatar: CircleAvatar(
                                                  backgroundColor: AppColors
                                                      .brandCyan
                                                      .withValues(alpha: 0.2),
                                                  child: const Icon(
                                                    Icons.business,
                                                    color: AppColors.brandCyan,
                                                    size: 16,
                                                  ),
                                                ),
                                                label: Text(
                                                  brand,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                deleteIcon: const Icon(
                                                  Icons.close,
                                                  color: AppColors.textLight,
                                                  size: 18,
                                                ),
                                                onDeleted: () {
                                                  setState(
                                                    () => _favoriteBrands
                                                        .remove(brand),
                                                  );
                                                },
                                                backgroundColor: AppColors
                                                    .primaryLight
                                                    .withValues(alpha: 0.5),
                                                side: BorderSide(
                                                  color: AppColors.brandCyan
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.brandCyan,
                                  AppColors.brandCyanDark,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandCyan
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: (_isLoading || _currentUserId == null)
                                  ? null
                                  : _saveProfile,
                              icon: _isLoading
                                  ? Container(
                                      width: 20,
                                      height: 20,
                                      padding: const EdgeInsets.all(2.0),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryDark,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.save,
                                      color: AppColors.primaryDark,
                                    ),
                              label: const Text(
                                'Save Profile',
                                style: TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // --- Quick Actions Section ---
                        Card(
                          color: AppColors.primaryMedium,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppColors.brandCyan.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    'Quick Actions',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandCyan
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_outlined,
                                      color: AppColors.brandCyan,
                                    ),
                                  ),
                                  title: const Text(
                                    'Reminder Settings',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppColors.textLight,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ReminderSettingsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                Divider(
                                  color: AppColors.primaryLight
                                      .withValues(alpha: 0.5),
                                  height: 1,
                                ),
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandCyan
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.volunteer_activism_outlined,
                                      color: AppColors.brandCyan,
                                    ),
                                  ),
                                  title: const Text(
                                    'Support a Charity',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppColors.textLight,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CharitySelectionScreen(),
                                      ),
                                    );
                                  },
                                ),
                                Divider(
                                  color: AppColors.primaryLight
                                      .withValues(alpha: 0.5),
                                  height: 1,
                                ),
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandCyan
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.shield_outlined,
                                      color: AppColors.brandCyan,
                                    ),
                                  ),
                                  title: const Text(
                                    'Privacy Policy',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppColors.textLight,
                                    size: 16,
                                  ),
                                  onTap: () =>
                                      _launchURL('https://yourapp.com/privacy'),
                                ),
                                Divider(
                                  color: AppColors.primaryLight
                                      .withValues(alpha: 0.5),
                                  height: 1,
                                ),
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandCyan
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.description_outlined,
                                      color: AppColors.brandCyan,
                                    ),
                                  ),
                                  title: const Text(
                                    'Terms of Service',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppColors.textLight,
                                    size: 16,
                                  ),
                                  onTap: () =>
                                      _launchURL('https://yourapp.com/terms'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      );

  Future<void> _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the link: $urlString')),
      );
    }
  }
}
