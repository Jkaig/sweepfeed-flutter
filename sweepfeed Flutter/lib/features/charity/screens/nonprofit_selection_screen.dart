import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/every_org_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';

final everyOrgServiceProvider =
    Provider<EveryOrgService>((ref) => EveryOrgService());

final nonprofitSearchProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, query) async {
  if (query.isEmpty) return [];
  final service = ref.watch(everyOrgServiceProvider);
  final results = await service.searchNonprofits(query);

  final detailedResults = await Future.wait(
    results.map((nonprofit) async {
      final details = await service.getNonprofitDetails(nonprofit['slug']);
      return details ?? nonprofit;
    }),
  );

  return detailedResults;
});

class NonprofitSelectionScreen extends ConsumerStatefulWidget {
  const NonprofitSelectionScreen({super.key});

  @override
  ConsumerState<NonprofitSelectionScreen> createState() =>
      _NonprofitSelectionScreenState();
}

class _NonprofitSelectionScreenState
    extends ConsumerState<NonprofitSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isUpdating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectNonprofit(Map<String, dynamic> nonprofit) async {
    final currentUser = ref.read(firebaseServiceProvider).currentUser;
    if (currentUser == null) return;

    setState(() => _isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'selectedNonprofit': nonprofit['slug'],
        'selectedNonprofitName': nonprofit['name'],
        'selectedNonprofitDescription': nonprofit['description'],
        'selectedNonprofitLogo': nonprofit['logoUrl'],
        'selectedNonprofitEin': nonprofit['ein'],
        'selectedNonprofitIsVerified': nonprofit['isVerified'] ?? false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Now supporting: ${nonprofit['name']}'),
                ),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting nonprofit: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(nonprofitSearchProvider(_searchQuery));

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text(
          'Choose a Nonprofit',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.primaryMedium,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryMedium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search for a cause you care about',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textLight),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textWhite),
                  decoration: InputDecoration(
                    hintText: 'Search 1M+ nonprofits...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.accent),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.primaryLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    if (value.length >= 3) {
                      setState(() => _searchQuery = value);
                    } else if (value.isEmpty) {
                      setState(() => _searchQuery = '');
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildSearchResults(searchResultsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    AsyncValue<List<Map<String, dynamic>>> searchResultsAsync,
  ) {
    if (_searchQuery.isEmpty) {
      return _buildPopularNonprofits();
    }

    return searchResultsAsync.when(
      data: (nonprofits) {
        if (nonprofits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'No nonprofits found',
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textLight),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: nonprofits.length,
          itemBuilder: (context, index) =>
              _buildNonprofitCard(nonprofits[index]),
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading nonprofits',
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.errorRed),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularNonprofits() {
    final popularNonprofits = [
      {
        'slug': 'water-org',
        'name': 'Water.org',
        'description':
            'Empowering people with access to safe water and sanitation',
        'logo':
            'https://res.cloudinary.com/everydotorg/image/upload/c_lfill,w_24,h_24,dpr_2/c_crop,ar_24:24/q_auto,f_auto,fl_progressive/faja_profile/qmyglbf8oguqxbclz7ku',
      },
      {
        'slug': 'the-nature-conservancy',
        'name': 'The Nature Conservancy',
        'description': 'Protecting nature and preserving life',
        'logo':
            'https://res.cloudinary.com/everydotorg/image/upload/c_lfill,w_24,h_24,dpr_2/c_crop,ar_24:24/q_auto,f_auto,fl_progressive/profile_pics/logo-1_xmpwb9',
      },
      {
        'slug': 'doctors-without-borders',
        'name': 'Doctors Without Borders',
        'description': "Providing medical aid where it's needed most",
        'logo':
            'https://res.cloudinary.com/everydotorg/image/upload/c_lfill,w_24,h_24,dpr_2/c_crop,ar_24:24/q_auto,f_auto,fl_progressive/profile_pics/msf_logo_red',
      },
      {
        'slug': 'world-wildlife-fund',
        'name': 'World Wildlife Fund',
        'description': 'Conserving nature and reducing threats to biodiversity',
        'logo':
            'https://res.cloudinary.com/everydotorg/image/upload/c_lfill,w_24,h_24,dpr_2/c_crop,ar_24:24/q_auto,f_auto,fl_progressive/profile_pics/wwf-logo',
      },
      {
        'slug': 'american-red-cross',
        'name': 'American Red Cross',
        'description':
            'Preventing and alleviating human suffering in emergencies',
        'logo':
            'https://res.cloudinary.com/everydotorg/image/upload/c_lfill,w_24,h_24,dpr_2/c_crop,ar_24:24/q_auto,f_auto,fl_progressive/profile_pics/red-cross-logo',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Popular Nonprofits',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Or search above to find your cause',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        ...popularNonprofits.map(_buildNonprofitCard),
      ],
    );
  }

  Widget _buildNonprofitCard(Map<String, dynamic> nonprofit) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryLight.withAlpha(51)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isUpdating ? null : () => _selectNonprofit(nonprofit),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism,
                      color: AppColors.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                nonprofit['name'] ?? '',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (nonprofit['isVerified'] == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.successGreen
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified,
                                      color: AppColors.successGreen,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.successGreen,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nonprofit['description'] ?? '',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (nonprofit['ein'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'EIN: ${nonprofit['ein']} • 501(c)(3) Tax-Exempt',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    _isUpdating
                        ? Icons.hourglass_empty
                        : Icons.arrow_forward_ios,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
