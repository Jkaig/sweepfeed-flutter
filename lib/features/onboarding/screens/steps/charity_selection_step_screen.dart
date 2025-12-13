import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../controllers/unified_onboarding_controller.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_template.dart';

class CharitySelectionStepScreen extends ConsumerStatefulWidget {
  const CharitySelectionStepScreen({
    required this.onNext,
    this.onSkip,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback? onSkip;

  @override
  ConsumerState<CharitySelectionStepScreen> createState() =>
      _CharitySelectionStepScreenState();
}

class _CharitySelectionStepScreenState
    extends ConsumerState<CharitySelectionStepScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double _rotationAngle = 0;
  int _selectedIndex = 0;

  // Real Every.org nonprofit slugs for verified 501(c)(3) organizations
  final List<Map<String, String>> charities = [
    {
      'id': 'american-red-cross',
      'slug': 'american-red-cross',
      'name': 'American Red Cross',
      'description': 'Emergency assistance and disaster relief worldwide',
      'category': 'Emergency Relief',
      'icon': 'emergency',
    },
    {
      'id': 'doctors-without-borders-usa',
      'slug': 'doctors-without-borders-usa',
      'name': 'Doctors Without Borders',
      'description': "Medical aid where it's needed most",
      'category': 'Healthcare',
      'icon': 'medical',
    },
    {
      'id': 'world-wildlife-fund',
      'slug': 'world-wildlife-fund',
      'name': 'World Wildlife Fund',
      'description': 'Protecting endangered species and habitats',
      'category': 'Environment',
      'icon': 'eco',
    },
    {
      'id': 'feeding-america',
      'slug': 'feeding-america',
      'name': 'Feeding America',
      'description': 'Fighting hunger across the United States',
      'category': 'Hunger Relief',
      'icon': 'food',
    },
    {
      'id': 'st-jude-childrens-research-hospital',
      'slug': 'st-jude-childrens-research-hospital',
      'name': "St. Jude Children's",
      'description': 'Leading pediatric treatment and research',
      'category': 'Healthcare',
      'icon': 'health',
    },
    {
      'id': 'habitat-for-humanity-international',
      'slug': 'habitat-for-humanity-international',
      'name': 'Habitat for Humanity',
      'description': 'Building homes and communities worldwide',
      'category': 'Housing',
      'icon': 'home',
    },
    {
      'id': 'unicef-usa',
      'slug': 'unicef-usa',
      'name': 'UNICEF USA',
      'description': 'Helping children survive and thrive globally',
      'category': 'Children',
      'icon': 'child',
    },
    {
      'id': 'the-nature-conservancy',
      'slug': 'the-nature-conservancy',
      'name': 'Nature Conservancy',
      'description': 'Protecting lands and waters for future generations',
      'category': 'Environment',
      'icon': 'eco',
    },
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _rotateToIndex(int index) {
    final anglePerItem = (2 * math.pi) / charities.length;
    final targetAngle = -index * anglePerItem;

    final animation = Tween<double>(
      begin: _rotationAngle,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOutBack,
    ),);

    animation.addListener(() {
      setState(() {
        _rotationAngle = animation.value;
      });
    });

    _rotationController.forward(from: 0);
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleDrag(DragUpdateDetails details) {
    setState(() {
      _rotationAngle += details.delta.dx * 0.01;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    // Snap to nearest charity
    final anglePerItem = (2 * math.pi) / charities.length;
    final normalizedAngle = _rotationAngle % (2 * math.pi);
    final nearestIndex =
        ((-normalizedAngle) / anglePerItem).round() % charities.length;
    _rotateToIndex(nearestIndex);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCharities = ref.watch(selectedCharitiesProvider);

    return OnboardingTemplate(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Skip button at top right
          if (widget.onSkip != null)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 8),
                child: TextButton(
                  onPressed: widget.onSkip,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Title
          Text(
            'Choose Charities',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle with multi-select info
          Text(
            'Select one or more charities',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Multi-select hint
          Text(
            'Your ad revenue will be split among your selections',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Selection indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: selectedCharities.isNotEmpty
                  ? AppColors.successGreen.withValues(alpha: 0.2)
                  : AppColors.primaryLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              selectedCharities.isEmpty
                  ? 'Tap charities to select'
                  : '${selectedCharities.length} ${selectedCharities.length == 1 ? 'charity' : 'charities'} selected',
              style: AppTextStyles.bodyMedium.copyWith(
                color: selectedCharities.isNotEmpty
                    ? AppColors.successGreen
                    : AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3D Rotating Charity Balls
          Expanded(
            child: GestureDetector(
              onHorizontalDragUpdate: _handleDrag,
              onHorizontalDragEnd: _handleDragEnd,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Charity balls in 3D circular arrangement
                  ...List.generate(charities.length, (index) => _buildCharityBall(context, ref, index)),
                ],
              ),
            ),
          ),

          // Info card for selected charity
          _buildInfoCard(ref),

          const SizedBox(height: 16),

          // Continue button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OnboardingButton(
              text: selectedCharities.isEmpty ? 'Skip for now' : 'Continue',
              onPressed: widget.onNext,
              isPrimary: selectedCharities.isNotEmpty,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCharityBall(BuildContext context, WidgetRef ref, int index) {
    final selectedCharities = ref.watch(selectedCharitiesProvider);
    final charity = charities[index];
    final isSelected = selectedCharities.any((c) => c['id'] == charity['id']);

    // Calculate 3D position on the circle
    final anglePerItem = (2 * math.pi) / charities.length;
    final itemAngle = _rotationAngle + (index * anglePerItem);

    // Calculate position on ellipse (3D perspective)
    const radiusX = 120.0; // Horizontal radius
    const radiusY = 40.0; // Vertical radius (creates depth illusion)
    final x = math.cos(itemAngle) * radiusX;
    final y = math.sin(itemAngle) * radiusY;

    // Calculate z-depth for scaling (front items are bigger)
    final zDepth = math.sin(itemAngle);
    final scale = 0.6 + (0.4 * ((zDepth + 1) / 2)); // Scale from 0.6 to 1.0
    final opacity = 0.5 + (0.5 * ((zDepth + 1) / 2)); // Opacity from 0.5 to 1.0

    // Ball size
    const baseSize = 90.0;
    final size = baseSize * scale;

    // Z-index based on position (front items on top)
    final zIndex = ((zDepth + 1) * 100).toInt();

    return Positioned(
      left: MediaQuery.of(context).size.width / 2 + x - size / 2 - 24,
      top: 140 + y - size / 2,
      child: GestureDetector(
        onTap: () {
          ref.read(selectedCharitiesProvider.notifier).toggle(charity);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          child: Opacity(
            opacity: opacity,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.5),
                  colors: isSelected
                      ? [
                          AppColors.successGreen,
                          AppColors.successGreen.withValues(alpha: 0.7),
                          AppColors.successGreen.withValues(alpha: 0.4),
                        ]
                      : [
                          _getCategoryColor(charity['category']!),
                          _getCategoryColor(charity['category']!)
                              .withValues(alpha: 0.7),
                          _getCategoryColor(charity['category']!)
                              .withValues(alpha: 0.4),
                        ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.successGreen.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: isSelected ? 3 : 0,
                    offset: const Offset(0, 5),
                  ),
                  // Inner glow at top for 3D effect
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: -5,
                    offset: Offset(-size * 0.1, -size * 0.1),
                  ),
                ],
                border: isSelected
                    ? Border.all(
                        color: Colors.white,
                        width: 3,
                      )
                    : null,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCharityIcon(charity['category']!),
                      size: size * 0.35,
                      color: Colors.white,
                    ),
                    if (scale > 0.8) ...[
                      const SizedBox(height: 4),
                      Text(
                        charity['name']!.split(' ').first,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size * 0.12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        size: size * 0.2,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(WidgetRef ref) {
    final selectedCharities = ref.watch(selectedCharitiesProvider);

    // If charities are selected, show them in a scrollable list
    if (selectedCharities.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        constraints: const BoxConstraints(maxHeight: 180),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.successGreen.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.successGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your Selected Charities',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: selectedCharities.length,
                itemBuilder: (context, index) {
                  final charity = selectedCharities[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getCategoryColor(charity['category'] ?? 'default'),
                            ),
                            child: Icon(
                              _getCharityIcon(charity['category'] ?? 'default'),
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  charity['name'] ?? '',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  charity['category'] ?? '',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ref.read(selectedCharitiesProvider.notifier).toggle(charity);
                            },
                            child: Icon(
                              Icons.close,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // If no charities selected, show the currently focused charity
    final charity = charities[_selectedIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getCategoryColor(charity['category']!),
                ),
                child: Icon(
                  _getCharityIcon(charity['category']!),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  charity['name']!,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            charity['description']!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getCategoryColor(charity['category']!).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              charity['category']!,
              style: TextStyle(
                color: _getCategoryColor(charity['category']!),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'emergency relief':
        return Colors.red;
      case 'healthcare':
        return Colors.blue;
      case 'environment':
        return Colors.green;
      case 'hunger relief':
        return Colors.orange;
      case 'education':
        return Colors.purple;
      case 'housing':
        return Colors.amber;
      case 'children':
        return Colors.pink;
      default:
        return AppColors.accent;
    }
  }

  IconData _getCharityIcon(String category) {
    switch (category.toLowerCase()) {
      case 'emergency relief':
        return Icons.emergency;
      case 'healthcare':
        return Icons.medical_services;
      case 'environment':
        return Icons.eco;
      case 'hunger relief':
        return Icons.restaurant;
      case 'education':
        return Icons.school;
      case 'housing':
        return Icons.home;
      case 'children':
        return Icons.child_care;
      default:
        return Icons.favorite;
    }
  }
}
