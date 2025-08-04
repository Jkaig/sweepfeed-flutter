import 'package:flutter/material.dart';

// Placeholder data - replace with actual data source if available
const List<String> _allCategories = [
  'Cash',
  'Travel',
  'Electronics',
  'Gift Cards',
  'Experiences',
  'Other'
];
const List<String> _allEntryMethods = [
  'Gleam',
  'Website Form',
  'Social Media',
  'Referral',
  'Daily',
  'Instant Win'
];

// Placeholder data for new filters - replace with actual data if available
const List<String> _allPlatforms = [
  'Gleam',
  'Rafflecopter',
  'SweepWidget',
  'Twitter',
  'Instagram',
  'Facebook',
  'Other'
];
const List<String> _allEntryFrequencies = [
  'One-time',
  'Daily',
  'Weekly',
  'Monthly'
];

class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> initialFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApplyFilters,
  });

  @override
  _FilterBottomSheetState createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, dynamic> _currentFilters;

  // Temporary state for UI elements
  late Set<String> _selectedCategories;
  late Set<String> _selectedEntryMethods;
  late Set<String> _selectedPlatforms; // New filter
  late Set<String> _selectedEntryFrequencies; // New filter
  bool _endingSoon = false;
  double? _minPrize; // Using null for no minimum
  String? _newContestDuration; // New filter: null, '24h', or '48h'

  @override
  void initState() {
    super.initState();
    _currentFilters = Map.from(widget.initialFilters);

    // Initialize temporary UI state from initial filters
    _selectedCategories = Set<String>.from(_currentFilters['categories'] ?? []);
    _selectedEntryMethods =
        Set<String>.from(_currentFilters['entryMethods'] ?? []);
    _selectedPlatforms = Set<String>.from(_currentFilters['platforms'] ?? []); // New
    _selectedEntryFrequencies =
        Set<String>.from(_currentFilters['entryFrequencies'] ?? []); // New
    _endingSoon = _currentFilters['endingSoon'] ?? false;
    _minPrize = _currentFilters['minPrize']?.toDouble(); // Allow null
    _newContestDuration = _currentFilters['newContestDuration']; // New
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Add padding to respect safe area (notch, navigation bar)
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16),
      child: SingleChildScrollView(
        // Allow content to scroll if it overflows
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    // Reset temporary state and apply empty filters
                    setState(() {
                      _selectedCategories = {};
                      _selectedEntryMethods = {};
                      _selectedPlatforms = {}; // Reset new filter
                      _selectedEntryFrequencies = {}; // Reset new filter
                      _endingSoon = false;
                      _minPrize = null;
                      _newContestDuration = null; // Reset new filter
                      _currentFilters = {};
                    });
                    widget
                        .onApplyFilters({}); // Apply empty filters immediately
                    Navigator.pop(context); // Close sheet
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const Divider(height: 24),

            // --- Ending Soon Filter ---
            SwitchListTile(
              title: const Text('Ending Soon'),
              value: _endingSoon,
              onChanged: (value) {
                setState(() {
                  _endingSoon = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // --- Categories Filter ---
            _buildFilterSection(
              title: 'Categories',
              options: _allCategories,
              selectedOptions: _selectedCategories,
              onChanged: (value, isSelected) {
                setState(() {
                  if (isSelected) {
                    _selectedCategories.add(value);
                  } else {
                    _selectedCategories.remove(value);
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // --- Entry Methods Filter ---
            _buildFilterSection(
              title: 'Entry Methods',
              options: _allEntryMethods,
              selectedOptions: _selectedEntryMethods,
              onChanged: (value, isSelected) {
                setState(() {
                  if (isSelected) {
                    _selectedEntryMethods.add(value);
                  } else {
                    _selectedEntryMethods.remove(value);
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // --- Platforms Filter ---
            _buildFilterSection(
              title: 'Platform',
              options: _allPlatforms,
              selectedOptions: _selectedPlatforms,
              onChanged: (value, isSelected) {
                setState(() {
                  if (isSelected) {
                    _selectedPlatforms.add(value);
                  } else {
                    _selectedPlatforms.remove(value);
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // --- Entry Frequency Filter ---
            _buildFilterSection(
              title: 'Entry Frequency',
              options: _allEntryFrequencies,
              selectedOptions: _selectedEntryFrequencies,
              onChanged: (value, isSelected) {
                setState(() {
                  if (isSelected) {
                    _selectedEntryFrequencies.add(value);
                  } else {
                    _selectedEntryFrequencies.remove(value);
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // --- New Contest Filter ---
            Text('New Contests',
                style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 8.0,
              children: [
                ChoiceChip(
                  label: const Text('Any'),
                  selected: _newContestDuration == null,
                  onSelected: (selected) {
                    setState(() {
                      _newContestDuration = selected ? null : _newContestDuration;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Last 24h'),
                  selected: _newContestDuration == '24h',
                  onSelected: (selected) {
                    setState(() {
                      _newContestDuration = selected ? '24h' : null;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Last 48h'),
                  selected: _newContestDuration == '48h',
                  onSelected: (selected) {
                    setState(() {
                      _newContestDuration = selected ? '48h' : null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Min Prize Filter ---
            Text('Minimum Prize Value',
                style: Theme.of(context).textTheme.titleMedium),
            // Simple example using ChoiceChips, could use Slider or TextField
            Wrap(
              spacing: 8.0,
              children: [0, 100, 500, 1000, 5000].map((value) {
                bool isSelected = _minPrize == value.toDouble();
                return ChoiceChip(
                  label: Text(value == 0 ? 'Any' : '\$$value+'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _minPrize = selected ? value.toDouble() : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // --- Apply Button ---
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, 40), // Make button wider
                ),
                onPressed: () {
                  // Construct the final filter map from the temporary state
                  final Map<String, dynamic> appliedFilters = {};
                  if (_selectedCategories.isNotEmpty) {
                    appliedFilters['categories'] = _selectedCategories.toList();
                  }
                  if (_selectedEntryMethods.isNotEmpty) {
                    appliedFilters['entryMethods'] =
                        _selectedEntryMethods.toList();
                  }
                  if (_selectedPlatforms.isNotEmpty) { // New
                    appliedFilters['platforms'] = _selectedPlatforms.toList();
                  }
                  if (_selectedEntryFrequencies.isNotEmpty) { // New
                    appliedFilters['entryFrequencies'] =
                        _selectedEntryFrequencies.toList();
                  }
                  if (_endingSoon) {
                    // HomeScreen logic translates this to date query
                    // Or adjust ContestService to handle 'endingSoon' directly
                    appliedFilters['endingSoon'] = true;
                  }
                  if (_newContestDuration != null) { // New
                    appliedFilters['newContestDuration'] = _newContestDuration;
                  }
                  if (_minPrize != null && _minPrize! > 0) {
                    // Exclude 'Any' (0)
                    appliedFilters['minPrize'] = _minPrize;
                  }

                  widget.onApplyFilters(appliedFilters);
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper widget for building sections with chips
  Widget _buildFilterSection({
    required String title,
    required List<String> options,
    required Set<String> selectedOptions,
    required Function(String, bool) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) => onChanged(option, selected),
              // Add styling as needed
            );
          }).toList(),
        ),
      ],
    );
  }
}
