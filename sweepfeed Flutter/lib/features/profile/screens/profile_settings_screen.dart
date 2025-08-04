import 'dart:io'; // For File
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:cached_network_image/cached_network_image.dart'; 
import 'package:provider/provider.dart'; // Import Provider
import 'package:sweepfeed_app/core/models/user_profile.dart';
import 'package:sweepfeed_app/features/profile/services/profile_service.dart';
import 'package:sweepfeed_app/core/providers/theme_provider.dart'; // Import ThemeProvider

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final ProfileService _profileService = ProfileService();
  String? _currentUserId; // To store the actual user ID
  late Future<UserProfile?> _profileFuture;
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  // No longer using a text controller for profile picture URL directly
  // final TextEditingController _profilePictureUrlController = TextEditingController(); 
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
    // Initialize _profileFuture with a dummy future or handle null state in FutureBuilder
    _profileFuture = Future.value(null); 
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchCurrentUserAndProfile();
  }

  Future<void> _fetchCurrentUserAndProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _isLoading = true; // Start loading
      });
      _profileFuture = _profileService.getUserProfile(_currentUserId!).then((profile) {
        if (mounted) {
          setState(() {
            if (profile != null) {
              _currentProfilePictureUrl = profile.profilePictureUrl;
              _bioController.text = profile.bio ?? '';
              _locationController.text = profile.location ?? '';
              _interests = List<String>.from(profile.interests);
              _favoriteBrands = List<String>.from(profile.favoriteBrands);
            }
            _isLoading = false; // Stop loading
          });
        }
        return profile;
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _isLoading = false; // Stop loading on error
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading profile: $error')),
          );
        }
        return null; // Return null or handle error as appropriate
      });
    } else {
      // No user logged in
      if (mounted) {
         setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No authenticated user found. Please log in.')),
        );
        // Optionally, navigate away or disable UI elements
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
        const SnackBar(content: Text('User not authenticated. Cannot save profile.')),
      );
      return;
    }
    
    // Show loading indicator while saving
    setState(() => _isLoading = true);

    try {
      // UserProfile? existingProfile = await _profileFuture; // Not strictly needed if we reconstruct
      String? newProfilePictureUrl = _currentProfilePictureUrl;

      // Upload new image if selected
      if (_selectedImageFile != null) {
        newProfilePictureUrl = await _profileService.uploadProfilePicture(
            _currentUserId!, _selectedImageFile!);
        if (newProfilePictureUrl == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload profile picture.')),
          );
          setState(() => _isLoading = false);
          return; // Stop if upload failed
        }
      }

      UserProfile updatedProfile = UserProfile(
        id: _currentUserId!, // Use actual user ID
        bio: _bioController.text,
        location: _locationController.text,
        profilePictureUrl: newProfilePictureUrl,
        interests: _interests,
        favoriteBrands: _favoriteBrands,
      );

      await _profileService.updateUserProfile(updatedProfile);

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
      String title, List<String> values, List<String> allValues,
      void Function(List<String>) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        Wrap(
          children: allValues.map((value) {
            return FilterChip(
              label: Text(value),
              selected: values.contains(value),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    values.add(value);
                  } else {
                    values.remove(value);
                  }
                  onChanged(values);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: (_isLoading || _currentUserId == null) ? null : _saveProfile,
            tooltip: 'Save Profile',
          )
        ],
      ),
      body: _isLoading && _currentUserId == null // Initial loading or no user
          ? const Center(child: CircularProgressIndicator()) 
          : _currentUserId == null 
              ? const Center(child: Text('User not authenticated. Please log in.'))
              : FutureBuilder<UserProfile?>(
                  future: _profileFuture, // This future is now set up in _fetchCurrentUserAndProfile
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
                       // Show loading indicator if _isLoading is true OR if snapshot is waiting
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      // Data is loaded (or attempted to load and might be null)
                      // Controllers are set in _fetchCurrentUserAndProfile's .then()
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Profile Picture Section ---
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _selectedImageFile != null
                                ? FileImage(_selectedImageFile!)
                                : (_currentProfilePictureUrl != null &&
                                        _currentProfilePictureUrl!.isNotEmpty
                                    ? CachedNetworkImageProvider(
                                        _currentProfilePictureUrl!)
                                    : null) as ImageProvider?,
                            child: (_selectedImageFile == null &&
                                    (_currentProfilePictureUrl == null ||
                                        _currentProfilePictureUrl!.isEmpty))
                                ? Icon(Icons.camera_alt,
                                    size: 50, color: Colors.grey[700])
                                : null,
                          ),
                        ),
                        TextButton(
                          onPressed: _pickImage,
                          child: const Text('Change Profile Picture'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Other Profile Fields ---
                  TextField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                        labelText: 'Bio', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                        labelText: 'Location', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  _buildCheckboxList('Interests', _interests, _allInterests,
                      (List<String> values) => setState(() => _interests = values)),
                  const SizedBox(height: 16),
                  _buildCheckboxList(
                      'Favorite Brands',
                      _favoriteBrands,
                      _allBrands,
                      (List<String> values) => setState(() => _favoriteBrands = values)),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: (_isLoading || _currentUserId == null) ? null : _saveProfile,
                      icon: _isLoading 
                          ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) 
                          : const Icon(Icons.save),
                      label: const Text('Save Profile'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _buildThemeSelection(context),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildThemeSelection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RadioListTile<ThemeMode>(
          title: const Text('Light Mode'),
          value: ThemeMode.light,
          groupValue: themeProvider.themeMode,
          onChanged: (ThemeMode? value) {
            if (value != null) {
              themeProvider.setThemeMode(value);
            }
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Dark Mode'),
          value: ThemeMode.dark,
          groupValue: themeProvider.themeMode,
          onChanged: (ThemeMode? value) {
            if (value != null) {
              themeProvider.setThemeMode(value);
            }
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('System Default'),
          value: ThemeMode.system,
          groupValue: themeProvider.themeMode,
          onChanged: (ThemeMode? value) {
            if (value != null) {
              themeProvider.setThemeMode(value);
            }
          },
        ),
      ],
    );
  }
}