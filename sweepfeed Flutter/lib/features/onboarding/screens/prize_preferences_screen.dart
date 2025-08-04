import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/services/auth_service.dart';
import '../../contests/screens/home_screen.dart';

class PrizePreferencesScreen extends StatefulWidget {
  const PrizePreferencesScreen({super.key});

  @override
  State<PrizePreferencesScreen> createState() => _PrizePreferencesScreenState();
}

class _PrizePreferencesScreenState extends State<PrizePreferencesScreen> {
  final Set<String> _selectedCategories = {};
  final String _selectedCountry = 'United States';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'cash',
      'title': 'Cash',
      'icon': Icons.attach_money,
    },
    {
      'id': 'gift_cards',
      'title': 'Gift Cards',
      'icon': Icons.card_giftcard,
    },
    {
      'id': 'electronics',
      'title': 'Electronics',
      'icon': Icons.phone_iphone,
    },
    {
      'id': 'vacations',
      'title': 'Vacations',
      'icon': Icons.beach_access,
    },
    {
      'id': 'home',
      'title': 'Home',
      'icon': Icons.home,
    },
    {
      'id': 'other',
      'title': 'Other',
      'icon': Icons.more_horiz,
    },
  ];

  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();

      // Update user preferences in Firestore
      await authService.updateUserProfile({
        'preferences': {
          'categories': _selectedCategories.toList(),
          'country': _selectedCountry,
        },
        'onboardingCompleted': true,
      });

      if (mounted) {
        // Navigate to home screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Icon and Welcome
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/icon/appicon.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.cleaning_services_rounded,
                          size: 50,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to',
                style: TextStyle(
                  fontSize: 24,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Sweep Feed',
                style: TextStyle(
                  fontSize: 32,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Question
              const Text(
                'What prizes are you interested in winning?',
                style: TextStyle(
                  fontSize: 24,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Prize Categories Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: _categories.map((category) {
                  final isSelected =
                      _selectedCategories.contains(category['id']);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCategories.remove(category['id']);
                        } else {
                          _selectedCategories.add(category['id']);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.surface,
                        border: Border.all(
                          color:
                              isSelected ? AppColors.primary : AppColors.border,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category['icon'],
                            size: 32,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category['title'],
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Country Selection
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Row(
                    children: [
                      Text(
                        _selectedCountry,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Implement country selection
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Get Started Button
              ElevatedButton(
                onPressed: _selectedCategories.isEmpty || _isLoading
                    ? null
                    : _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.backgroundDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.backgroundDark,
                          ),
                        ),
                      )
                    : const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
