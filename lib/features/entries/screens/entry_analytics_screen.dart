import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glassmorphic_container.dart';
import '../../../core/widgets/animated_gradient_background.dart';
import '../../social/screens/dust_bunnies_shop_screen.dart';

class EntryAnalyticsScreen extends ConsumerStatefulWidget {
  const EntryAnalyticsScreen({super.key});

  @override
  ConsumerState<EntryAnalyticsScreen> createState() => _EntryAnalyticsScreenState();
}

class _EntryAnalyticsScreenState extends ConsumerState<EntryAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch the unlock status
    final isUnlockedAsync = ref.watch(entryTrackerUnlockProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Entry Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedGradientBackground()),
          SafeArea(
            child: isUnlockedAsync.when(
              data: (isUnlocked) {
                if (!isUnlocked) {
                  return _buildLockedState();
                }
                return _buildAnalyticsDashboard();
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassmorphicContainer(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppColors.textLight,
                ),
                const SizedBox(height: 24),
                Text(
                  'Analytics Locked',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unlock detailed entry stats, win rates, and prize value tracking with Entry Tracker Pro.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to Shop
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DustBunniesShopScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Get it in the Shop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandCyan,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildAnalyticsDashboard() {
    // Mock data for now - could be connected to UserProfile stats
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          title: 'Win Rate',
          value: '2.5%',
          subtitle: 'Top 10% of users',
          icon: Icons.emoji_events_outlined,
          color: AppColors.brandGold,
        ),
        const SizedBox(height: 16),
        GlassmorphicContainer(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entries (Last 7 Days)',
                  style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: _bottomTitles,
                            reservedSize: 30,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 3),
                            FlSpot(1, 1),
                            FlSpot(2, 4),
                            FlSpot(3, 2),
                            FlSpot(4, 5),
                            FlSpot(5, 3),
                            FlSpot(6, 6),
                          ],
                          isCurved: true,
                          color: AppColors.brandCyan,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.brandCyan.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Value',
                value: '\$12,450',
                subtitle: 'Entered Prize Value',
                icon: Icons.attach_money,
                color: AppColors.successGreen,
                isSmall: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Active',
                value: '42',
                subtitle: 'Contests Entered',
                icon: Icons.check_circle_outline,
                color: AppColors.brandCyan,
                isSmall: true,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isSmall = false,
  }) {
    return GlassmorphicContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: isSmall ? 20 : 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 24 : 32,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper for chart titles
Widget _bottomTitles(double value, TitleMeta meta) {
  const style = TextStyle(
    color: Colors.white38,
    fontWeight: FontWeight.bold,
    fontSize: 10,
  );
  String text;
  switch (value.toInt()) {
    case 0:
      text = 'Mon';
      break;
    case 3:
      text = 'Thu';
      break;
    case 6:
      text = 'Sun';
      break;
    default:
      return Container();
  }
  return SideTitleWidget(
    axisSide: meta.axisSide,
    space: 8.0,
    child: Text(text, style: style),
  );
}


