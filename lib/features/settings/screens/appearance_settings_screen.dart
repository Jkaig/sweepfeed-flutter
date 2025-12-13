import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  final Map<String, Color> _accentColors = const {
    'cyan': AppColors.brandCyan,
    'blue': Colors.blue,
    'green': Colors.green,
    'purple': Colors.purple,
    'orange': Colors.orange,
    'pink': Colors.pink,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeProvider.notifier);
    final currentTheme = ref.watch(themeProvider);
    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.watch(appSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Appearance',
        leading: CustomBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Selection
            Card(
              color: AppColors.primaryMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.brandCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          color: AppColors.brandCyan,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Theme Mode',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildThemeOption(
                      'Light Mode',
                      'Bright theme with light backgrounds',
                      Icons.light_mode,
                      ThemeMode.light,
                      currentTheme,
                      (value) {
                        if (value != null) {
                          themeNotifier.setThemeMode(value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildThemeOption(
                      'Dark Mode',
                      'Dark theme with reduced eye strain',
                      Icons.dark_mode,
                      ThemeMode.dark,
                      currentTheme,
                      (value) {
                        if (value != null) {
                          themeNotifier.setThemeMode(value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildThemeOption(
                      'System Default',
                      'Matches your device settings',
                      Icons.settings_brightness,
                      ThemeMode.system,
                      currentTheme,
                      (value) {
                        if (value != null) {
                          themeNotifier.setThemeMode(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Accent Color Selection
            Card(
              color: AppColors.primaryMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.brandCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.color_lens_outlined,
                          color: AppColors.brandCyan,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Accent Color',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Choose your preferred accent color',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _accentColors.entries
                          .map((entry) => _buildColorOption(
                              entry.key,
                              entry.value,
                              settings.accentColor,
                              settingsNotifier,),)
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Font & Display Settings
            Card(
              color: AppColors.primaryMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.brandCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          color: AppColors.brandCyan,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Text & Display',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Font Size Slider
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Font Size',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${settings.fontSize.round()}sp',
                              style: const TextStyle(
                                color: AppColors.brandCyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.brandCyan,
                            inactiveTrackColor: AppColors.primaryLight,
                            thumbColor: AppColors.brandCyan,
                            overlayColor:
                                AppColors.brandCyan.withValues(alpha: 0.3),
                          ),
                          child: Slider(
                            value: settings.fontSize,
                            min: 12.0,
                            max: 24.0,
                            divisions: 12,
                            onChanged: settingsNotifier.setFontSize,
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryLight.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Sample text at ${settings.fontSize.round()}sp',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: settings.fontSize,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Accessibility & Performance
            Card(
              color: AppColors.primaryMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.brandCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.accessibility_new,
                          color: AppColors.brandCyan,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Accessibility & Performance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildToggleTile(
                      'Compact Mode',
                      'Reduce spacing and padding for more content',
                      Icons.compress,
                      settings.compactMode,
                      settingsNotifier.setCompactMode,
                    ),
                    const SizedBox(height: 12),
                    _buildToggleTile(
                      'Reduced Animations',
                      'Minimize motion effects for better performance',
                      Icons.animation,
                      settings.reducedAnimations,
                      settingsNotifier.setReducedAnimations,
                    ),
                    const SizedBox(height: 12),
                    _buildToggleTile(
                      'High Contrast',
                      'Increase contrast for better visibility',
                      Icons.contrast,
                      settings.highContrast,
                      settingsNotifier.setHighContrast,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Preview Section
            Card(
              color: AppColors.primaryMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.brandCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.preview,
                          color: AppColors.brandCyan,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Theme Preview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(settings.compactMode ? 12 : 16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              settings.accentColorValue.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: settings.accentColorValue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sample Contests',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: settings.fontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: settings.compactMode ? 8 : 12),
                          Text(
                            'This is how your app will look with the current settings. The accent color, font size, and spacing all reflect your choices.',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: settings.fontSize * 0.9,
                              height: settings.compactMode ? 1.3 : 1.5,
                            ),
                          ),
                          SizedBox(height: settings.compactMode ? 8 : 12),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: settings.compactMode ? 12 : 16,
                              vertical: settings.compactMode ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: settings.accentColorValue
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: settings.accentColorValue
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              'Enter Contests',
                              style: TextStyle(
                                color: settings.accentColorValue,
                                fontSize: settings.fontSize * 0.9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    String title,
    String subtitle,
    IconData icon,
    ThemeMode value,
    ThemeMode currentTheme,
    void Function(ThemeMode?) onChanged,
  ) {
    final isSelected = currentTheme == value;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.brandCyan.withValues(alpha: 0.5)
              : AppColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: RadioListTile<ThemeMode>(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.brandCyan.withValues(alpha: 0.2)
                    : AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.brandCyan : AppColors.textLight,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        value: value,
        groupValue: currentTheme,
        onChanged: onChanged,
        activeColor: AppColors.brandCyan,
      ),
    );
  }

  Widget _buildColorOption(String colorName, Color color, String selectedColor,
      settingsNotifier,) {
    final isSelected = selectedColor == colorName;

    return GestureDetector(
      onTap: () {
        settingsNotifier.setAccentColor(colorName);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              )
            : null,
      ),
    );
  }

  Widget _buildToggleTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? AppColors.brandCyan.withValues(alpha: 0.5)
                : AppColors.primaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: value
                    ? AppColors.brandCyan.withValues(alpha: 0.2)
                    : AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: value ? AppColors.brandCyan : AppColors.textLight,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.brandCyan,
                activeTrackColor: AppColors.brandCyan.withValues(alpha: 0.3),
                inactiveThumbColor: AppColors.textLight,
                inactiveTrackColor: AppColors.primaryLight,
              ),
            ),
          ],
        ),
      );
}
