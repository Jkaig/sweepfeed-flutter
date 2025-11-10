import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../features/subscription/screens/subscription_screen.dart';
import '../../../features/subscription/services/tier_management_service.dart';
import '../models/email_message.dart';
import '../services/email_service.dart';
import '../widgets/email_category_tab.dart';
import '../widgets/email_list_item.dart';
import 'email_settings_screen.dart';

/// Email inbox screen for Premium users
class EmailInboxScreen extends ConsumerStatefulWidget {
  const EmailInboxScreen({super.key});

  @override
  ConsumerState<EmailInboxScreen> createState() => _EmailInboxScreenState();
}

class _EmailInboxScreenState extends ConsumerState<EmailInboxScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedEmails = [];
  bool _isSelectionMode = false;

  final List<EmailCategoryTabData> _tabs = const [
    EmailCategoryTabData(
      category: null, // All emails
      label: 'All',
      icon: Icons.all_inbox,
    ),
    EmailCategoryTabData(
      category: EmailCategory.promo,
      label: 'Promos',
      icon: Icons.local_offer,
    ),
    EmailCategoryTabData(
      category: EmailCategory.winner,
      label: 'Winners',
      icon: Icons.emoji_events,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
          _clearSelection();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if user has Premium access
    final tierManagement = ref.watch(tierManagementServiceProvider);
    final currentTier = tierManagement.getCurrentTier();

    if (!currentTier.hasEmailInbox) {
      return _buildUpgradeScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Search bar (if searching)
          if (_isSearching) _buildSearchBar(),

          // Category tabs
          EmailCategoryTabBar(
            selectedIndex: _selectedTabIndex,
            onTabSelected: (index) {
              setState(() {
                _selectedTabIndex = index;
                _clearSelection();
              });
              _tabController.animateTo(index);
            },
            tabs: _tabs,
          ),

          // Selection mode toolbar
          if (_isSelectionMode) _buildSelectionToolbar(),

          // Email list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children:
                  _tabs.map((tab) => _buildEmailList(tab.category)).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton:
          _isSelectionMode ? null : _buildFloatingActionButton(),
    );
  }

  /// Build app bar with search and settings actions
  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        backgroundColor: AppColors.primaryMedium,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite),
          decoration: InputDecoration(
            hintText: 'Search emails...',
            hintStyle:
                AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
            border: InputBorder.none,
          ),
          onSubmitted: (query) {
            if (query.isNotEmpty) {
              _performSearch(query);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear, color: AppColors.textWhite),
            onPressed: () {
              _searchController.clear();
            },
          ),
        ],
      );
    }

    return CustomAppBar(
      title: 'Email Inbox',
      leading: const CustomBackButton(),
      actions: [
        // Search button
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryMedium.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.brandCyan.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
        ),

        // Settings button
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryMedium.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.brandCyan.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EmailSettingsScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build search bar widget
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryMedium,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textWhite),
                decoration: InputDecoration(
                  hintText: 'Search emails...',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textMuted),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (query) {
                  if (query.isNotEmpty) {
                    _performSearch(query);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
              });
            },
            child: Text(
              'Cancel',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.brandCyan),
            ),
          ),
        ],
      ),
    );
  }

  /// Build selection mode toolbar
  Widget _buildSelectionToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.brandCyan.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.brandCyan.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedEmails.length} selected',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.brandCyan),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _selectedEmails.isNotEmpty ? _markSelectedAsRead : null,
            icon: const Icon(Icons.mark_email_read, size: 18),
            label: const Text('Mark Read'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brandCyan,
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed:
                _selectedEmails.isNotEmpty ? _deleteSelectedEmails : null,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorRed,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _clearSelection,
            child: Text(
              'Cancel',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }

  /// Build email list for the specified category
  Widget _buildEmailList(EmailCategory? category) {
    final emailsAsync = ref.watch(emailsStreamProvider(category));

    return emailsAsync.when(
      data: (emails) {
        if (emails.isEmpty) {
          return _buildEmptyState(category);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.refresh(emailsStreamProvider(category));
          },
          color: AppColors.brandCyan,
          backgroundColor: AppColors.primaryMedium,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: emails.length,
            itemBuilder: (context, index) {
              final email = emails[index];
              final isSelected = _selectedEmails.contains(email.id);

              return GestureDetector(
                onLongPress: () {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedEmails.add(email.id);
                  });
                },
                child: Container(
                  decoration: isSelected
                      ? BoxDecoration(
                          color: AppColors.brandCyan.withValues(alpha: 0.1),
                          border: Border(
                            left: BorderSide(
                              color: AppColors.brandCyan,
                              width: 4,
                            ),
                          ),
                        )
                      : null,
                  child: Row(
                    children: [
                      if (_isSelectionMode) ...[
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedEmails.add(email.id);
                              } else {
                                _selectedEmails.remove(email.id);
                              }

                              if (_selectedEmails.isEmpty) {
                                _isSelectionMode = false;
                              }
                            });
                          },
                          activeColor: AppColors.brandCyan,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: SwipeableEmailListItem(
                          email: email,
                          onTap: _isSelectionMode
                              ? () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedEmails.remove(email.id);
                                    } else {
                                      _selectedEmails.add(email.id);
                                    }

                                    if (_selectedEmails.isEmpty) {
                                      _isSelectionMode = false;
                                    }
                                  });
                                }
                              : () => _openEmailDetail(email),
                          showActions: !_isSelectionMode,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading emails',
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.textWhite),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(emailsStreamProvider(category)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandCyan,
                foregroundColor: AppColors.primaryDark,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state for when no emails are found
  Widget _buildEmptyState(EmailCategory? category) {
    String title;
    String subtitle;
    IconData icon;

    switch (category) {
      case EmailCategory.promo:
        title = 'No promotional emails';
        subtitle = 'Promotional emails will appear here when you receive them.';
        icon = Icons.local_offer;
        break;
      case EmailCategory.winner:
        title = 'No winner notifications';
        subtitle = 'Winner notifications will appear here. Keep entering!';
        icon = Icons.emoji_events;
        break;
      case null: // All emails
      default:
        title = 'Your inbox is empty';
        subtitle =
            'Start using your @sweepfeed.com email address to receive emails here.';
        icon = Icons.inbox;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryMedium.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style:
                  AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            if (category == null) ...[
              const SizedBox(height: 24),
              Consumer(
                builder: (context, ref, child) {
                  final emailAddressAsync =
                      ref.watch(userSweepFeedEmailProvider);
                  return emailAddressAsync.when(
                    data: (emailAddress) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMedium.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.brandCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Your SweepFeed Email:',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  emailAddress,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.brandCyan,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    _copyEmailAddress(emailAddress),
                                icon: const Icon(
                                  Icons.copy,
                                  color: AppColors.brandCyan,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build floating action button
  Widget? _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const EmailSettingsScreen(),
          ),
        );
      },
      backgroundColor: AppColors.brandCyan,
      foregroundColor: AppColors.primaryDark,
      icon: const Icon(Icons.settings),
      label: const Text('Settings'),
    );
  }

  /// Build upgrade screen for non-Premium users
  Widget _buildUpgradeScreen() {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(
        title: 'Email Inbox',
        leading: const CustomBackButton(),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.mail_lock,
                  size: 64,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Premium Feature',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.textWhite),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'The email inbox is exclusively available to Premium subscribers. Get your own @sweepfeed.com email address and never miss important sweepstakes notifications!',
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandCyan,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                icon: const Icon(Icons.upgrade),
                label: const Text('Upgrade to Premium'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Private helper methods

  void _performSearch(String query) {
    // TODO: Implement search functionality
    // This would call the email service search method
    debugPrint('Searching for: $query');
  }

  void _openEmailDetail(EmailMessage email) {
    // Mark as read when opening
    ref.read(emailServiceProvider).markAsRead(email.id);

    // TODO: Navigate to email detail screen
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening: ${email.subject}'),
        backgroundColor: AppColors.primaryMedium,
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedEmails.clear();
      _isSelectionMode = false;
    });
  }

  void _markSelectedAsRead() async {
    if (_selectedEmails.isNotEmpty) {
      final emailService = ref.read(emailServiceProvider);
      await emailService.markMultipleAsRead(_selectedEmails);
      _clearSelection();
    }
  }

  void _deleteSelectedEmails() async {
    if (_selectedEmails.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.primaryMedium,
          title: Text(
            'Delete Emails',
            style:
                AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
          ),
          content: Text(
            'Are you sure you want to delete ${_selectedEmails.length} email(s)?',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textLight),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.errorRed),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final emailService = ref.read(emailServiceProvider);
        await emailService.deleteMultipleEmails(_selectedEmails);
        _clearSelection();
      }
    }
  }

  void _copyEmailAddress(String emailAddress) {
    // TODO: Copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email address copied: $emailAddress'),
        backgroundColor: AppColors.primaryMedium,
      ),
    );
  }
}
