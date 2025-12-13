import 'package:flutter/material.dart';
import '../../contests/screens/home_screen.dart';
import 'profile_and_settings_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView(
        controller: _pageController,
        children: const [
          HomeScreen(),
          ProfileAndSettingsScreen(),
        ],
      );
}
