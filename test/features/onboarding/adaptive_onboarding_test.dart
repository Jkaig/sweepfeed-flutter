import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sweepfeed/core/models/onboarding_config.dart';
import 'package:sweepfeed/features/onboarding/screens/adaptive_onboarding_wrapper.dart';

/// Unit tests for the adaptive onboarding integration
/// Tests providers, state management, and component behavior
void main() {
  group('AdaptiveOnboardingWrapper', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('useNewOnboardingProvider', () {
      test('should default to true (new system enabled)', () {
        final useNewOnboarding = container.read(useNewOnboardingProvider);
        expect(useNewOnboarding, isTrue);
      });

      test('should allow toggling the feature flag', () {
        // Initial state should be true
        expect(container.read(useNewOnboardingProvider), isTrue);

        // Toggle to false
        container.read(useNewOnboardingProvider.notifier).state = false;
        expect(container.read(useNewOnboardingProvider), isFalse);

        // Toggle back to true
        container.read(useNewOnboardingProvider.notifier).state = true;
        expect(container.read(useNewOnboardingProvider), isTrue);
      });

      test('should maintain state consistency across reads', () {
        // Set to false
        container.read(useNewOnboardingProvider.notifier).state = false;

        // Multiple reads should return the same value
        expect(container.read(useNewOnboardingProvider), isFalse);
        expect(container.read(useNewOnboardingProvider), isFalse);
        expect(container.read(useNewOnboardingProvider), isFalse);
      });
    });

    group('adaptiveOnboardingConfigProvider', () {
      test('should return default config', () {
        final config = container.read(adaptiveOnboardingConfigProvider);
        expect(config, equals(OnboardingConfig.defaultConfig));
      });

      test('should return consistent config across reads', () {
        final config1 = container.read(adaptiveOnboardingConfigProvider);
        final config2 = container.read(adaptiveOnboardingConfigProvider);
        expect(config1, equals(config2));
      });

      test('should have valid configuration properties', () {
        final config = container.read(adaptiveOnboardingConfigProvider);

        // Validate basic config properties
        expect(config.steps, isNotEmpty);
        expect(config.welcomeBonusPoints, greaterThanOrEqualTo(0));
        expect(config.totalSteps, equals(config.steps.length));
      });
    });

    group('OnboardingMetricsNotifier', () {
      late OnboardingMetricsNotifier notifier;

      setUp(() {
        notifier = container.read(onboardingMetricsProvider.notifier);
      });

      test('should have initial empty state', () {
        final metrics = container.read(onboardingMetricsProvider);
        expect(metrics.systemUsed, isEmpty);
        expect(metrics.startTime, isNull);
        expect(metrics.completionTime, isNull);
        expect(metrics.stepsCompleted, equals(0));
        expect(metrics.totalSteps, equals(0));
        expect(metrics.completionRate, equals(0.0));
        expect(metrics.duration, isNull);
      });

      test('should set system used and start time', () {
        notifier.setSystemUsed('new');
        final metrics = container.read(onboardingMetricsProvider);

        expect(metrics.systemUsed, equals('new'));
        expect(metrics.startTime, isNotNull);
        expect(
            metrics.startTime!
                .isBefore(DateTime.now().add(const Duration(seconds: 1))),
            isTrue,);
      });

      test('should update progress correctly', () {
        notifier.updateProgress(3, 5);
        final metrics = container.read(onboardingMetricsProvider);

        expect(metrics.stepsCompleted, equals(3));
        expect(metrics.totalSteps, equals(5));
        expect(metrics.completionRate, equals(0.6));
      });

      test('should calculate completion rate correctly', () {
        // Test various completion scenarios
        notifier.updateProgress(0, 5);
        expect(container.read(onboardingMetricsProvider).completionRate,
            equals(0.0),);

        notifier.updateProgress(2, 5);
        expect(container.read(onboardingMetricsProvider).completionRate,
            equals(0.4),);

        notifier.updateProgress(5, 5);
        expect(container.read(onboardingMetricsProvider).completionRate,
            equals(1.0),);
      });

      test('should handle division by zero in completion rate', () {
        notifier.updateProgress(5, 0);
        final metrics = container.read(onboardingMetricsProvider);
        expect(metrics.completionRate, equals(0.0));
      });

      test('should mark completion and calculate duration', () {
        // Set system and start time
        notifier.setSystemUsed('new');
        final startTime = container.read(onboardingMetricsProvider).startTime!;

        // Wait a small amount to ensure different timestamps
        Future.delayed(const Duration(milliseconds: 10), () {
          notifier.markComplete();
          final metrics = container.read(onboardingMetricsProvider);

          expect(metrics.completionTime, isNotNull);
          expect(metrics.duration, isNotNull);
          expect(metrics.duration!.inMilliseconds, greaterThan(0));
          expect(metrics.completionTime!.isAfter(startTime), isTrue);
        });
      });

      test('should reset metrics correctly', () {
        // Set some data
        notifier.setSystemUsed('legacy');
        notifier.updateProgress(3, 7);
        notifier.markComplete();

        // Verify data is set
        var metrics = container.read(onboardingMetricsProvider);
        expect(metrics.systemUsed, equals('legacy'));
        expect(metrics.stepsCompleted, equals(3));

        // Reset and verify
        notifier.reset();
        metrics = container.read(onboardingMetricsProvider);
        expect(metrics.systemUsed, isEmpty);
        expect(metrics.startTime, isNull);
        expect(metrics.completionTime, isNull);
        expect(metrics.stepsCompleted, equals(0));
        expect(metrics.totalSteps, equals(0));
      });
    });

    group('OnboardingFeatureFlags extension', () {
      test('should toggle onboarding system', () {
        // Start with true
        expect(container.read(useNewOnboardingProvider), isTrue);

        // Create a mock WidgetRef for testing
        final ref = _MockWidgetRef(container);

        // Toggle to false
        ref.toggleOnboardingSystem();
        expect(container.read(useNewOnboardingProvider), isFalse);

        // Toggle back to true
        ref.toggleOnboardingSystem();
        expect(container.read(useNewOnboardingProvider), isTrue);
      });

      test('should force new onboarding system', () {
        // Set to false first
        container.read(useNewOnboardingProvider.notifier).state = false;
        expect(container.read(useNewOnboardingProvider), isFalse);

        final ref = _MockWidgetRef(container);
        ref.useNewOnboarding();
        expect(container.read(useNewOnboardingProvider), isTrue);
      });

      test('should force old onboarding system', () {
        // Start with true
        expect(container.read(useNewOnboardingProvider), isTrue);

        final ref = _MockWidgetRef(container);
        ref.useOldOnboarding();
        expect(container.read(useNewOnboardingProvider), isFalse);
      });
    });
  });

  group('Widget Tests', () {
    testWidgets('AdaptiveOnboardingWrapper should build without error',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdaptiveOnboardingWrapper(),
          ),
        ),
      );

      // Should build without throwing an exception
      expect(find.byType(AdaptiveOnboardingWrapper), findsOneWidget);
    });

    testWidgets('AdaptiveOnboardingWrapper should use new system by default',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdaptiveOnboardingWrapper(),
          ),
        ),
      );

      // Should build NewOnboarding widget since default is true
      expect(find.byType(NewOnboarding), findsOneWidget);
      expect(find.byType(LegacyOnboarding), findsNothing);
    });

    testWidgets(
        'AdaptiveOnboardingWrapper should switch to legacy when flag is false',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            useNewOnboardingProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: AdaptiveOnboardingWrapper(),
          ),
        ),
      );

      // Should build LegacyOnboarding widget since flag is false
      expect(find.byType(LegacyOnboarding), findsOneWidget);
      expect(find.byType(NewOnboarding), findsNothing);
    });
  });
}

/// Mock WidgetRef for testing extension methods
class _MockWidgetRef implements WidgetRef {

  _MockWidgetRef(this._container);
  final ProviderContainer _container;

  @override
  T read<T>(ProviderListenable<T> provider) => _container.read(provider);

  @override
  T watch<T>(ProviderListenable<T> provider) => _container.read(provider);

  @override
  void invalidate(ProviderOrFamily provider) => _container.invalidate(provider);

  @override
  bool exists(ProviderBase<Object?> provider) => _container.exists(provider);

  @override
  void listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    _container.listen(provider, listener, onError: onError);
  }

  @override
  T refresh<T>(Refreshable<T> provider) => _container.refresh(provider);

  @override
  ProviderSubscription<T> listenManual<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) => _container.listen(provider, listener, onError: onError, fireImmediately: fireImmediately);

  @override
  BuildContext get context =>
      throw UnimplementedError('Mock context not implemented');
}
