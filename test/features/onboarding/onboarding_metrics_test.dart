import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sweepfeed/features/onboarding/screens/adaptive_onboarding_wrapper.dart';

/// Focused tests for onboarding metrics functionality
/// Covers edge cases and performance tracking scenarios
void main() {
  group('OnboardingMetrics', () {
    test('should create metrics with default values', () {
      const metrics = OnboardingMetrics();

      expect(metrics.systemUsed, equals(''));
      expect(metrics.startTime, isNull);
      expect(metrics.completionTime, isNull);
      expect(metrics.stepsCompleted, equals(0));
      expect(metrics.totalSteps, equals(0));
      expect(metrics.duration, isNull);
      expect(metrics.completionRate, equals(0.0));
    });

    test('should create metrics with custom values', () {
      final startTime = DateTime.now();
      final completionTime = startTime.add(const Duration(minutes: 5));

      final metrics = OnboardingMetrics(
        systemUsed: 'new',
        startTime: startTime,
        completionTime: completionTime,
        stepsCompleted: 8,
        totalSteps: 10,
      );

      expect(metrics.systemUsed, equals('new'));
      expect(metrics.startTime, equals(startTime));
      expect(metrics.completionTime, equals(completionTime));
      expect(metrics.stepsCompleted, equals(8));
      expect(metrics.totalSteps, equals(10));
      expect(metrics.duration, equals(const Duration(minutes: 5)));
      expect(metrics.completionRate, equals(0.8));
    });

    test('should copy metrics with new values', () {
      const original = OnboardingMetrics(
        systemUsed: 'legacy',
        stepsCompleted: 3,
        totalSteps: 5,
      );

      final updated = original.copyWith(
        systemUsed: 'new',
        stepsCompleted: 4,
      );

      expect(updated.systemUsed, equals('new'));
      expect(updated.stepsCompleted, equals(4));
      expect(updated.totalSteps, equals(5)); // Unchanged
    });

    test('should calculate duration correctly', () {
      final startTime = DateTime(2024, 1, 1, 10);
      final completionTime =
          DateTime(2024, 1, 1, 10, 3, 30); // 3 minutes 30 seconds later

      final metrics = OnboardingMetrics(
        startTime: startTime,
        completionTime: completionTime,
      );

      expect(metrics.duration, equals(const Duration(minutes: 3, seconds: 30)));
    });

    test('should return null duration when times are incomplete', () {
      final startTime = DateTime.now();

      // Only start time
      var metrics = OnboardingMetrics(startTime: startTime);
      expect(metrics.duration, isNull);

      // Only completion time
      metrics = OnboardingMetrics(completionTime: startTime);
      expect(metrics.duration, isNull);

      // Neither time
      metrics = const OnboardingMetrics();
      expect(metrics.duration, isNull);
    });

    test('should calculate completion rate edge cases', () {
      // Zero total steps
      var metrics = const OnboardingMetrics(stepsCompleted: 5);
      expect(metrics.completionRate, equals(0.0));

      // Completed more than total (edge case)
      metrics = const OnboardingMetrics(stepsCompleted: 7, totalSteps: 5);
      expect(metrics.completionRate, equals(1.4));

      // Perfect completion
      metrics = const OnboardingMetrics(stepsCompleted: 10, totalSteps: 10);
      expect(metrics.completionRate, equals(1.0));

      // Partial completion
      metrics = const OnboardingMetrics(stepsCompleted: 3, totalSteps: 8);
      expect(metrics.completionRate, equals(0.375));
    });
  });

  group('OnboardingMetricsNotifier', () {
    late ProviderContainer container;
    late OnboardingMetricsNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(onboardingMetricsProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('should track onboarding flow lifecycle', () {
      // Start onboarding
      notifier.setSystemUsed('new');
      var metrics = container.read(onboardingMetricsProvider);
      expect(metrics.systemUsed, equals('new'));
      expect(metrics.startTime, isNotNull);
      final startTime = metrics.startTime!;

      // Progress through steps
      notifier.updateProgress(1, 5);
      metrics = container.read(onboardingMetricsProvider);
      expect(metrics.stepsCompleted, equals(1));
      expect(metrics.totalSteps, equals(5));
      expect(metrics.completionRate, equals(0.2));

      notifier.updateProgress(3, 5);
      metrics = container.read(onboardingMetricsProvider);
      expect(metrics.stepsCompleted, equals(3));
      expect(metrics.completionRate, equals(0.6));

      // Complete onboarding
      notifier.markComplete();
      metrics = container.read(onboardingMetricsProvider);
      expect(metrics.completionTime, isNotNull);
      expect(metrics.completionTime!.isAfter(startTime), isTrue);
      expect(metrics.duration, isNotNull);
    });

    test('should handle multiple system switches', () {
      // Start with new system
      notifier.setSystemUsed('new');
      expect(
          container.read(onboardingMetricsProvider).systemUsed, equals('new'),);

      // Switch to legacy system
      notifier.setSystemUsed('legacy');
      expect(container.read(onboardingMetricsProvider).systemUsed,
          equals('legacy'),);

      // Switch back to new system
      notifier.setSystemUsed('new');
      expect(
          container.read(onboardingMetricsProvider).systemUsed, equals('new'),);
    });

    test('should preserve progress when system changes', () {
      notifier.setSystemUsed('new');
      notifier.updateProgress(3, 7);

      // Change system but keep progress
      notifier.setSystemUsed('legacy');
      final metrics = container.read(onboardingMetricsProvider);
      expect(metrics.systemUsed, equals('legacy'));
      expect(metrics.stepsCompleted, equals(3));
      expect(metrics.totalSteps, equals(7));
    });

    test('should handle rapid progress updates', () {
      notifier.setSystemUsed('new');

      // Simulate rapid progress updates
      for (var i = 0; i <= 10; i++) {
        notifier.updateProgress(i, 10);
        final metrics = container.read(onboardingMetricsProvider);
        expect(metrics.stepsCompleted, equals(i));
        expect(metrics.completionRate, equals(i / 10.0));
      }
    });

    test('should handle edge case progress values', () {
      notifier.setSystemUsed('new');

      // Negative values (should still work for tracking errors)
      notifier.updateProgress(-1, 5);
      var metrics = container.read(onboardingMetricsProvider);
      expect(metrics.stepsCompleted, equals(-1));
      expect(metrics.completionRate, equals(-0.2));

      // Large values
      notifier.updateProgress(1000, 100);
      metrics = container.read(onboardingMetricsProvider);
      expect(metrics.stepsCompleted, equals(1000));
      expect(metrics.completionRate, equals(10.0));
    });

    test('should reset completely', () {
      // Set up a full metrics state
      notifier.setSystemUsed('new');
      notifier.updateProgress(5, 10);
      notifier.markComplete();

      // Verify state is set
      var metrics = container.read(onboardingMetricsProvider);
      expect(metrics.systemUsed, isNotEmpty);
      expect(metrics.startTime, isNotNull);
      expect(metrics.completionTime, isNotNull);
      expect(metrics.stepsCompleted, greaterThan(0));

      // Reset and verify clean state
      notifier.reset();
      metrics = container.read(onboardingMetricsProvider);
      expect(metrics.systemUsed, isEmpty);
      expect(metrics.startTime, isNull);
      expect(metrics.completionTime, isNull);
      expect(metrics.stepsCompleted, equals(0));
      expect(metrics.totalSteps, equals(0));
      expect(metrics.duration, isNull);
      expect(metrics.completionRate, equals(0.0));
    });

    test('should handle completion without setting system', () {
      // Mark complete without setting system first
      notifier.markComplete();
      final metrics = container.read(onboardingMetricsProvider);

      expect(metrics.completionTime, isNotNull);
      expect(metrics.systemUsed, isEmpty);
      expect(metrics.startTime, isNull);
      expect(metrics.duration, isNull);
    });

    test('should update start time when system changes', () {
      notifier.setSystemUsed('new');
      final firstStartTime =
          container.read(onboardingMetricsProvider).startTime!;

      // Small delay to ensure different timestamp
      Future.delayed(const Duration(milliseconds: 1), () {
        notifier.setSystemUsed('legacy');
        final secondStartTime =
            container.read(onboardingMetricsProvider).startTime!;

        expect(secondStartTime.isAfter(firstStartTime), isTrue);
      });
    });
  });

  group('Performance Scenarios', () {
    late ProviderContainer container;
    late OnboardingMetricsNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(onboardingMetricsProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('should track fast completion', () {
      notifier.setSystemUsed('new');
      notifier.updateProgress(5, 5); // Complete all steps quickly
      notifier.markComplete();

      final metrics = container.read(onboardingMetricsProvider);
      expect(metrics.completionRate, equals(1.0));
      expect(metrics.duration, isNotNull);
      expect(metrics.duration!.inMilliseconds, lessThan(1000)); // Very fast
    });

    test('should track abandoned onboarding', () {
      notifier.setSystemUsed('new');
      notifier.updateProgress(2, 10); // Only partial completion
      // No markComplete() call - simulates abandonment

      final metrics = container.read(onboardingMetricsProvider);
      expect(metrics.completionRate, equals(0.2));
      expect(metrics.completionTime, isNull);
      expect(metrics.duration, isNull);
    });

    test('should track non-linear completion', () {
      notifier.setSystemUsed('new');
      notifier.updateProgress(3, 5); // User gets to step 3
      notifier.updateProgress(1, 5); // User goes back to step 1
      notifier.updateProgress(5, 5); // User finishes
      notifier.markComplete();

      final metrics = container.read(onboardingMetricsProvider);
      expect(metrics.stepsCompleted, equals(5));
      expect(metrics.completionRate, equals(1.0));
      expect(metrics.completionTime, isNotNull);
    });

    test('should track system switching during onboarding', () {
      // Start with new system
      notifier.setSystemUsed('new');
      final newStartTime = container.read(onboardingMetricsProvider).startTime!;

      notifier.updateProgress(3, 10);

      // Switch to legacy system mid-flow
      notifier.setSystemUsed('legacy');
      final legacyStartTime =
          container.read(onboardingMetricsProvider).startTime!;

      notifier.updateProgress(7, 10);
      notifier.markComplete();

      final metrics = container.read(onboardingMetricsProvider);
      expect(metrics.systemUsed, equals('legacy'));
      expect(metrics.startTime, equals(legacyStartTime));
      expect(metrics.stepsCompleted, equals(7));
      expect(legacyStartTime.isAfter(newStartTime), isTrue);
    });
  });
}
