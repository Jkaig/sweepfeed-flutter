import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_test_service.dart';

/// Comprehensive test screen for modern notification features
/// Demonstrates iOS 17+ and Android 14+ capabilities
class NotificationTestScreen extends ConsumerStatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  ConsumerState<NotificationTestScreen> createState() =>
      _NotificationTestScreenState();
}

class _NotificationTestScreenState
    extends ConsumerState<NotificationTestScreen> {
  bool _isRunningTest = false;
  String _testStatus = 'Ready to test';
  Map<String, dynamic>? _lastTestReport;
  final String _testUserId = 'test_user_123';

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0A1929),
        appBar: AppBar(
          title: const Text('Notification Testing'),
          backgroundColor: const Color(0xFF0A1929),
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.science, color: Color(0xFF00E5FF), size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Notification Lab',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Test modern iOS 17+ and Android 14+ notification features including Live Activities, rich media, and interactive actions.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isRunningTest
                          ? Colors.orange.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isRunningTest
                              ? Icons.hourglass_empty
                              : Icons.check_circle,
                          color: _isRunningTest ? Colors.orange : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _testStatus,
                            style: TextStyle(
                              color:
                                  _isRunningTest ? Colors.orange : Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Tests Section
            _buildSectionCard(
              title: 'Quick Tests',
              icon: Icons.flash_on,
              children: [
                _buildTestButton(
                  title: 'Test Basic Notifications',
                  subtitle: 'Test all notification categories',
                  icon: Icons.notifications,
                  color: const Color(0xFF00E5FF),
                  onPressed: _isRunningTest ? null : _testBasicNotifications,
                ),
                _buildTestButton(
                  title: 'Test Rich Media',
                  subtitle: 'Images, BigPicture, InboxStyle',
                  icon: Icons.image,
                  color: const Color(0xFF4CAF50),
                  onPressed: _isRunningTest ? null : _testRichMedia,
                ),
                _buildTestButton(
                  title: 'Test Interactive Actions',
                  subtitle: 'Buttons, replies, and actions',
                  icon: Icons.touch_app,
                  color: const Color(0xFF9C27B0),
                  onPressed: _isRunningTest ? null : _testInteractiveActions,
                ),
                _buildTestButton(
                  title: 'Test Live Activities',
                  subtitle: 'iOS 17+ Dynamic Island integration',
                  icon: Icons.dynamic_form,
                  color: const Color(0xFFFF9800),
                  onPressed: _isRunningTest ? null : _testLiveActivities,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Advanced Tests Section
            _buildSectionCard(
              title: 'Advanced Tests',
              icon: Icons.engineering,
              children: [
                _buildTestButton(
                  title: 'Test Notification Grouping',
                  subtitle: 'Thread management and bundling',
                  icon: Icons.group_work,
                  color: const Color(0xFF2196F3),
                  onPressed: _isRunningTest ? null : _testGrouping,
                ),
                _buildTestButton(
                  title: 'Test Deep Linking',
                  subtitle: 'Navigation from notifications',
                  icon: Icons.link,
                  color: const Color(0xFFE91E63),
                  onPressed: _isRunningTest ? null : _testDeepLinking,
                ),
                _buildTestButton(
                  title: 'Test Consent Management',
                  subtitle: 'GDPR compliance and user preferences',
                  icon: Icons.privacy_tip,
                  color: const Color(0xFF607D8B),
                  onPressed: _isRunningTest ? null : _testConsentManagement,
                ),
                _buildTestButton(
                  title: 'Performance Test',
                  subtitle: 'High volume notification handling',
                  icon: Icons.speed,
                  color: const Color(0xFFFF5722),
                  onPressed: _isRunningTest ? null : _runPerformanceTest,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Comprehensive Test Section
            _buildSectionCard(
              title: 'Comprehensive Testing',
              icon: Icons.fact_check,
              children: [
                _buildTestButton(
                  title: 'Run All Tests',
                  subtitle: 'Complete feature validation suite',
                  icon: Icons.playlist_add_check,
                  color: const Color(0xFFFFD700),
                  onPressed: _isRunningTest ? null : _runComprehensiveTest,
                  isLarge: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Test Report Section
            if (_lastTestReport != null) _buildTestReport(),

            const SizedBox(height: 16),

            // Device Information
            _buildDeviceInfoCard(),
          ],
        ),
      );

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF00E5FF)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );

  Widget _buildTestButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool isLarge = false,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(isLarge ? 20 : 16),
              decoration: BoxDecoration(
                color: onPressed != null
                    ? color.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: onPressed != null
                      ? color.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: onPressed != null
                          ? color.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: onPressed != null ? color : Colors.grey,
                      size: isLarge ? 28 : 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color:
                                onPressed != null ? Colors.white : Colors.grey,
                            fontSize: isLarge ? 18 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: onPressed != null
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey.withValues(alpha: 0.7),
                            fontSize: isLarge ? 16 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onPressed != null) ...[
                    Icon(
                      Icons.play_arrow,
                      color: color,
                      size: isLarge ? 28 : 24,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildTestReport() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assessment, color: Color(0xFF00E5FF)),
                SizedBox(width: 8),
                Text(
                  'Test Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...(_lastTestReport!['test_results'] as Map<String, dynamic>)
                .entries
                .map(
                  (entry) => _buildTestResultItem(entry.key, entry.value),
                ),
            const SizedBox(height: 12),
            Text(
              'Report generated: ${_lastTestReport!['timestamp']}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );

  Widget _buildTestResultItem(String test, String result) {
    Color resultColor;
    IconData resultIcon;

    switch (result) {
      case 'passed':
        resultColor = Colors.green;
        resultIcon = Icons.check_circle;
        break;
      case 'failed':
        resultColor = Colors.red;
        resultIcon = Icons.error;
        break;
      case 'conditional':
        resultColor = Colors.orange;
        resultIcon = Icons.warning;
        break;
      default:
        resultColor = Colors.grey;
        resultIcon = Icons.help;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(resultIcon, color: resultColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              test.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Text(
            result.toUpperCase(),
            style: TextStyle(
              color: resultColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.phone_android, color: Color(0xFF00E5FF)),
                SizedBox(width: 8),
                Text(
                  'Device Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Platform', Theme.of(context).platform.name),
            _buildInfoRow('Test User ID', _testUserId),
            _buildInfoRow('Modern Features', 'iOS 17+ / Android 14+'),
            _buildInfoRow('Live Activities', 'iOS Only'),
          ],
        ),
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  // Test methods
  Future<void> _testBasicNotifications() async {
    setState(() {
      _isRunningTest = true;
      _testStatus = 'Testing basic notifications...';
    });

    try {
      await notificationTestService._testBasicNotifications(_testUserId);
      setState(() {
        _testStatus = 'Basic notifications test completed';
      });
    } catch (e) {
      setState(() {
        _testStatus = 'Basic notifications test failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  Future<void> _testRichMedia() async {
    setState(() {
      _isRunningTest = true;
      _testStatus = 'Testing rich media notifications...';
    });

    try {
      await notificationTestService._testRichMediaNotifications(_testUserId);
      setState(() {
        _testStatus = 'Rich media test completed';
      });
    } catch (e) {
      setState(() {
        _testStatus = 'Rich media test failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  Future<void> _testInteractiveActions() async {
    setState(() {
      _isRunningTest = true;
      _testStatus = 'Testing interactive actions...';
    });

    try {
      await notificationTestService._testInteractiveNotifications(_testUserId);
      setState(() {
        _testStatus = 'Interactive actions test completed';
      });
    } catch (e) {
      setState(() {
        _testStatus = 'Interactive actions test failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  Future<void> _testLiveActivities() async {
    setState(() {
      _isRunningTest = true;
      _testStatus = 'Testing Live Activities...';
    });

    try {
      await notificationTestService._testLiveActivities(_testUserId);
      setState(() {
        _testStatus = 'Live Activities test completed';
      });
    } catch (e) {
      setState(() {
        _testStatus = 'Live Activities test failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  Future<void> _testGrouping() async {
    setState(() {
      _isRunningTest = true;
      _testStatus = 'Testing notification grouping...';
    });

    try {
      await notificationTestService._testNotificationGrouping(_testUserId);
      setState(() {
        _testStatus = 'Notification grouping test completed';
      });
    } catch (e) {
      setState(() {
        _testStatus = 'Notification grouping test failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  Future<void> _testDeepLinking() async {
    setState(() {
      _isRunningTest = true;
      _testStatus = 'Testing deep linking...';
    });

    try {
      await notificationTestService.testDeepLinking(_testUserId);
      setState(() {
        _testStatus = 'Deep linking test completed';
      });
    } catch (e) {
      setState(() {
        _testStatus = 'Deep linking test failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  Future<void> _testConsentManagement() async {
    setState(() {
      _isRunningTest = true;
      _testStatus = 'Testing consent management...';
    });

    try {
      await notificationTestService._testConsentManagement(_testUserId);
      setState(() {
        _testStatus = 'Consent management test completed';
      });
    } catch (e) {
      setState(() {
        _testStatus = 'Consent management test failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  Future<void> _runPerformanceTest() async {
    setState(() {
      _isRunningTest = true;
      _testStatus = 'Running performance test...';
    });

    try {
      await notificationTestService.runPerformanceTest(
        _testUserId,
        notificationCount: 50,
      );
      setState(() {
        _testStatus = 'Performance test completed';
      });
    } catch (e) {
      setState(() {
        _testStatus = 'Performance test failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  Future<void> _runComprehensiveTest() async {
    setState(() {
      _isRunningTest = true;
      _testStatus = 'Running comprehensive test suite...';
    });

    try {
      await notificationTestService.runComprehensiveTest(_testUserId);
      final report =
          await notificationTestService.generateTestReport(_testUserId);

      setState(() {
        _testStatus = 'Comprehensive test completed successfully';
        _lastTestReport = report;
      });
    } catch (e) {
      setState(() {
        _testStatus = 'Comprehensive test failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }
}
