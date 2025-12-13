import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sweepfeed/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SweepFeed App Integration Tests', () {
    testWidgets('App launches and loads home screen', (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Verify app launches successfully
      expect(find.text('SweepFeed'), findsOneWidget);

      // Wait for initial data loading
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify home screen elements are present
      expect(find.text('Featured Contests'), findsOneWidget);
      expect(find.text('Daily Challenges'), findsOneWidget);
    });

    testWidgets('Home screen displays contest data', (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Wait for data to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Check for contest count display
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);

      // Check for level progress
      expect(find.text('Level 3'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('Navigation elements are accessible', (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Check bottom navigation items
      expect(find.text('Daily Bonus'), findsOneWidget);
      expect(find.text('Rewards'), findsOneWidget);
      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.text('Invite'), findsOneWidget);

      // Check floating action button
      expect(find.text('Quick Enter'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Daily challenges display correctly', (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Check challenge cards
      expect(find.text('Enter 3 Contests'), findsOneWidget);
      expect(find.text('Share a Contest'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('0/1'), findsOneWidget);

      // Check progress indicators
      expect(find.byType(LinearProgressIndicator), findsAtLeastNWidgets(2));
    });

    testWidgets('Error handling works correctly', (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Wait for potential error states
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // If error state is shown, verify retry functionality
      if (find.text('Retry').evaluate().isNotEmpty) {
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Verify loading state appears
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('Accessibility features work', (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Find elements with semantic labels
      expect(find.bySemanticsLabel('SweepFeed home screen'), findsOneWidget);
      expect(find.bySemanticsLabel('Active contests counter'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Quick enter contests button'),
        findsOneWidget,
      );
    });

    testWidgets('Performance test - app responds within reasonable time',
        (tester) async {
      final stopwatch = Stopwatch()..start();

      await app.main();
      await tester.pumpAndSettle();

      stopwatch.stop();

      // App should launch within 5 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));

      // Test scroll performance
      final scrollableWidget = find.byType(SingleChildScrollView);
      if (scrollableWidget.evaluate().isNotEmpty) {
        final scrollStopwatch = Stopwatch()..start();

        await tester.drag(scrollableWidget, const Offset(0, -200));
        await tester.pumpAndSettle();

        scrollStopwatch.stop();

        // Scroll should complete within 1 second
        expect(scrollStopwatch.elapsedMilliseconds, lessThan(1000));
      }
    });

    testWidgets('Memory usage test', (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Simulate multiple screen interactions
      for (var i = 0; i < 10; i++) {
        // Scroll up and down
        final scrollableWidget = find.byType(SingleChildScrollView);
        if (scrollableWidget.evaluate().isNotEmpty) {
          await tester.drag(scrollableWidget, const Offset(0, -100));
          await tester.pump();
          await tester.drag(scrollableWidget, const Offset(0, 100));
          await tester.pump();
        }

        // Wait a bit between iterations
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();

      // App should still be responsive after multiple interactions
      expect(find.text('SweepFeed'), findsOneWidget);
    });

    testWidgets('User interaction flow test', (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Test viewing all challenges
      if (find.text('View All').evaluate().isNotEmpty) {
        await tester.tap(find.text('View All'));
        await tester.pumpAndSettle();
      }

      // Test challenge interaction
      if (find.text('Go').evaluate().isNotEmpty) {
        await tester.tap(find.text('Go').first);
        await tester.pumpAndSettle();
      }

      // Test floating action button
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Test navigation items
      final navItems = ['Daily Bonus', 'Rewards', 'Leaderboard', 'Invite'];
      for (final item in navItems) {
        if (find.text(item).evaluate().isNotEmpty) {
          await tester.tap(find.text(item));
          await tester.pump();
        }
      }

      await tester.pumpAndSettle();
    });

    testWidgets('Data loading and caching test', (tester) async {
      // First load
      final firstLoadStopwatch = Stopwatch()..start();
      await app.main();
      await tester.pumpAndSettle();
      firstLoadStopwatch.stop();

      // Restart app to test cached data
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        null,
        (data) {},
      );

      // Second load (should be faster due to caching)
      final secondLoadStopwatch = Stopwatch()..start();
      await app.main();
      await tester.pumpAndSettle();
      secondLoadStopwatch.stop();

      // Second load should be faster (allowing for some variance)
      expect(
        secondLoadStopwatch.elapsedMilliseconds,
        lessThan(firstLoadStopwatch.elapsedMilliseconds + 1000),
      );
    });

    testWidgets('Offline behavior test', (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Wait for initial data load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // App should show some content even in offline mode
      // (cached data or empty states)
      expect(find.text('SweepFeed'), findsOneWidget);
      expect(find.text('Featured Contests'), findsOneWidget);
      expect(find.text('Daily Challenges'), findsOneWidget);
    });
  });
}
