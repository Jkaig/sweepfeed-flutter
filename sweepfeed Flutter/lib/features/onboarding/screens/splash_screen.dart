import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweep_feed/main.dart'; // For AuthWrapper
import 'package:sweep_feed/features/onboarding/screens/onboarding_screen_1.dart';
import 'package:sweep_feed/common/widgets/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    Timer(const Duration(seconds: 3), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    final user = Provider.of<User?>(context, listen: false);

    if (user == null) {
      // Not logged in
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    } else {
      // Logged in, check onboarding status
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        bool onboardingCompleted = false;
        if (userDoc.exists && userDoc.data() != null && userDoc.data()!.containsKey('onboardingCompleted')) {
          onboardingCompleted = userDoc.data()!['onboardingCompleted'] as bool;
        } else {
          // If field doesn't exist, assume onboarding is not completed.
          // Optionally, update Firestore to set it to false if it's missing.
          // This case should ideally be handled at user creation in AuthWrapper or AuthService.
          // For safety here, treat as not completed.
          // await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'onboardingCompleted': false}, SetOptions(merge: true));
        }

        if (onboardingCompleted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthWrapper()), // AuthWrapper will lead to MainScreen
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen1()),
          );
        }
      } catch (e) {
        // Error fetching user data, fallback to login/auth wrapper
        debugPrint("Error fetching onboarding status: $e");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundDark,
              Color(0xFF0A2A4F), // Slightly lighter shade
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/icon/appicon.png', // Ensure this path is correct
                  width: 150, // Adjust size as needed
                  height: 150,
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  "SweepFeed",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  "Your Sweepstakes Feed",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70, // Slightly less prominent
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
