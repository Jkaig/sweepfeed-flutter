import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/biometric_auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../core/widgets/particle_painter.dart';
import '../../auth/screens/auth_wrapper.dart';
import 'adaptive_onboarding_wrapper.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Pulse controller for continuous glow effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Particle animation controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Staggered animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start animations
    _animationController.forward();

    // Navigate after animation
    Future.delayed(const Duration(milliseconds: 3000), _navigate);

    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    // Try biometric authentication first if enabled
    final biometricService = BiometricAuthService();
    final isBiometricsEnabled = await biometricService.isBiometricsEnabled();

    if (isBiometricsEnabled) {
      logger.i('Biometrics enabled, attempting biometric sign-in');
      final biometricUser = await biometricService.signInWithBiometrics();

      if (biometricUser != null) {
        logger.i('Successfully signed in with biometrics');
      } else {
        logger.w('Biometric sign-in failed, will try regular auth');
      }
    }

    // Check current user from Firebase Auth
    final user = ref.read(authStateChangesProvider).value ??
        FirebaseAuth.instance.currentUser;

    Widget nextScreen;

    if (user == null) {
      // No user - go to auth/login
      logger.i('No user found, navigating to AuthWrapper');
      nextScreen = const AuthWrapper();
    } else {
      // User is logged in - check onboarding status from Firestore
      logger.i('User ${user.uid} found, checking onboarding status');
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                logger.w('Firestore timeout checking onboarding status');
                throw TimeoutException('Firestore fetch timed out');
              },
            );
        
        final onboardingCompleted = userDoc.exists &&
            userDoc.data() != null &&
            (userDoc.data()!['onboardingCompleted'] as bool? ?? false);

        logger.i('User ${user.uid} onboardingCompleted: $onboardingCompleted');

        if (onboardingCompleted) {
          // Onboarding complete - go to main app via AuthWrapper
          nextScreen = const AuthWrapper();
        } else {
          // Onboarding not complete - show onboarding
          logger.i('User ${user.uid} needs onboarding');
          nextScreen = const AdaptiveOnboardingWrapper();
        }
      } catch (e) {
        // Error fetching user data - default to AuthWrapper which will handle state
        logger.w('Error fetching user data: $e, defaulting to AuthWrapper');
        nextScreen = const AuthWrapper();
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageTransitions.fadeTransition(
          page: nextScreen,
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.darkGradient,
          ),
          child: Stack(
            children: [
              // Animated particles/embers background
              AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) => CustomPaint(
                  painter: ParticlePainter(
                    progress: _particleController.value,
                    color: AppColors.brandCyan.withValues(alpha: 0.3),
                  ),
                  size: Size.infinite,
                ),
              ),
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Logo with scale and glow animation
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) => Transform.scale(
                        scale: _scaleAnimation.value,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandCyan.withValues(
                                    alpha: 0.5 * _glowAnimation.value,
                                  ),
                                  blurRadius: 50,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // App icon with rounded edges and pulse animation
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) => Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(35),
                                      child: Image.asset(
                                        'assets/icon/ios_app_icon_1024.png',
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title with slide animation
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                              children: [
                                // "Sweep" in white
                                TextSpan(
                                  text: 'Sweep',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                // "Feed" in cyan
                                TextSpan(
                                  text: 'Feed',
                                  style: TextStyle(
                                    color: AppColors.brandCyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tagline with delayed animation
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.5),
                        child: FadeTransition(
                          opacity: _glowAnimation,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) => Text(
                              'YOUR DAILY SHOT AT GLORY',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.brandCyan.withValues(
                                  alpha: 0.8 + (0.2 * _pulseAnimation.value),
                                ),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
