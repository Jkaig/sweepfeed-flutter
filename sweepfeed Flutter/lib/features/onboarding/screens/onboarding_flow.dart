import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../navigation/screens/main_screen.dart';
import 'charity_selection_screen.dart';
import 'interest_selection_screen.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_pageController.page == 1) {
      // Last page
      _saveOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveOnboarding() async {
    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
    final selectedInterests = ref.read(selectedInterestsProvider);
    final selectedCharities = ref.read(selectedCharitiesProvider);

    if (userId != null) {
      await ref
          .read(profileServiceProvider)
          .updateInterests(userId, selectedInterests);

      final charityIds = selectedCharities.map((c) => c.id).toList();
      await ref
          .read(profileServiceProvider)
          .updateCharities(userId, charityIds);

      await ref.read(userServiceProvider).markOnboardingComplete(userId);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swiping
          children: [
            InterestSelectionScreen(
              onNext: _onNextPage,
            ),
            CharitySelectionScreen(
              onNext: _onNextPage,
            ),
          ],
        ),
      );
}

final selectedInterestsProvider =
    StateNotifierProvider<SelectedInterestsNotifier, List<String>>(
        (ref) => SelectedInterestsNotifier());

class SelectedInterestsNotifier extends StateNotifier<List<String>> {
  SelectedInterestsNotifier() : super([]);

  void toggle(String interest) {
    if (state.contains(interest)) {
      state = state.where((item) => item != interest).toList();
    } else {
      state = [...state, interest];
    }
  }
}
