import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/models/user_model.dart';
import '../../../core/theme/app_colors.dart';

class ProfilePictureAvatar extends StatelessWidget {
  const ProfilePictureAvatar({
    required this.user,
    super.key,
    this.radius = 50.0,
  });
  final UserProfile user;
  final double radius;

  // This is a placeholder. In a real app, you'd fetch this from your CharityService based on user.selectedCharityId.
  String? get _charityEmblemUrl {
    if (user.selectedCharityId == 'world_wildlife_fund') {
      return 'https://i.imgur.com/8529911.png'; // Placeholder Panda Logo
    }
    return null;
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (uri.scheme != 'https' && uri.scheme != 'http')) {
        return false;
      }

      final validHosts = [
        'firebasestorage.googleapis.com',
        'storage.googleapis.com',
        'i.imgur.com',
      ];

      if (!validHosts.any((host) => uri.host.endsWith(host))) {
        return false;
      }

      final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
      final path = uri.path.toLowerCase();
      if (!validExtensions.any(path.contains)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final charityEmblem = _charityEmblemUrl;
    final isValidUrl = _isValidImageUrl(user.profilePictureUrl);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.brandCyan.withValues(alpha: 0.2),
          backgroundImage: isValidUrl
              ? CachedNetworkImageProvider(user.profilePictureUrl!)
              : const AssetImage('assets/icon/appicon.png') as ImageProvider,
        ),
        if (charityEmblem != null)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: radius * 0.25,
                backgroundImage: CachedNetworkImageProvider(charityEmblem),
              ),
            ),
          ),
      ],
    );
  }
}
