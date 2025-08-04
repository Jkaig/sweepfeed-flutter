import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweepfeed_app/features/contests/widgets/filter_bottom_sheet.dart';

void main() {
  // Helper function to pump the FilterBottomSheet widget
  Future<void> pumpFilterBottomSheet(
    WidgetTester tester, {
    Map<String, dynamic> initialFilters = const {},
    required Function(Map<String, dynamic>) onApplyFilters,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              // Button to show the bottom sheet
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true, // Important for scrollable content
                    builder: (_) => FilterBottomSheet(
                      initialFilters: initialFilters,
                      onApplyFilters: onApplyFilters,
                    ),
                  );
                },
                child: const Text('Show Filters'),
              );
            },
          ),
        ),
      ),
    );

    // Tap the button to show the bottom sheet
    await tester.tap(find.text('Show Filters'));
    await tester.pumpAndSettle(); // Wait for bottom sheet animation
  }

  group('FilterBottomSheet Widget Tests', () {
    testWidgets('renders correctly and shows initial filters', (WidgetTester tester) async {
      Map<String, dynamic>? appliedFilters;
      final initialFilters = {
        'categories': ['Cash'],
        'endingSoon': true,
      };

      await pumpFilterBottomSheet(
        tester,
        initialFilters: initialFilters,
        onApplyFilters: (filters) {
          appliedFilters = filters;
        },
      );

      // Check if title is present
      expect(find.text('Filters'), findsOneWidget);
      
      // Check if initial 'Cash' category chip is selected
      final cashChip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Cash'));
      expect(cashChip.selected, isTrue);

      // Check if 'Ending Soon' switch is on
      final endingSoonSwitch = tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Ending Soon'));
      expect(endingSoonSwitch.value, isTrue);

      // Check for new filter sections (they should exist even if no initial value)
      expect(find.text('Platform'), findsOneWidget);
      expect(find.text('Entry Frequency'), findsOneWidget);
      expect(find.text('New Contests'), findsOneWidget);
    });

    testWidgets('selects and applies platform filter', (WidgetTester tester) async {
      Map<String, dynamic>? appliedFilters;
      await pumpFilterBottomSheet(
        tester,
        onApplyFilters: (filters) {
          appliedFilters = filters;
        },
      );

      // Tap on 'Gleam' platform chip
      await tester.tap(find.widgetWithText(FilterChip, 'Gleam'));
      await tester.pumpAndSettle(); // Update chip selection state

      // Verify 'Gleam' chip is selected
      final gleamChip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Gleam'));
      expect(gleamChip.selected, isTrue);
      
      // Tap Apply Filters button
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle(); // Wait for sheet to close

      expect(appliedFilters, isNotNull);
      expect(appliedFilters!['platforms'], contains('Gleam'));
    });

    testWidgets('selects and applies entry frequency filter', (WidgetTester tester) async {
      Map<String, dynamic>? appliedFilters;
      await pumpFilterBottomSheet(
        tester,
        onApplyFilters: (filters) {
          appliedFilters = filters;
        },
      );

      await tester.tap(find.widgetWithText(FilterChip, 'Daily')); // From _allEntryFrequencies
      await tester.pumpAndSettle();
      
      final dailyChip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Daily'));
      expect(dailyChip.selected, isTrue);

      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(appliedFilters, isNotNull);
      expect(appliedFilters!['entryFrequencies'], contains('Daily'));
    });

    testWidgets('selects and applies "New Contests" filter (Last 24h)', (WidgetTester tester) async {
      Map<String, dynamic>? appliedFilters;
      await pumpFilterBottomSheet(
        tester,
        onApplyFilters: (filters) {
          appliedFilters = filters;
        },
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Last 24h'));
      await tester.pumpAndSettle();
      
      // Verify 'Last 24h' chip is selected
      final chip24h = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Last 24h'));
      expect(chip24h.selected, isTrue);

      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(appliedFilters, isNotNull);
      expect(appliedFilters!['newContestDuration'], '24h');
    });
    
    testWidgets('selects and applies "New Contests" filter (Last 48h)', (WidgetTester tester) async {
      Map<String, dynamic>? appliedFilters;
      await pumpFilterBottomSheet(
        tester,
        onApplyFilters: (filters) {
          appliedFilters = filters;
        },
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Last 48h'));
      await tester.pumpAndSettle();
      
      final chip48h = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Last 48h'));
      expect(chip48h.selected, isTrue);

      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(appliedFilters, isNotNull);
      expect(appliedFilters!['newContestDuration'], '48h');
    });

    testWidgets('applies multiple filters correctly', (WidgetTester tester) async {
      Map<String, dynamic>? appliedFilters;
      await pumpFilterBottomSheet(
        tester,
        onApplyFilters: (filters) {
          appliedFilters = filters;
        },
      );

      // Select platform
      await tester.tap(find.widgetWithText(FilterChip, 'Twitter'));
      await tester.pumpAndSettle();
      // Select entry frequency
      await tester.tap(find.widgetWithText(FilterChip, 'Weekly')); // From _allEntryFrequencies
      await tester.pumpAndSettle();
      // Select new contest duration
      await tester.tap(find.widgetWithText(ChoiceChip, 'Last 48h'));
      await tester.pumpAndSettle();
      // Select a category
      await tester.tap(find.widgetWithText(FilterChip, 'Electronics'));
      await tester.pumpAndSettle();


      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(appliedFilters, isNotNull);
      expect(appliedFilters!['platforms'], contains('Twitter'));
      expect(appliedFilters!['entryFrequencies'], contains('Weekly'));
      expect(appliedFilters!['newContestDuration'], '48h');
      expect(appliedFilters!['categories'], contains('Electronics'));
    });

    testWidgets('Reset button clears all selections and applies empty filters', (WidgetTester tester) async {
      Map<String, dynamic>? appliedFilters;
      // Start with some initial filters to ensure they are cleared
      final initialFilters = {
        'platforms': ['Gleam'],
        'entryFrequencies': ['Daily'],
        'newContestDuration': '24h',
        'categories': ['Travel'],
        'endingSoon': true,
      };

      await pumpFilterBottomSheet(
        tester,
        initialFilters: initialFilters,
        onApplyFilters: (filters) {
          appliedFilters = filters;
        },
      );

      // Verify initial selections are present
      expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Gleam')).selected, isTrue);
      expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Daily')).selected, isTrue);
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Last 24h')).selected, isTrue);
      expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Travel')).selected, isTrue);
      expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Ending Soon')).value, isTrue);


      // Tap Reset button
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle(); // Wait for sheet to close

      // onApplyFilters should be called with empty map
      expect(appliedFilters, isNotNull);
      expect(appliedFilters, isEmpty);

      // To verify UI elements are reset, we'd need to reopen the sheet.
      // The current test structure pops the sheet on reset.
      // For a more thorough test of UI reset, one might avoid auto-popping or
      // check the state of the _FilterBottomSheetState directly if possible,
      // or reopen and check.

      // Re-open the sheet to check if selections are cleared
      await tester.tap(find.text('Show Filters'));
      await tester.pumpAndSettle();

      expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Gleam')).selected, isFalse);
      expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Daily')).selected, isFalse);
      // For ChoiceChips, 'Any' or null equivalent should be selected. Let's check 'Last 24h' is false.
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Last 24h')).selected, isFalse);
      // And check if 'Any' is selected for New Contests (this assumes 'Any' is the default for null _newContestDuration)
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Any')).selected, isTrue);


      expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Travel')).selected, isFalse);
      expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Ending Soon')).value, isFalse);
    });
  });
}
